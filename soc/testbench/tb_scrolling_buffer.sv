module tb_scrolling_buffer;

    // Declare signals to connect to the scrolling_buffer module
    logic clk;
    logic rst;
    logic buffer_clear;
    logic buffer_write;
    logic [4:0] buffer_data;
    logic next_char;
    logic [4:0] hex_char;

    // Instantiate the scrolling_buffer module
    scrolling_buffer uut (
        .clk(clk),
        .rst(rst),
        .buffer_clear(buffer_clear),
        .buffer_write(buffer_write),
        .buffer_data(buffer_data),
        .next_char(next_char),
        .hex_char(hex_char)
    );
    localparam CLK_PERIOD = 10; // ns
    // Clock generation (period = 10ns, 50MHz clock)
       initial begin
        clk = 0;
        forever begin
            #(CLK_PERIOD/2) clk = ~clk;
        end
    end

    // Stimulus generation
    initial begin
        // Initialize signals
        buffer_clear = 0;
        buffer_write = 0;
        buffer_data = 5'd0;
        next_char = 0;
        rst = 1;
        // Apply reset
        $display("Applying reset...");
        #10;
        rst = 0;
        
        // Test 1: Write data into the buffer
        $display("Writing data into buffer...");
        buffer_write = 1;
        buffer_data = 5'd5;  // Write value 5 into buffer
        #10;
        buffer_write = 0;
        buffer_data = 5'd0;  // Reset buffer_data to 0
        
        // Test 2: Read data from the buffer
        $display("Reading data from buffer...");
        next_char = 1;
        #10;
        $display("hex_char = %d", hex_char);  // Expected output: hex_char = 5

        // Test 3: Write more data into the buffer
        $display("Writing more data into buffer...");
        buffer_write = 1;
        buffer_data = 5'd10;  // Write value 10 into buffer
        #10;
        buffer_write = 0;
        buffer_data = 5'd0;  // Reset buffer_data to 0

        // Test 4: Read new data from the buffer
        $display("Reading new data from buffer...");
        next_char = 1;
        #10;
        $display("hex_char = %d", hex_char);  // Expected output: hex_char = 10
        next_char = 0;

        // Test 5: Clear the buffer
        $display("Clearing the buffer...");
        buffer_clear = 1;
        #10;
        buffer_clear = 0;

        // Test 6: Verify empty buffer behavior (no data to read)
        $display("Reading from empty buffer...");
        next_char = 1;
        #10;
        $display("hex_char = %d", hex_char);  // Expected output: hex_char = 0

        // Test 7: Reset the buffer and check behavior
        $display("Resetting the buffer...");
        rst = 1;
        #10;
        rst = 0;

        // Test 8: Verify the buffer after reset (should output 0)
        next_char = 1;
        #10;
        next_char = 0;
        $display("Writing more data into buffer...");
        buffer_write = 1;
        buffer_data = 5'd1;  // Write value 10 into buffer
        
        #10 buffer_data = 5'd17;
        #10 buffer_data = 5'd16;
        #10 buffer_data = 5'd15;
        #10 buffer_data = 5'd14;
        #10 buffer_data = 5'd13;
        #10 buffer_data = 5'd12;
        #10 buffer_data = 5'd11;
        #10 buffer_data = 5'd10;
        #10 buffer_data = 5'd9;
        #10 buffer_data = 5'd8;
        #10 buffer_data = 5'd7;
        #10 buffer_data = 5'd6;
        #10 buffer_data = 5'd5;
        #10 buffer_data = 5'd4;
        #10 buffer_data = 5'd3;
        #10 buffer_data = 5'd2;
        #10 buffer_data = 5'd1;
        #10 buffer_data = 5'd18;
        #10 buffer_data = 5'd20;
        #10
        buffer_write = 0;
        next_char = 1;
        #180
        next_char = 0;

        $display("hex_char = %d", hex_char);  // Expected output: hex_char = 0
        #20;
        $finish;
    
    end

endmodule
