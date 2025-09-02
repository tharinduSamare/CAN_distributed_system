`timescale 1ns / 1ns

module tb_can_dual;

  parameter time clk_period = 10;
  logic clk = 0;
  logic rst;

  // CAN bus lines
  logic tx_a, tx_b;
  logic rx_a, rx_b;

  // CAN controller interface signals
  logic irq_a, irq_b;
  logic driver_en_a, driver_en_b;
  logic n_read_en_a, n_read_en_b;

  assign rx_a = tx_b;  // loopback connection
  assign rx_b = tx_a;

  // Instantiate interfaces
  DATA_BUS cfg_if_a();
  DATA_BUS cfg_if_b();

  // Clock generation
  always #(clk_period/2) clk = ~clk;

  // CAN Controller A
  can_wrapper can_a (
    .clk(clk),
    .rst(rst),
    .rx_i(rx_a),
    .tx_o(tx_a),
    .driver_en(driver_en_a),
    .n_read_en(n_read_en_a),
    .irq(irq_a),
    .dslv(cfg_if_a)
  );

  // CAN Controller B
  can_wrapper can_b (
    .clk(clk),
    .rst(rst),
    .rx_i(rx_b),
    .tx_o(tx_b),
    .driver_en(driver_en_b),
    .n_read_en(n_read_en_b),
    .irq(irq_b),
    .dslv(cfg_if_b)
  );

  initial begin
  // Initial conditions
  clk = 0;
  rst = 0;
  cfg_if_a.req = 0;
  cfg_if_b.req = 0;
  cfg_if_a.be = 4'b0001;
  cfg_if_b.be = 4'b0001;
  #20; rst = 1;
  #20; rst = 0;
  #40;

  // --- Node A: Enter reset mode
  cfg_if_a.addr = 32'd0; cfg_if_a.wdata = 32'd1; cfg_if_a.we = 1; cfg_if_a.req = 1;
  wait(cfg_if_a.gnt); wait(cfg_if_a.rvalid); cfg_if_a.req = 0; cfg_if_a.we = 0; #20;

  // --- Node A: Bit timing
  cfg_if_a.addr = 32'd6; cfg_if_a.wdata = 32'd0; cfg_if_a.we = 1; cfg_if_a.req = 1;
  wait(cfg_if_a.gnt); wait(cfg_if_a.rvalid); cfg_if_a.req = 0; cfg_if_a.we = 0; #20;

  cfg_if_a.addr = 32'd7; cfg_if_a.wdata = 32'd0; cfg_if_a.we = 1; cfg_if_a.req = 1;
  wait(cfg_if_a.gnt); wait(cfg_if_a.rvalid); cfg_if_a.req = 0; cfg_if_a.we = 0; #20;

  // --- Node A: Exit reset
  cfg_if_a.addr = 32'd0; cfg_if_a.wdata = 32'd0; cfg_if_a.we = 1; cfg_if_a.req = 1;
  wait(cfg_if_a.gnt); wait(cfg_if_a.rvalid); cfg_if_a.req = 0; cfg_if_a.we = 0; #20;

  // --- Node A: TX ID = 0x123, DLC = 2
  cfg_if_a.addr = 32'd10; cfg_if_a.wdata = 32'd36; cfg_if_a.we = 1; cfg_if_a.req = 1; // ID1 = 0x24
  wait(cfg_if_a.gnt); wait(cfg_if_a.rvalid); cfg_if_a.req = 0; cfg_if_a.we = 0; #20;

  cfg_if_a.addr = 32'd11; cfg_if_a.wdata = 32'd99; cfg_if_a.we = 1; cfg_if_a.req = 1; // ID2 = 0x63 (DLC=3)
  wait(cfg_if_a.gnt); wait(cfg_if_a.rvalid); cfg_if_a.req = 0; cfg_if_a.we = 0; #20;

  // --- Data = 0x00, 0xAB
  cfg_if_a.addr = 32'd12; cfg_if_a.wdata = 32'h00; cfg_if_a.we = 1; cfg_if_a.req = 1;
  wait(cfg_if_a.gnt); wait(cfg_if_a.rvalid); cfg_if_a.req = 0; cfg_if_a.we = 0; #20;

  cfg_if_a.addr = 32'd13; cfg_if_a.wdata = 32'hAB; cfg_if_a.we = 1; cfg_if_a.req = 1;
  wait(cfg_if_a.gnt); wait(cfg_if_a.rvalid); cfg_if_a.req = 0; cfg_if_a.we = 0; #20;

  // --- Node B: Enter reset + bit timing
  cfg_if_b.addr = 32'd0; cfg_if_b.wdata = 32'd1; cfg_if_b.we = 1; cfg_if_b.req = 1;
  wait(cfg_if_b.gnt); wait(cfg_if_b.rvalid); cfg_if_b.req = 0; cfg_if_b.we = 0; #20;

  cfg_if_b.addr = 32'd6; cfg_if_b.wdata = 32'd0; cfg_if_b.we = 1; cfg_if_b.req = 1;
  wait(cfg_if_b.gnt); wait(cfg_if_b.rvalid); cfg_if_b.req = 0; cfg_if_b.we = 0; #20;

  cfg_if_b.addr = 32'd7; cfg_if_b.wdata = 32'd0; cfg_if_b.we = 1; cfg_if_b.req = 1;
  wait(cfg_if_b.gnt); wait(cfg_if_b.rvalid); cfg_if_b.req = 0; cfg_if_b.we = 0; #20;

  // --- Node B: Exit reset
  cfg_if_b.addr = 32'd0; cfg_if_b.wdata = 32'd0; cfg_if_b.we = 1; cfg_if_b.req = 1;
  wait(cfg_if_b.gnt); wait(cfg_if_b.rvalid); cfg_if_b.req = 0; cfg_if_b.we = 0; #20;

  // --- Start TX from A
  cfg_if_a.addr = 32'd1; cfg_if_a.wdata = 32'd1; cfg_if_a.we = 1; cfg_if_a.req = 1;
  wait(cfg_if_a.gnt); wait(cfg_if_a.rvalid); cfg_if_a.req = 0; cfg_if_a.we = 0; #20;

  // --- Wait and Check TX Complete
  
  cfg_if_a.addr = 32'd2; cfg_if_a.req = 1; cfg_if_a.we = 0;
  wait(cfg_if_a.gnt); wait(cfg_if_a.rvalid); 

  // --- Check RX Complete
  cfg_if_b.addr = 32'd2; cfg_if_b.req = 1; cfg_if_b.we = 0;
  wait(cfg_if_b.gnt); wait(cfg_if_b.rvalid); 

  #1000
  if (cfg_if_a.rdata[3]) $display("✅ CAN A: Transmission complete");
  else                   $display("❌ CAN A: Transmission NOT complete");
  if (cfg_if_b.rdata[0]) $display("✅ CAN B: Frame received");
  else                   $display("❌ CAN B: No frame received");
  /*
   // --- Read Received Data
  cfg_if_b.addr = 32'd20; cfg_if_b.req = 1; cfg_if_b.we = 0; wait(cfg_if_b.gnt); wait(cfg_if_b.rvalid); cfg_if_b.req = 0;
  $display("RX ID1 = %02x", cfg_if_b.rdata);

  cfg_if_b.addr = 32'd21; cfg_if_b.req = 1; cfg_if_b.we = 0; wait(cfg_if_b.gnt); wait(cfg_if_b.rvalid); cfg_if_b.req = 0;
  $display("RX ID2 = %02x", cfg_if_b.rdata);

  cfg_if_b.addr = 32'd22; cfg_if_b.req = 1; cfg_if_b.we = 0; wait(cfg_if_b.gnt); wait(cfg_if_b.rvalid); cfg_if_b.req = 0;
  $display("RX DATA0 = %02x", cfg_if_b.rdata);

  cfg_if_b.addr = 32'd23; cfg_if_b.req = 1; cfg_if_b.we = 0; wait(cfg_if_b.gnt); wait(cfg_if_b.rvalid); cfg_if_b.req = 0;
  $display("RX DATA1 = %02x", cfg_if_b.rdata);

  */
 
  #100;
  $finish;
end

endmodule