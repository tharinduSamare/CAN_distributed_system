import config_pkg::*;

module corewrapper(
    input clk,
    input rst,

    input [15:0] irq_lines,

    INSTR_BUS.Master imst,
    DATA_BUS.Master dmst
);

    logic [31:0] irq_core_in;

    assign irq_core_in [31:16] = irq_lines;
    assign irq_core_in [15: 0] = 0;

    
    cv32e40p_top #(
        .COREV_PULP      (0),  // PULP ISA Extension (incl. custom CSRs and hardware loop, excl. cv.elw)
        .COREV_CLUSTER   (0),  // PULP Cluster interface (incl. cv.elw)
        .FPU             (0),  // Floating Point Unit (interfaced via APU interface)
        .FPU_ADDMUL_LAT  (0),  // Floating-Point ADDition/MULtiplication computing lane pipeline registers number
        .FPU_OTHERS_LAT  (0),  // Floating-Point COMParison/CONVersion computing lanes pipeline registers number
        .ZFINX           (0),  // Float-in-General Purpose registers
        .NUM_MHPMCOUNTERS(1)
    ) cv32e40p_inst (
        // Clock and Reset
        .clk_i (clk),
        .rst_ni(~rst),
    
        .pulp_clock_en_i('0),  // PULP clock enable (only used if COREV_CLUSTER = 1)
        .scan_cg_en_i   ('0),  // Enable all clock gates for testing
    
        // Core ID, Cluster ID, debug mode halt address and boot address are considered more or less static
        .boot_addr_i        (32'h00000080),
        .mtvec_addr_i       (32'h00000000),
        .dm_halt_addr_i     (32'h00000000),
        .hart_id_i          (32'h00000000),
        .dm_exception_addr_i(32'h00000000),
    
        // Instruction memory interface
        .instr_req_o   (imst.req),
        .instr_gnt_i   (imst.gnt),
        .instr_rvalid_i(imst.rvalid),
        .instr_addr_o  (imst.addr),
        .instr_rdata_i (imst.rdata),
    
        // Data memory interface
        .data_req_o   (dmst.req),
        .data_gnt_i   (dmst.gnt),
        .data_rvalid_i(dmst.rvalid),
        .data_we_o    (dmst.we),
        .data_be_o    (dmst.be),
        .data_addr_o  (dmst.addr),
        .data_wdata_o (dmst.wdata),
        .data_rdata_i (dmst.rdata),
    
        // Interrupt inputs
        .irq_i    (irq_core_in),  // CLINT interrupts + CLINT extension interrupts
        .irq_ack_o(),
        .irq_id_o (),
    
        // Debug Interface
        .debug_req_i      ('0),
        .debug_havereset_o(),
        .debug_running_o  (),
        .debug_halted_o   (),
    
        // CPU Control Signals
        .fetch_enable_i(1'b1),
        .core_sleep_o  ()
    );


endmodule