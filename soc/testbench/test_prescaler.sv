`timescale 1ns / 1ns

module test_prescaller;

    // Clock period definitions
    parameter time clk_period = 10;
    logic clk = 0;
    logic rst;

    // signal declarations
    logic [7:0] led;
    logic [ 4: 0] btn;
    logic [16: 0] sw;

    lt16soc_top #(
        .RST_ACTIVE_HIGH(1'b1)
    ) dut (
        .clk_sys(clk),
        .rst(rst),
        .btn(btn),
        .sw(sw),
        .led(led)
    );

    always #(clk_period/2) clk = ~clk;

    initial begin
        rst = 0;
        #10;
        rst = 1;
        #10
        sw = '0;
        
        #100
        sw = 'h0000000f;
        /*
        #300
        sw = 'h0000ffff;
        #800;
        sw = '1;
        */
        
        #5000
        $finish;
    end
endmodule