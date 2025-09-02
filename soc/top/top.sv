import data_bus_pkg::*;
import config_pkg::*;

module lt16soc_top #(
    parameter real CLK_FREQ = 100, // MHz;
    parameter logic RST_ACTIVE_HIGH = 1'b1
) (
    input logic clk_sys, //clock signal
    input logic rst, //external reset button
    output logic [7 : 0] cathodes,
    output logic [7 : 0] AN,
    output logic [7 : 0] led,
    input logic [4:0] btn,
    input logic [15:0] sw,

    // CAN_PMOD
    output logic can_re,
    output logic can_txd,
    input logic can_rxd,
    output logic can_de

    // debug
    // output logic can_tx_success,
    // output logic can_tx_request,
    // output logic can_need_to_tx,
    // output logic can_sample_point,
    // output logic [8:0]can_tx_err_cnt,
    // output logic can_error_status,
    // output logic can_error_irq,
    // output logic can_error_trasmitting,
    // output logic can_abort_tx,
    // output logic [31:0]core_pc
);

    localparam real SEVEN_SEGMENT_REFRESH_RATE = 100; //Hz
    // localparam real SEVEN_SEGMENT_REFRESH_RATE = 1_000_000; //Hz (for simulation)
    localparam SCROLLING_SCREEN_BUFFER_SIZE = 16;

    logic clk;

    DATA_BUS  db_slv_vector [NSLV-1 : 0] (clk);
    DATA_BUS  db_mst_vector [NMST-1 : 0] (clk);

    INSTR_BUS ibus ();

    logic rst_gen;

    logic[15:0] irq_lines;

    assign rst_gen = ~rst;//RST_ACTIVE_HIGH?~rst:rst;
    

    // assign clk = clk_sys;

    clk_div clock_div_inst(
       .clk_out1(clk),
       .reset(rst_gen),
       .locked(),
       .clk_in1(clk_sys)
   );

    corewrapper corewrap_inst (
        .clk(clk),
        .rst(rst_gen),
        .irq_lines(irq_lines),
        .imst(ibus),
        .dmst(db_mst_vector[CFG_CORE])
    );

    data_interconnect dicn_inst (
        .clk(clk),
        .rst(rst_gen),
        .mst(db_mst_vector),
        .slv(db_slv_vector)
    );

    memwrapper #(
        .base_addr(CFG_BADR_MEM),
        .addr_mask(CFG_MADR_MEM)
    ) memwrap_inst(
        .clk(clk),
        .rst(rst_gen),
		.fault(),
        .islv(ibus),
		.dslv(db_slv_vector[CFG_MEM])
    );

    scrolling_top #(
        .base_addr(CFG_BADR_Scrolling),
        .addr_mask(CFG_MADR_Scrolling),
        .CLK_FREQ(CLK_FREQ), // MHz
        .SEVEN_SEGMENT_REFRESH_RATE(SEVEN_SEGMENT_REFRESH_RATE), //Hz
        .BUFFER_SIZE(SCROLLING_SCREEN_BUFFER_SIZE)
    ) scrolling_display_inst
    (
        .clk(clk), //clock signal
        .rst(rst_gen), //external reset button
        .dslv(db_slv_vector[CFG_Scrolling]),
        .cathodes(cathodes),
        .AN(AN)

    );

    io_led #(
        CFG_BADR_LED, CFG_MADR_LED
    ) led_inst(
        clk, rst_gen, led, db_slv_vector[CFG_LED]
    );

    io_sw #(
        CFG_BADR_SW, CFG_MADR_SW
    ) sw_inst(
        .clk(clk),
        .rst(rst_gen),
        .buttons(btn),
        .switches(sw),
        .dslv(db_slv_vector[CFG_SW]),
        .irq(irq_lines[0])
    );

    can_wrapper #(
        .base_addr(CFG_BADR_CAN),
        .addr_mask(CFG_MADR_CAN)
    )can_inst(
        .clk(clk),
        .rst(rst_gen),
        .rx_i(can_rxd),
        .tx_o(can_txd),
        .driver_en(can_de),
        .n_read_en(can_re),
        .irq(irq_lines[1]),
        .dslv(db_slv_vector[CFG_CAN])
    );

    assign irq_lines[15:2] = '0;

    //debug
    // assign can_tx_success = can_inst.can_mod.i_can_registers.tx_successful;
    // assign can_tx_request = can_inst.can_mod.i_can_registers.tx_request;
    // assign can_need_to_tx = can_inst.can_mod.i_can_registers.need_to_tx;
    // assign can_sample_point = can_inst.can_mod.i_can_registers.sample_point;
    // assign can_tx_err_cnt = can_inst.can_mod.i_can_bsp.tx_err_cnt;
    // assign can_error_status = can_inst.can_mod.i_can_bsp.error_status;
    // assign can_error_irq = can_inst.can_mod.i_can_registers.error_irq;
    // assign can_error_trasmitting = can_inst.can_mod.i_can_registers.transmitting;
    // assign can_abort_tx = can_inst.can_mod.i_can_registers.abort_tx;
    // assign core_pc = corewrap_inst.cv32e40p_inst.core_i.if_stage_i.pc_id_o;
    
    

endmodule