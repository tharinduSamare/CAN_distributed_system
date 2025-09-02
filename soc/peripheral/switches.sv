import data_bus_pkg::*;
import config_pkg::*;

module io_sw #(
    parameter base_addr_type base_addr = CFG_BADR_SW,
    parameter addr_mask_type addr_mask = CFG_MADR_SW
) (
    input  logic clk,
    input  logic rst,

    input logic [4:0] buttons,
    input logic [15:0] switches,
    output logic irq,

    DATA_BUS.Slave dslv
);

localparam N_WORDS = 2; // [buttons, switches]

logic [N_WORDS-1:0][31:0] reg_data_o; // [buttons, switches]
logic [N_WORDS-1:0][31:0] reg_data_i; // [buttons, switches]

logic new_data_i;
logic read_ocur;

db_reg_intf #(
    .N_WORDS(N_WORDS),
    .base_addr(base_addr),
    .addr_mask(addr_mask),
    .reg_init('0)
) db_reg_intf_inst (
    .clk(clk),
    .rst(rst),
    .reg_data_o(reg_data_o),
    .reg_data_i(reg_data_i),
    .reg_read_o(read_ocur),
    .new_data_i(new_data_i),

    .dslv(dslv)
);

    logic pressed;
    assign pressed = |buttons;
    
    always_ff @(posedge clk) begin
        if(rst) begin
            irq <= 1'b0;
        end
        else begin
            if(pressed && ~irq) irq <= 1'b1;
            else if (irq && read_ocur) irq <= 1'b0;
        end
    end

// assign new_data_i = 1'b1; // switches and buttons always write to the register
assign new_data_i = pressed && ~irq;
assign reg_data_i = '{{'0, buttons}, {'0, switches}};

endmodule