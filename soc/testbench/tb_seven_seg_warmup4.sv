`timescale 1ns / 1ns

module test_seven_seg_warmup4;



    // signal declarations
    logic clk;
    logic rst;
    logic on_off;
    logic cnt_start;
    logic cnt_done;
    logic next_char;
    logic [4:0] hex_char;
    logic [3:0] seg_data;
    logic seg_off;
    logic seg_shift;
    logic seg_write;
    logic seg_clear;
    logic [7:0] anodes;
    logic [7:0] cathodes;

    
   scrolling_controller scrolling_dut(
    .clk(clk),
    .rst(rst),
    .on_off(on_off),
    .cnt_start(cnt_start),
    .cnt_done(cnt_done),
    .next_char(next_char),
    .hex_char(hex_char),
    .seg_data(seg_data),
    .seg_off(seg_off),
    .seg_shift(seg_shift),
    .seg_write(seg_write),
    .seg_clear(seg_clear)
);
seven_segment_display_warmup4 Seven_dut(
    .clk(clk),
    .rst(rst),
    .seg_data(seg_data),
    .seg_off(seg_off),
    .seg_shift(seg_shift),
    .seg_write(seg_write),
    .seg_clear(seg_clear),
    .anodes(anodes),
    .cathodes(cathodes)
);

    always #(5) clk = ~clk;

    initial begin
        rst = 1;
        clk = 0;
        #10
        rst = 0;
        on_off = 0;
        cnt_done = 0;
        hex_char = '0;
        #10
        @(posedge clk); on_off = 1;// turn on
        hex_char = 9;
        @(posedge clk);on_off = 0;// Keep it on
        #105
        cnt_done = 1;
        hex_char = 8;
        @(posedge clk); cnt_done = 0;
        #105
        cnt_done = 1;
        hex_char = 7;
        @(posedge clk); cnt_done = 0;
        #105
        cnt_done = 1;
        hex_char = 6;
        @(posedge clk); cnt_done = 0;
        #105
        cnt_done = 1;
        hex_char = 5;
        @(posedge clk); cnt_done = 0;
        #105
        cnt_done = 1;
        hex_char = 4;
        @(posedge clk); cnt_done = 0;
        #105
        cnt_done = 1;
        hex_char = 3;
        @(posedge clk); cnt_done = 0;
        #105
        cnt_done = 1;
        hex_char = 2;
        @(posedge clk); cnt_done = 0;
        #105
        cnt_done = 1;
        hex_char = 1;
        @(posedge clk); cnt_done = 0;
        #105
        cnt_done = 1;
        hex_char = 0;
        @(posedge clk); cnt_done = 0;
        #105
        cnt_done = 1;
        hex_char = 15;
        @(posedge clk); cnt_done = 0;
        #105
        on_off = 1;// turn off and keep it alternating between on and off



        #1000
        $finish;
    end
endmodule