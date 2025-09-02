`timescale 1ns / 1ns

module warmup1_tb;

    // Clock period definitions
    parameter time clk_period = 10;
    logic clk = 0;
    logic rst;

    // signal declarations
    logic [7:0] led;

    lt16soc_top #(
        .RST_ACTIVE_HIGH(1'b1)
    ) dut (
        .clk_sys(clk),
        .rst(rst),

        .led(led)
    );

    always #(clk_period/2) clk = ~clk;

    initial begin
        rst = 0;
        #10;
        rst = 1;

        #40000;
        
        $finish;
    end
endmodule