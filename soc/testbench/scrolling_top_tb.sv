import data_bus_pkg::*;

`timescale 1ns / 1ns


typedef enum bit[1:0] { 
    r_req_tr,
    w_req_tr,
    no_tr
} transaction_t;

class OBI_simple_master_warmup4 #(parameter CLK_PERIOD = 10, parameter BUFFER_SIZE = 16);

    rand transaction_t transaction_type;

    virtual DATA_BUS.Master vif;
    bit[31:0] BASE_ADDR;
    bit[31:0] ADDR_MASK;

    rand bit req;
    rand bit [31:0] addr;
    rand bit we;
    rand bit [ 3:0] be;
    rand bit [31:0] wdata;

    rand bit [BUFFER_SIZE-1:0][31:0] buffer;

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
        be dist{0:=0, [1:14]:=0, 15:=5}; // always read or write all 7segments
    }

    constraint tr_type_c{
        transaction_type dist {r_req_tr:=0, w_req_tr:=1, no_tr:=0};
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

    task no_req();
        @(posedge vif.clk)
        vif.req = 1'b0;
        vif.addr = '0;
        vif.we = 1'b0;
        vif.be = '0;
        vif.wdata = '0;
    endtask

    task w_req(input int w_data, input int w_addr);
        @(posedge vif.clk)
        vif.req = 1'b1;
        vif.addr = w_addr;
        vif.we = 1'b1;
        vif.be = be;
        vif.wdata = w_data;
        cycle_start();
        while (vif.gnt != 1'b1) begin
            cycle_end(); 
            cycle_start(); 
        end
        no_req();
        // cycle_end();
    endtask

    typedef enum bit{
        counter_val_write,
        control_write
    } w_req_tr_t;
    
    localparam BUFFER_WRITE_BIT     = 24;
    localparam BUFFER_CLEAR_BIT     = 8;
    localparam ON_OFF_BIT           = 0;
    // localparam BUFFER_DATA_HIGH_BIT = 20;
    // localparam BUFFER_DATA_LOW_BIT  = 16;

    typedef enum bit[1:0]{
        buffer_write,
        buffer_clear, 
        toggle_on_off
    } control_req_t;

    rand control_req_t control_req_type;


    rand int buffer_write_count;
    rand int counter_val;

    constraint control_req_type_c{
        control_req_type dist {buffer_write:= 1, buffer_clear:= 0, toggle_on_off:= 1};
    }

    constraint buffer_write_count_c{
        buffer_write_count <= BUFFER_SIZE;
        (control_req_type == toggle_on_off) -> buffer_write_count == 1;
        (control_req_type == buffer_clear)  -> buffer_write_count == 1;
        (control_req_type == buffer_write)  -> buffer_write_count dist {BUFFER_SIZE/4:=1, BUFFER_SIZE/2:= 1, BUFFER_SIZE:=1, BUFFER_SIZE*2:=1};
    }

    constraint buffer_c {
        if(control_req_type == toggle_on_off){
            foreach (buffer[i]){
                buffer[i][BUFFER_CLEAR_BIT] == 1'b0;
                buffer[i][ON_OFF_BIT] == 1'b1;
                buffer[i][BUFFER_WRITE_BIT]  == 1'b0;
            }
        }
        else if(control_req_type == buffer_clear){
            foreach (buffer[i]){
                buffer[i][BUFFER_CLEAR_BIT] == 1'b1;
                buffer[i][ON_OFF_BIT] == 1'b0;
                buffer[i][BUFFER_WRITE_BIT]  == 1'b0;
            }
        }
        else if(control_req_type == buffer_write){
            foreach (buffer[i]){
                buffer[i][BUFFER_CLEAR_BIT]  == 1'b0;
                buffer[i][ON_OFF_BIT]        == 1'b0;
                buffer[i][BUFFER_WRITE_BIT]  == 1'b1;
            }
        }
    }

    constraint counter_val_c{
        // counter_val == 1_000_000;
        counter_val == 100;
    }

    rand int write_gap;
    task set_buffer();
        int w_addr;
        for(int i=0; i<buffer_write_count; i++)begin
            void'(randomize(write_gap) with {write_gap inside {[0:10]};});
            w_addr = BASE_ADDR;
            w_req(buffer[i], w_addr);
            #(write_gap*CLK_PERIOD);
        end
    endtask

    task set_counter_val();
        w_req(counter_val, BASE_ADDR+4);
    endtask

endclass

module scrolling_top_tb();

localparam real CLK_FREQ = 100; // MHz;
localparam real CLK_PERIOD = 1000 / CLK_FREQ; // ns
// localparam real SEVEN_SEGMENT_REFRESH_RATE = 100; //Hz
localparam real SEVEN_SEGMENT_REFRESH_RATE = 1_000_000; //Hz
localparam int SEVEN_SEGMENT_REFRESH_PERIOD = CLK_FREQ * 1000000 / SEVEN_SEGMENT_REFRESH_RATE; // number of clk cycles

localparam N_WORDS = 2; // [control_reg, segment_set1, segment_set0]
localparam base_addr_type base_addr = 32'h000F_0040; // [TODO] parameterize this
localparam addr_mask_type addr_mask = ((32'h1 << 32)-1) & ~((32'b1 << $clog2(N_WORDS*4))-1);

localparam BUFFER_SIZE = 16;

logic clk; //clock signal
logic rst; //external reset button
logic [7:0] cathodes;
logic [7:0] AN;

OBI_simple_master_warmup4 #(.CLK_PERIOD(CLK_PERIOD), .BUFFER_SIZE(BUFFER_SIZE)) master_inst;

initial begin
    clk = 0;
    forever begin
        #(CLK_PERIOD/2) clk = ~clk;
    end
end

DATA_BUS dbus(clk);

scrolling_top #(
    .base_addr(base_addr),
    .addr_mask(addr_mask),
    .CLK_FREQ(CLK_FREQ), // MHz
    .SEVEN_SEGMENT_REFRESH_RATE(SEVEN_SEGMENT_REFRESH_RATE), //Hz
    .BUFFER_SIZE(BUFFER_SIZE)
)dut(
    .clk(clk),
    .rst(rst),
    .dslv(dbus.Slave),
    .cathodes(cathodes),
    .AN(AN)
);

initial begin
    rst = 1'b1;
    repeat(2) #CLK_PERIOD;
    rst = 1'b0;

    master_inst = new(.vif(dbus.Master), .base_addr(base_addr), .addr_mask(addr_mask));
    
    forever begin
        @(posedge clk);
        master_inst.randomize();
        master_inst.set_counter_val();
        master_inst.set_buffer();
        #(CLK_PERIOD*500);        
    end    
end



// monitor
int counter_val;
bit [BUFFER_SIZE-1:0][4:0] buffer;
bit [$clog2(BUFFER_SIZE)-1:0] buffer_wr_ptr;

initial begin
    counter_val = '0;
    buffer = '0;
    buffer_wr_ptr = '0;

    forever begin
        @(posedge clk);
        if(dbus.req && dbus.gnt && dbus.we && (dbus.addr == base_addr))begin
            buffer[buffer_wr_ptr] = dbus.wdata[20:16];
            buffer_wr_ptr = (buffer_wr_ptr == (BUFFER_SIZE-1))? '0 : buffer_wr_ptr+1'b1;
        end
        else if(dbus.req && dbus.gnt && dbus.we && (dbus.addr == (base_addr+4)))begin
            counter_val = dbus.wdata;
        end
    end
end

localparam bit [6:0] VALID_SEGMENT_VALS [0:16] = '{
    7'b0000001, // 0
    7'b1001111, // 1
    7'b0010010, // 2
    7'b0000110, // 3
    7'b1001100, // 4
    7'b0100100, // 5
    7'b0100000, // 6
    7'b0001111, // 7
    7'b0000000, // 8
    7'b0000100, // 9
    7'b0001000, // A
    7'b1100000, // b
    7'b0110001, // C
    7'b1000010, // d
    7'b0110000, // E
    7'b0111000, // F
    7'b1111111  // off
};

property segmemnt_valid_physical_val_check;
    @(posedge clk) disable iff(rst)
    (AN != '1) |-> cathodes[7:1] inside {VALID_SEGMENT_VALS}; // if at least 1 digit is ON, it should have a valid value.
endproperty

property only_one_segment_can_on_check;
    @(posedge clk) disable iff(rst)
    ((AN == {8{1'b1}}) || (((~AN) & ((~AN)-8'b1))== 8'b0));// either all bits are one or only 1 bit is zero
endproperty

// property segmemnt_val_check;
//     @(posedge clk) disable iff(rst)
//     (AN != '1) |-> cathodes[7:1] inside {buffer};
// endproperty

assert property(segmemnt_valid_physical_val_check)
// $display("[DEBUG] segmemnt_valid_physical_val_check passed");
else $error("Seven segment cathods[7:1] value 0b%7b is not a valid value", cathodes[7:1]);

assert property(only_one_segment_can_on_check)
// $display("[DEBUG] only_one_segment_can_on_check passed");
else $error("Only one of 4 digits can be ON at once. AN: 0b%8b ", AN);


endmodule