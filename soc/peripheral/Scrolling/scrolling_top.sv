import data_bus_pkg::*;
import config_pkg::*;

module scrolling_top #(
    parameter base_addr_type base_addr = CFG_BADR_Scrolling,
    parameter addr_mask_type addr_mask = CFG_MADR_Scrolling,
    parameter real CLK_FREQ = 100, // MHz
    parameter real SEVEN_SEGMENT_REFRESH_RATE = 100, //Hz
    parameter BUFFER_SIZE = 16
)
(
    input logic clk, //clock signal
    input logic rst, //external reset button
    DATA_BUS.Slave dslv,
    output logic [7:0] cathodes,
    output logic [7:0] AN

);

logic cnt_start, cnt_done;
logic [31:0]cnt_value;

scrolling_timer scrolling_timer_inst(
    .clk(clk),
    .rst(rst),
    .cnt_start(cnt_start),
    .cnt_done(cnt_done),
    .cnt_value(cnt_value)
);

logic buffer_clear;
logic buffer_write;
logic [4:0] buffer_data;
logic next_char;
logic [4:0] hex_char;

// scrolling_buffer #(
//         .BUFFER_SIZE(BUFFER_SIZE)) 
//     scrolling_buffer_inst (
//     .clk(clk),
//     .rst(rst),
//     .buffer_clear(buffer_clear),
//     .buffer_write(buffer_write),
//     .buffer_data(buffer_data),
//     .next_char(next_char),
//     .hex_char(hex_char)
// );
scrolling_buffer_adv #(
        .BUFFER_SIZE(BUFFER_SIZE)) 
    scrolling_buffer_inst (
    .clk(clk),
    .rst(rst),
    .buffer_clear(buffer_clear),
    .buffer_write(buffer_write),
    .buffer_data(buffer_data),
    .next_char(next_char),
    .hex_char(hex_char)
);

logic on_off;
logic [3:0] seg_data;
logic seg_off;
logic seg_shift;
logic seg_write;
logic seg_clear;

scrolling_controller scrolling_controller_inst(
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

seven_segment_display_warmup4 #(
        .CLK_FREQ(CLK_FREQ), // MHz
        .REFRESH_RATE(SEVEN_SEGMENT_REFRESH_RATE) //Hz
    )seven_segment_display_inst(
    .clk(clk),
    .rst(rst),
    .seg_data(seg_data),
    .seg_off(seg_off),
    .seg_shift(seg_shift),
    .seg_write(seg_write),
    .seg_clear(seg_clear),
    .anodes(AN),
    .cathodes(cathodes)
);

localparam N_WORDS = 2; // {counter_top, control_signals}
logic [N_WORDS-1:0][31:0] reg_data_o; // {counter_top, control_signals}
logic [N_WORDS-1:0][31:0] reg_data_i; // {counter_top, control_signals}
logic reg_read_o;
logic new_data_i;

db_reg_intf #(
    .N_WORDS(N_WORDS),
    .base_addr(base_addr),
    .addr_mask(addr_mask),
    .reg_init('0)
)db_reg_intf_inst(
    .clk(clk),
    .rst(rst),
    .reg_data_o(reg_data_o),
    .reg_data_i(reg_data_i),
    .reg_read_o(reg_read_o),
    .new_data_i(new_data_i),
    .dslv(dslv)
);

logic [31:0] control_reg_val;
assign control_reg_val = reg_data_o[0];
assign cnt_value    = reg_data_o[1];
assign buffer_write = control_reg_val[24];
assign buffer_clear = control_reg_val[8];
assign buffer_data  = control_reg_val[20:16];
assign on_off       = control_reg_val[0];

assign new_data_i = (buffer_write || buffer_clear || on_off);
//assign new_data_i = 1;
assign reg_data_i = '{reg_data_o[1], '0};

// always_ff @(posedge clk) begin
//     if(rst) begin
//         new_data_i <= 1'b0;
//         reg_data_i <= '0;
//     end
//     else begin
//         // new_data_i
//         if(buffer_write || buffer_clear || on_off) begin // write only when new control signal is available
//             new_data_i <= 1'b1;
//         end
//         else begin
//             new_data_i <= 1'b0;
//         end
//         // control register
//         reg_data_i[0] <= '0; // always reset control register after new control signal
//         reg_data_i[1] <= reg_data_o[1]; // no change to the counter top value
//     end
// end
endmodule