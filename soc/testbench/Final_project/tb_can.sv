`timescale 1ns / 1ns

module tb_can;

  // Clock period definitions
  parameter time clk_period = 10;
  logic clk = 0;
  logic rst;

  // CAN signals
  logic rx_i, tx_o, driver_en, n_read_en, irq;

  // DATA_BUS interface
  DATA_BUS cfg_if();

  // Instantiate CAN wrapper
  can_wrapper can_dut (
    .clk(clk),
    .rst(rst),
    .rx_i(rx_i),
    .tx_o(tx_o),
    .driver_en(driver_en),
    .n_read_en(n_read_en),
    .irq(irq),
    .dslv(cfg_if)
  );

  // Clock generation
  always #(clk_period/2) clk = ~clk;

  initial begin
    rx_i = 1;
    wait(tx_o == 0);                 // Start of frame (SOF)
    repeat(1440) @(posedge clk);     // Wait until ACK slot (~for short frame)
    rx_i = 0;                        // Drive ACK
    #clk_period;
    rx_i = 1;                        // Release line
  end

  // Test sequence
  initial begin
    // Initial conditions
    clk = 0;
    rst = 0;
    cfg_if.req    = 0;
    cfg_if.addr   = 0;
    cfg_if.we     = 0;
    cfg_if.be     = 4'b0001;
    cfg_if.wdata  = 32'h00000000;

    // Reset pulse
    #20;
    rst = 1;
    #20;
    rst = 0;
    #20;

    // -------------------------------
    // STEP 1: Enter reset mode (MODE = 0x01)
    // -------------------------------
    cfg_if.addr   = 32'h00;
    cfg_if.we     = 1;
    cfg_if.wdata  = 32'h00000001;
    cfg_if.req    = 1; wait(cfg_if.gnt); wait(cfg_if.rvalid);
    cfg_if.req = 0; cfg_if.we = 0;
    #20;

    // -------------------------------
    // STEP 2: Configure Bit Timing
    // BTR0 = 0x00 (SJW = 1, BRP = 1)
    // BTR1 = 0x14 (TSEG1 = 13, TSEG2 = 2, SAM = 0)
    // -------------------------------
    cfg_if.addr   = 32'h06;
    cfg_if.we     = 1;
    cfg_if.wdata  = 32'h00000000;
    cfg_if.req    = 1; wait(cfg_if.gnt); wait(cfg_if.rvalid);
    cfg_if.req = 0; cfg_if.we = 0;
    #20;

    cfg_if.addr   = 32'h07;
    cfg_if.we     = 1;
    cfg_if.wdata  = 32'h00000000;
    cfg_if.req    = 1; wait(cfg_if.gnt); wait(cfg_if.rvalid);
    cfg_if.req = 0; cfg_if.we = 0;
    #20;

    // -------------------------------
    // STEP 3: Exit reset, enter BasicCAN mode (MODE = 0x00)
    // -------------------------------
    cfg_if.addr   = 32'h00;
    cfg_if.we     = 1;
    cfg_if.wdata  = 32'h00000000;
    cfg_if.req    = 1; wait(cfg_if.gnt); wait(cfg_if.rvalid);
    cfg_if.req = 0; cfg_if.we = 0;
    #20;

    // -------------------------------
    // STEP 4: Write TX Identifier 
    // -------------------------------
    // ID[10:3] = 0x24
    cfg_if.addr   = 32'h0A;
    cfg_if.we     = 1;
    cfg_if.wdata  = 32'b00000100;
    cfg_if.req    = 1; wait(cfg_if.gnt); wait(cfg_if.rvalid);
    cfg_if.req = 0; cfg_if.we = 0;
    #20;

    // ID[2:0] = 0x3 (shifted), RTR = 0, DLC = 1 → 0x61
    cfg_if.addr   = 32'h0B;
    cfg_if.we     = 1;
    cfg_if.wdata  = 32'b00010010;
    cfg_if.req    = 1; wait(cfg_if.gnt); wait(cfg_if.rvalid);
    cfg_if.req = 0; cfg_if.we = 0;
    #20;

    // -------------------------------
    // STEP 5: Write one data byte 
    // -------------------------------
    cfg_if.addr   = 32'h0C;
    cfg_if.we     = 1;
    cfg_if.wdata  = 32'h00000000;
    cfg_if.req    = 1; wait(cfg_if.gnt); wait(cfg_if.rvalid);
    cfg_if.req = 0; cfg_if.we = 0;
    #20;

     // -------------------------------
    // STEP 5b: Write Second data byte 
    // -------------------------------
    cfg_if.addr   = 32'h0D;
    cfg_if.we     = 1;
    cfg_if.wdata  = 32'h000000ab;
    cfg_if.req    = 1; wait(cfg_if.gnt); wait(cfg_if.rvalid);
    cfg_if.req = 0; cfg_if.we = 0;
    #20;

    // -------------------------------
    // STEP 6: Issue transmission request
    // -------------------------------
    cfg_if.addr   = 32'h01;
    cfg_if.we     = 1;
    cfg_if.wdata  = 32'h00000001; // Command = TX Request
    cfg_if.req    = 1; wait(cfg_if.gnt); wait(cfg_if.rvalid);
    cfg_if.req = 0; cfg_if.we = 0;
    #20;

    // -------------------------------
    // STEP 7: Wait for transmission to complete
    // -------------------------------
    #200;

    // Optionally read status register (0x02) to check TX complete
    cfg_if.addr   = 32'h02;
    cfg_if.we     = 0;
    cfg_if.req    = 1;
    wait(cfg_if.gnt); wait(cfg_if.rvalid);
    wait(cfg_if.rdata & (1<<5));// wait until the transmission starts
    $display("STATUS REGISTER = %02x", cfg_if.rdata);
    wait(cfg_if.rdata & (1<<3));// wait until the transmission complete
    cfg_if.req    = 0;
    // End simulation
    #100;
    $finish;
  end

endmodule
