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
        be dist{0:=0, [1:14]:=0, 15:=5}; // always read or write all 7segments
    }

//    constraint wdata_c{
//        digit_on dist {0:=1, 1:=1};
//    }

    constraint tr_type_c{
        transaction_type dist {r_req_tr:=1, w_req_tr:=1, no_tr:=1};
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


module seven_segment_display_tb();

localparam real CLK_FREQ = 100; // MHz;
localparam real CLK_PERIOD = 1000 / CLK_FREQ; // ns
// localparam real REFRESH_RATE = 100; //Hz
localparam real REFRESH_RATE = 1_000_000; //Hz

localparam int REFRESH_PERIOD = CLK_FREQ * 1000000 / REFRESH_RATE; // number of clk cycles
localparam int LOW_TIME = REFRESH_PERIOD / 8; // number of clk cycles

localparam N_WORDS = 2; // 8 7-segments are available. 1 byte per segment.
localparam base_addr_type base_addr = 32'h0001_0000; // [TODO] parameterize this
localparam addr_mask_type addr_mask = ((32'h1 << 32)-1) & ~((32'b1 << $clog2(N_WORDS*4))-1);
localparam logic [N_WORDS-1:0][31:0] reg_init = '0;

logic clk; //clock signal
logic rst; //external reset button
logic [7:0] cathodes;
logic [7:0] AN;

OBI_simple_master #(.CLK_PERIOD(CLK_PERIOD)) master_inst;

initial begin
    clk = 0;
    forever begin
        #(CLK_PERIOD/2) clk = ~clk;
    end
end

DATA_BUS dbus(clk);

seven_segment_display #(
    .base_addr(base_addr),
    .addr_mask(addr_mask),
    .CLK_FREQ(CLK_FREQ), // MHz
    .REFRESH_RATE(REFRESH_RATE) //Hz
) dut(
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
        master_inst.randomize();
        case(master_inst.transaction_type)
            r_req_tr: master_inst.r_req();
            w_req_tr: master_inst.w_req();
            no_tr   : master_inst.no_req();
        endcase
        no_tr   : master_inst.no_req();
        repeat(REFRESH_PERIOD*5) #(CLK_PERIOD);
    end

end

// monitor
bit [N_WORDS-1:0][31:0] reg_file_model, reg_file_model_old;
bit [31:0]address;
assign address = (dbus.addr & ~addr_mask)>>2; // address alligns to 4 bytes
bit [31:0]rdata_old;

bit [7:0]AN_old;

initial begin
    forever begin
        @(posedge clk);
        #(1);
        if(dbus.req & dbus.we & dbus.gnt) reg_file_model[address] = dbus.wdata;
    end
end

always_ff@(posedge clk) begin
    if(rst)begin
        rdata_old <= '0;
        reg_file_model_old <= '0;
        AN_old <= '0;
    end
    else begin

        rdata_old <= dbus.rdata;
        reg_file_model_old <= reg_file_model;
        AN_old <= AN;
    end
end

property rdata_check;
    @(posedge clk) disable iff(rst)
    (dbus.req & ~dbus.we & dbus.gnt) |-> ##[1:$] (rdata_old == reg_file_model[address]) && dbus.rvalid;
endproperty

// property reg_data_o_check;
//     @(posedge clk) disable iff(rst)
//     reg_data_o == reg_file_model_old;
// endproperty

assert property(rdata_check)
else $error("dbus.rdata = 0x%0x. But it should be 0x%0x", rdata_old, reg_file_model[address]);

// assert property(reg_data_o_check)
// else $error("reg_data_o = %0p. But it should be %0p", reg_data_o, reg_file_model);

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

property AN_shift_11111110_11111101_shift_check;
    @(posedge clk) disable iff(rst)
    (AN == 8'b1111_1110) |=> ##[1:$] ((AN == 8'b1111_1101) || (AN == {8{1'b1}}));
endproperty

property AN_shift_11111101_11111011_shift_check;
    @(posedge clk) disable iff(rst)
    (AN == 8'b1111_1101) |=> ##[1:$] ((AN == 8'b1111_1011) || (AN == {8{1'b1}}));
endproperty

property AN_shift_11111011_11110111_shift_check;
    @(posedge clk) disable iff(rst)
    (AN == 8'b1111_1011) |=> ##[1:$] ((AN == 8'b1111_0111) || (AN == {8{1'b1}}));
endproperty

property AN_shift_11110111_11101111_shift_check;
    @(posedge clk) disable iff(rst)
    (AN == 8'b1111_0111) |=> ##[1:$] ((AN == 8'b1110_1111) || (AN == {8{1'b1}}));
endproperty

property AN_shift_11101111_11011111_shift_check;
    @(posedge clk) disable iff(rst)
    (AN == 8'b1110_1111) |=> ##[1:$] ((AN == 8'b1101_1111) || (AN == {8{1'b1}}));
endproperty

property AN_shift_11011111_10111111_shift_check;
    @(posedge clk) disable iff(rst)
    (AN == 8'b1101_1111) |=> ##[1:$] ((AN == 8'b1011_1111) || (AN == {8{1'b1}}));
endproperty

property AN_shift_10111111_01111111_shift_check;
    @(posedge clk) disable iff(rst)
    (AN == 8'b1011_1111) |=> ##[1:$] ((AN == 8'b0111_1111) || (AN == {8{1'b1}}));
endproperty

property AN_shift_01111111_11111110_shift_check;
    @(posedge clk) disable iff(rst)
    (AN == 8'b0111_1111) |=> ##[1:$] ((AN == 8'b111_11110) || (AN == {8{1'b1}}));
endproperty

property segment_afterglow_timing_check1;
    @(posedge clk) disable iff(rst)
    ((AN != AN_old) && (AN != {8{1'b1}})) |-> ##1 (AN == AN_old)[*LOW_TIME] |-> ##1 (AN != AN_old);
endproperty

property segment_afterglow_timing_check2;
    @(posedge clk) disable iff(rst)
    ((AN == AN_old) && (AN != {8{1'b1}}))[*LOW_TIME] |-> ##1 (AN != AN_old);
endproperty

property segment0_value_check; // segment value should be equal to what was written by the processor
    @(posedge clk) disable iff(rst)
    (dbus.req & dbus.we & dbus.gnt & dbus.wdata[4] & (address == 0)) |-> ##[4:REFRESH_PERIOD+LOW_TIME] ((~AN[0]) && cathodes[7:1]==VALID_SEGMENT_VALS[reg_file_model[0][3:0]]);
endproperty

property segment1_value_check; // segment value should be equal to what was written by the processor
    @(posedge clk) disable iff(rst)
    (dbus.req & dbus.we & dbus.gnt & dbus.wdata[12] & (address == 0)) |-> ##[4:REFRESH_PERIOD+LOW_TIME] ((~AN[1]) && cathodes[7:1]==VALID_SEGMENT_VALS[reg_file_model[0][11:8]]);
endproperty

property segment2_value_check; // segment value should be equal to what was written by the processor
    @(posedge clk) disable iff(rst)
    (dbus.req & dbus.we & dbus.gnt & dbus.wdata[20] & (address == 0)) |-> ##[4:REFRESH_PERIOD+LOW_TIME] ((~AN[2]) && cathodes[7:1]==VALID_SEGMENT_VALS[reg_file_model[0][19:16]]);
endproperty

property segment3_value_check; // segment value should be equal to what was written by the processor
    @(posedge clk) disable iff(rst)
    (dbus.req & dbus.we & dbus.gnt & dbus.wdata[28] & (address == 0)) |-> ##[4:REFRESH_PERIOD+LOW_TIME] ((~AN[3]) && cathodes[7:1]==VALID_SEGMENT_VALS[reg_file_model[0][27:24]]);
endproperty

property segment4_value_check; // segment value should be equal to what was written by the processor
    @(posedge clk) disable iff(rst)
    (dbus.req & dbus.we & dbus.gnt & dbus.wdata[4] & (address == 1)) |-> ##[4:REFRESH_PERIOD+LOW_TIME] ((~AN[4]) && cathodes[7:1]==VALID_SEGMENT_VALS[reg_file_model[1][3:0]]);
endproperty

property segment5_value_check; // segment value should be equal to what was written by the processor
    @(posedge clk) disable iff(rst)
    (dbus.req & dbus.we & dbus.gnt & dbus.wdata[12] & (address == 1)) |-> ##[4:REFRESH_PERIOD+LOW_TIME] ((~AN[5]) && cathodes[7:1]==VALID_SEGMENT_VALS[reg_file_model[1][11:8]]);
endproperty

property segment6_value_check; // segment value should be equal to what was written by the processor
    @(posedge clk) disable iff(rst)
    (dbus.req & dbus.we & dbus.gnt & dbus.wdata[20] & (address == 1)) |-> ##[4:REFRESH_PERIOD+LOW_TIME] ((~AN[6]) && cathodes[7:1]==VALID_SEGMENT_VALS[reg_file_model[1][19:16]]);
endproperty

property segment7_value_check; // segment value should be equal to what was written by the processor
    @(posedge clk) disable iff(rst)
    (dbus.req & dbus.we & dbus.gnt & dbus.wdata[28] & (address == 1)) |-> ##[4:REFRESH_PERIOD+LOW_TIME] ((~AN[7]) && cathodes[7:1]==VALID_SEGMENT_VALS[reg_file_model[1][27:24]]);
endproperty

assert property(segmemnt_valid_physical_val_check)
// $display("[DEBUG] segmemnt_valid_physical_val_check passed");
else $error("Seven segment cathods[7:1] value 0b%7b is not a valid value", cathodes[7:1]);

assert property(only_one_segment_can_on_check)
// $display("[DEBUG] only_one_segment_can_on_check passed");
else $error("Only one of 4 digits can be ON at once. AN: 0b%8b ", AN);

assert property(AN_shift_11111110_11111101_shift_check) else $error("Digits should ON in the given pattern. AN_old: 0b%8b -> AN_new: 0b%8b", AN_old, AN);
assert property(AN_shift_11111101_11111011_shift_check) else $error("Digits should ON in the given pattern. AN_old: 0b%8b -> AN_new: 0b%8b", AN_old, AN);
assert property(AN_shift_11111011_11110111_shift_check) else $error("Digits should ON in the given pattern. AN_old: 0b%8b -> AN_new: 0b%8b", AN_old, AN);
assert property(AN_shift_11110111_11101111_shift_check) else $error("Digits should ON in the given pattern. AN_old: 0b%8b -> AN_new: 0b%8b", AN_old, AN);
assert property(AN_shift_11101111_11011111_shift_check) else $error("Digits should ON in the given pattern. AN_old: 0b%8b -> AN_new: 0b%8b", AN_old, AN);
assert property(AN_shift_11011111_10111111_shift_check) else $error("Digits should ON in the given pattern. AN_old: 0b%8b -> AN_new: 0b%8b", AN_old, AN);
assert property(AN_shift_10111111_01111111_shift_check) else $error("Digits should ON in the given pattern. AN_old: 0b%8b -> AN_new: 0b%8b", AN_old, AN);
assert property(AN_shift_01111111_11111110_shift_check) else $error("Digits should ON in the given pattern. AN_old: 0b%8b -> AN_new: 0b%8b", AN_old, AN);

assert property(segment_afterglow_timing_check1)
// $display("segment_afterglow_timing_check1 passed");
else $fatal("AN: 0b%0b should keep its value for %0d cycles to have %0d refresh rate", AN, LOW_TIME, REFRESH_RATE);

assert property(segment_afterglow_timing_check2)
// $display("segment_afterglow_timing_check2 passed");
else $fatal("AN: 0b%0b should change its value after %0d cycles to have %0d refresh rate", AN, LOW_TIME, REFRESH_RATE);


assert property(segment0_value_check) else $error("Segment[0]: 0b%0b != processor wrote value: 0b%0b (digit %0d)", cathodes[7:1], VALID_SEGMENT_VALS[reg_file_model[0][3:0]], reg_file_model[0][3:0]);
assert property(segment1_value_check) else $error("Segment[1]: 0b%0b != processor wrote value: 0b%0b (digit %0d)", cathodes[7:1], VALID_SEGMENT_VALS[reg_file_model[0][11:8]], reg_file_model[0][11:8]);
assert property(segment2_value_check) else $error("Segment[2]: 0b%0b != processor wrote value: 0b%0b (digit %0d)", cathodes[7:1], VALID_SEGMENT_VALS[reg_file_model[0][19:16]], reg_file_model[0][19:16]);
assert property(segment3_value_check) else $error("Segment[3]: 0b%0b != processor wrote value: 0b%0b (digit %0d)", cathodes[7:1], VALID_SEGMENT_VALS[reg_file_model[0][27:24]], reg_file_model[0][27:24]);
assert property(segment4_value_check) else $error("Segment[4]: 0b%0b != processor wrote value: 0b%0b (digit %0d)", cathodes[7:1], VALID_SEGMENT_VALS[reg_file_model[1][3:0]], reg_file_model[1][3:0]);
assert property(segment5_value_check) else $error("Segment[5]: 0b%0b != processor wrote value: 0b%0b (digit %0d)", cathodes[7:1], VALID_SEGMENT_VALS[reg_file_model[1][11:8]], reg_file_model[1][11:8]);
assert property(segment6_value_check) else $error("Segment[6]: 0b%0b != processor wrote value: 0b%0b (digit %0d)", cathodes[7:1], VALID_SEGMENT_VALS[reg_file_model[1][19:16]], reg_file_model[1][19:16]);
assert property(segment7_value_check) else $error("Segment[7]: 0b%0b != processor wrote value: 0b%0b (digit %0d)", cathodes[7:1], VALID_SEGMENT_VALS[reg_file_model[1][27:24]], reg_file_model[1][27:24]);


endmodule