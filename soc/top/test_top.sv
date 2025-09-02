module test_top #(
    parameter logic RST_ACTIVE_HIGH = 1'b1
) (
    input logic clk_sys, //clock signal
    input logic rst, //external reset button

    output logic [7 : 0] led,
    input logic [4:0] btn,
    input logic [15:0] sw

);

    logic rst_gen;

    assign rst_gen = ~rst;//RST_ACTIVE_HIGH?~rst:rst;
    
    
    logic clk;

    clk_div clock_div_inst(
       .clk_out1(clk),
       .reset(rst_gen),
       .locked(),
       .clk_in1(clk_sys)
   );

   assign led = sw[7:0];


endmodule