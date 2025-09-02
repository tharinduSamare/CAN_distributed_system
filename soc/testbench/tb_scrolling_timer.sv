module scrolling_timer_tb;

    // Signals
    logic clk;
    logic rst;
    logic cnt_start;
    logic cnt_done;
    logic [31:0] cnt_value;

    localparam CLK_PERIOD = 10; // ns

    initial begin
        clk = 0;
        forever begin
            #(CLK_PERIOD/2) clk = ~clk;
        end
    end


    // DUT instantiation
    scrolling_timer dut (
        .clk(clk),
        .rst(rst),
        .cnt_start(cnt_start),
        .cnt_done(cnt_done),
        .cnt_value(cnt_value)
    );

    // Test sequence
    initial begin
        // Initial values
        
        rst = 1;
        cnt_start = 0;
        cnt_value = 0;

        // Apply reset
        #10;
        rst = 0;

        // Start timer with a value of 10
        #10;
        cnt_value = 10;
        cnt_start = 1;
        #10;
        cnt_start = 0;

        // Wait enough time for timer to expire
        wait(cnt_done == 1);
        $display("Timer completed at time %t", $time);

        // Hold simulation for a bit
        #20;

        // Second test with different value
        cnt_value = 5;
        cnt_start = 1;
        #10;
        cnt_start = 0;

        wait(cnt_done == 1);
        $display("Second timer completed at time %t", $time);

        #20;
        $finish;
    end

endmodule
