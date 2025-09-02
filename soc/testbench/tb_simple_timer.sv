`timescale 1ns / 1ns

module test_simple_timer;



    // signal declarations
   
    logic clk, rst, timer_overflow;
    always #(5) clk = ~clk;

   simple_timer  # (5) dut(
        .clk(clk),
        .rst(rst),
        .timer_overflow(timer_overflow)
    );

    initial begin
        rst = 1;
        clk = 0;
        #10
        rst = 0;
        #1000
        $finish;
    end
endmodule