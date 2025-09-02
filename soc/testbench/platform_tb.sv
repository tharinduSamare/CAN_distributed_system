// See the file "LICENSE" for the full license governing this code.
`timescale 1ns / 1ns

module platform_tb;

    // Clock period definitions
    parameter time clk_period = 10;
    logic clk = 0;
    logic rst;

    // signal declarations
    logic [7:0] led;
    logic [1:0] btn = '0;
    logic [7:0] sw = '0;
    logic test_irq0 = 0;
    logic test_irq1 = 0;

    lt16soc_top #(
        // .programfilename("/import/home/jmueller/Documents/lab/lt16soc/riscv-programs/blinky.txt")
        .RST_ACTIVE_HIGH(1'b1)
    ) dut (
        .clk_sys(clk),
        .rst(rst),

        .btn(btn),
        .sw(sw),
        .test_irq0(test_irq0),
        .test_irq1(test_irq1),
        .led(led)
    );

    always #(clk_period/2) clk = ~clk;

    initial begin
        sw = 0;
        rst = 0;
        #10;
        rst = 1;
        #950
        sw = 8'b10101010;
        #100
        sw = 8'b01010101;
        #100
        sw = 8'b10101010;
        #100
        sw = 8'b01010101;

        test_irq0 = 1;
        #100
        test_irq0 = 0;
//        rst = 0;
//        #20;
//        rst = 1;
        #10000
        // test_irq = 1;
        // #100;
        // test_irq = 0;
        #20000;
        $finish;
    end
endmodule