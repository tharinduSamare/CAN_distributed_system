import data_bus_pkg::*;

`timescale 1ns / 1ns

typedef enum bit[1:0] { 
    r_req_tr,
    w_req_tr,
    no_tr
} transaction_t;

class OBI_simple_master #(parameter CLK_PERIOD = 10);

    rand transaction_t transaction_type;

    virtual DATA_BUS.Master vif;
    bit[31:0] BASE_ADDR;
    bit[31:0] ADDR_MASK;

    rand bit req;
    rand bit [31:0] addr;
    rand bit we;
    rand bit [ 3:0] be;
    rand bit [31:0] wdata;

    function new(virtual DATA_BUS.Master vif, input int base_addr=32'h0001_0000, input int addr_mask=(32'h3FFFFF-(8-1)));
        this.vif = vif;
        this.BASE_ADDR = base_addr;
        this.ADDR_MASK = addr_mask;
        assert(randomize());
    endfunction

    constraint req_c{
        // addr >= BASE_ADDR;
        // addr <= BASE_ADDR+ADDR_MASK;
        // addr & ADDR_MASK == BASE_ADDR;
        // addr >= BASE_ADDR;
        // addr <= BASE_ADDR | ~ADDR_MASK; // ex:- BASE_ADDR=0x0001_0000, ADDR_MASK=0xFFFF_0000
        be dist{0:=0, [1:14]:=0, 15:=5};
    }

    constraint tr_type_c{
        transaction_type dist {r_req_tr:=1, w_req_tr:=0, no_tr:=5};
    }

    task cycle_start;
      #CLK_PERIOD;
    endtask

    task cycle_end;
      @(posedge vif.clk);
    endtask

    task r_req();
        @(posedge vif.clk);
        vif.req = 1'b1;
        vif.addr = addr;
        vif.we = 1'b0;
        cycle_start();
        while (vif.gnt != 1'b1) begin
            cycle_end();
            cycle_start(); 
        end
        // cycle_end();
    endtask

    task w_req();
        @(posedge vif.clk)
        vif.req = 1'b1;
        vif.addr = addr;
        vif.we = 1'b1;
        vif.be = be;
        vif.wdata = wdata;
        cycle_start();
        while (vif.gnt != 1'b1) begin
            cycle_end(); 
            cycle_start(); 
        end
        // cycle_end();
    endtask

    task no_req();
        @(posedge vif.clk)
        vif.req = 1'b0;
        vif.addr = '0;
        vif.we = 1'b0;
        vif.be = '0;
        vif.wdata = '0;
    endtask

endclass

class peripheral_device #(parameter N_WORDS=1);

    rand bit[N_WORDS-1:0][31:0]data; // [buttons, switches]
    rand bit valid;

    rand bit buttons_zero;

    constraint new_data_valid_c{
        valid dist {0:= 10, 1:=1};
    }

    constraint buttons_c{
        buttons_zero dist {0:=1, 1:=10};
        (buttons_zero == 1'b1) -> data[1] == '0; // [buttons, switches]
    }

    function void send_data(output bit [N_WORDS-1:0][31:0]reg_data_i, output bit new_data_i);
        assert(randomize());
        reg_data_i = data;
        new_data_i = valid;
    endfunction

endclass

module sw_intr_tb();

localparam CLK_PERIOD = 10; // ns
localparam N_WORDS = 2; // [buttons, switches]

localparam base_addr_type base_addr = 32'h0001_0000; // [TODO] parameterize this
localparam addr_mask_type addr_mask = (33'h1 << 32) - ($clog2(N_WORDS*4)-1);
localparam BUTTON_W = 5;
localparam SWITCH_W = 16;
logic clk;
logic rst;
logic [BUTTON_W-1:0] buttons;
logic [SWITCH_W-1:0] switches;
logic irq;

logic [N_WORDS-1:0][31:0]reg_data_i; // [buttons, switches]
logic new_data_i;

OBI_simple_master #(.CLK_PERIOD(CLK_PERIOD)) master_inst;
peripheral_device #(.N_WORDS(N_WORDS)) peripheral_inst;

initial begin
    clk = 0;
    forever begin
        #(CLK_PERIOD/2) clk = ~clk;
    end
end

DATA_BUS dbus(clk);

io_sw #(
    .base_addr(base_addr),
    .addr_mask(addr_mask)
) dut(
    .clk(clk),
    .rst(rst),
    .buttons(buttons),
    .switches(switches),
    .irq(irq),

    .dslv(dbus.Slave)
);

assign buttons = reg_data_i[1][BUTTON_W-1:0];
assign switches = reg_data_i[0][SWITCH_W-1:0];

initial begin

    rst = 1'b1;
    repeat(2) #CLK_PERIOD;
    rst = 1'b0;

    master_inst = new(.vif(dbus.Master), .base_addr(base_addr), .addr_mask(addr_mask));
    peripheral_inst = new();

    fork
        forever begin
            master_inst.randomize();
            case(master_inst.transaction_type)
                r_req_tr: master_inst.r_req();
                w_req_tr: master_inst.w_req();
                no_tr   : master_inst.no_req();
            endcase
        end

        forever begin
            @(posedge clk);
            peripheral_inst.randomize();
            peripheral_inst.send_data(reg_data_i, new_data_i);
        end
    join_none
end

// monitor
bit [N_WORDS-1:0][31:0] reg_file_model;
bit [31:0]address;
assign address = dbus.addr & ~addr_mask;
bit [31:0]rdata_old;

initial begin
    forever begin
        @(posedge clk);
        #(1);
        if(new_data_i) reg_file_model = reg_data_i;
        else if(dbus.req & dbus.we & dbus.gnt) reg_file_model[address] = dbus.wdata;
    end
end

property rdata_check;
    @(posedge clk) disable iff(rst)
    (dbus.req & ~dbus.we & dbus.gnt) |-> ##[1:$] (rdata_old == reg_file_model[address]) && dbus.rvalid;
endproperty

property irq_start_check;
    @(posedge clk) disable iff(rst)
    ((buttons != '0) && (irq == 1'b0)) |-> ##1 irq == 1'b1;
endproperty

property irq_end_check;
    @(posedge clk) disable iff(rst)
    irq == 1'b1 |-> ##[1:$](irq && dbus.req && !dbus.we) ##[1:$](irq && dbus.rvalid) ##1 ~irq;
endproperty

assert property(rdata_check)
// $display("hit rdata_check");
else $error("dbus.rdata = 0x%0x. But it should be 0x%0x", rdata_old, reg_file_model[address]);

assert property (irq_start_check)
// $display("hit irq_start_check");
else $error("When button pressed irq should becomes high. But it did not");

assert property (irq_end_check)
// $display("hit irq_end_check");
else $error("Switch IRQ should stay until next read and reset after read response.");

endmodule