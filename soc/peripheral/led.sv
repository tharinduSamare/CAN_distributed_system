import data_bus_pkg::*;
import config_pkg::*;

module io_led #(
    parameter base_addr_type base_addr = CFG_BADR_LED,
    parameter addr_mask_type addr_mask = CFG_MADR_LED
) (
    input  logic clk, 
    input  logic rst, 

    output logic [7:0] led, 

    DATA_BUS.Slave dslv
);

    logic [31:0] data;

    db_reg_intf_simple #(
        .base_addr(base_addr),
        .addr_mask(addr_mask),
        .reg_init(32'h0000000f)
    ) db_reg_intf_inst(
        .clk(clk),
        .rst(rst),
        .reg_data_o(data),
        .dslv(dslv)
    );

    assign led = data[7:0];
    
endmodule