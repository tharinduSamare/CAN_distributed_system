`timescale 1ns / 1ns

module warmup2_intr_tb;

    // Clock period definitions
    parameter time clk_period = 10;
    logic clk = 0;
    logic rst;

    // signal declarations
    logic [7:0] led;
    logic [15:0] sw;
    logic [4:0] btn;

    lt16soc_top #(
        .RST_ACTIVE_HIGH(1'b1)
    ) dut (
        .clk_sys(clk),
        .rst(rst),

        .led(led),
        .sw(sw),
        .btn(btn)
    );

    assign btn = '0;
    assign sw = 16'd0;

    always #(clk_period/2) clk = ~clk;

    initial begin
        rst = 0;
        #10;
        rst = 1;

        // #40000;

        for(int i=0; i<16; i=i+1)begin
            sw = i;
            #100;
            btn = 5'd1;
            #10
            btn = '0;
            #40000;
        end
        for(int i=0; i<16; i=i+1)begin
            sw = i;
            #40000;
        end
        #40000;
        
        $finish;
    end
endmodule