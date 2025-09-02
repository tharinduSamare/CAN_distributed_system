import data_bus_pkg::*;
import config_pkg::*;

module memwrapper #(
    parameter base_addr_type base_addr = CFG_BADR_MEM,
    parameter addr_mask_type addr_mask = CFG_MADR_MEM
) (
    input  logic clk,
    input  logic rst,

    output logic fault,
    
    INSTR_BUS.Slave islv,
    DATA_BUS.Slave dslv
);

    logic [31:0] instr_raddr;
    logic        instr_ren;
    logic [31:0] instr_rdata;
    logic        instr_ready;

    logic [31:0] data_wdata;
    logic [31:0] data_addr;
    logic [ 1:0] data_size;
    logic        data_ren;
    logic        data_wen;
    logic [31:0] data_rdata;
    logic        data_ready;

    logic mem_fault;

    assign fault = 0;

    memdiv_32 mem_inst (
		.clk(clk),
		.rst(rst),
        .dmem_write_data (data_wdata),
        .dmem_addr       (data_addr),
        .dmem_size       (data_size),
        .dmem_read_en    (data_ren),
        .dmem_write_en   (data_wen),
        .dmem_read_data  (data_rdata),
        .dmem_ready      (data_ready),
        .imem_addr       (instr_raddr),
        .imem_read_en    (instr_ren),
        .imem_read_data  (instr_rdata),
        .imem_ready      (instr_ready),
		.fault           (mem_fault)
	);

    mem2db #(
        .base_addr(base_addr),
        .addr_mask(addr_mask)
    ) mem2db_inst (
        .clk(clk),
        .rst(rst),
        .fault(0),
        .wdata(data_wdata),
        .addr (data_addr ),
        .size (data_size ),
        .ren  (data_ren  ),
        .wen  (data_wen  ),
        .rdata(data_rdata),
        .ready(data_ready),
        .dslv (dslv)
	);

    mem2ib mem2ib_inst (
        .clk(clk),
        .rst(rst),
        .fault(0),
        .raddr(instr_raddr),
        .ren  (instr_ren  ),
        .rdata(instr_rdata),
        .ready(instr_ready),
        .islv (islv)
	);

endmodule