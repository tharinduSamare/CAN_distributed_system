module top_wrapper #(
    // parameter real CLK_FREQ = 100, // MHz;
    // parameter integer RST_ACTIVE_HIGH = 1'b1
) (
    
    input wire clk_sys, //clock signal
    input wire rst, //external reset button
    output wire [7 : 0] cathodes,
    output wire [7 : 0] AN,
    output wire [7 : 0] led,
    input wire [4:0] btn,
    input wire [15:0] sw,

    // CAN_PMOD
    output wire can_re,
    output wire can_txd,
    input wire can_rxd,
    output wire can_de,

    output wire can_tx_success,
    output wire can_need_to_tx,
    output wire can_tx_request,
    output wire can_sample_point,
    output wire [8:0]can_tx_err_cnt,
    output wire can_error_status,
    output wire can_error_irq,
    output wire can_error_trasmitting,
    output wire can_abort_tx,
    output wire [31:0]core_pc
);


lt16soc_top #(
    // .CLK_FREQ(CLK_FREQ),
    // .RST_ACTIVE_HIGH(RST_ACTIVE_HIGH)
) lt16soc_top(
    .clk_sys(clk_sys), //clock signal
    .rst(rst), //external reset button
    .cathodes(cathodes),
    .AN(AN),
    .led(led),
    .btn(btn),
    .sw(sw),

    // CAN_PMOD
    .can_re(can_re),
    .can_txd(can_txd),
    .can_rxd(can_rxd),
    .can_de(can_de),

    // debug
    .can_tx_success(can_tx_success),
    .can_tx_request(can_tx_request),
    .can_need_to_tx(can_need_to_tx),
    .can_sample_point(can_sample_point),
    .can_tx_err_cnt(can_tx_err_cnt),
    .can_error_status(can_error_status),
    .can_error_irq(can_error_irq),
    .can_error_trasmitting(can_error_trasmitting),
    .can_abort_tx(can_abort_tx),
    .core_pc(core_pc)
);


endmodule