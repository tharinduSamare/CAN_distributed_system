`timescale 1ns / 1ns

module warmup3_tb;

    // Clock period definitions
    parameter time clk_period = 10;
    localparam real CLK_FREQ = 1000/clk_period; // MHz
    logic clk = 0;
    logic rst;

    // signal declarations
    logic [7:0] led;
    logic [15:0] sw;
    logic [4:0] btn;
    logic [7:0] cathodes, AN;

    lt16soc_top #(
        .CLK_FREQ(CLK_FREQ), // MHz;
        .RST_ACTIVE_HIGH(1'b1)
    ) dut (
        .clk_sys(clk),
        .rst(rst),

        .led(led),
        .sw(sw),
        .btn(btn),
        .AN(AN),
        .cathodes(cathodes)
    );

    assign btn = '0;
    assign sw = 16'd0;

    always #(clk_period/2) clk = ~clk;

    initial begin
        rst = 0;
        #10;
        rst = 1;

        // #40000;

        # 100000;
        
        $finish;
    end
endmodule