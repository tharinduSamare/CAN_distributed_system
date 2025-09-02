`timescale 1ns / 1ns

module tb_dual_client();

    // Clock period definitions
    parameter time CLK_PERIOD = 10;
    localparam real CLK_FREQ = 1000/CLK_PERIOD; // MHz
    localparam BUTTON_PUSH_DELAY = 2; // keep pressed for n cycles
    localparam BTNM = 0;
    localparam BTNU = 1;
    localparam BTNL = 2;
    localparam BTND = 4;
    
    logic clk = 0;
    logic rstn;

    logic [7 : 0] cathodes[0:1];
    logic [7 : 0] AN[0:1];
    logic [7 : 0] led[0:1];
    logic [4:0] btn[0:1]; //Buttons: 0: BTNC, 1: BTNU, 2: BTNL, 3: BTNR, 4: BTND
    logic [15:0] sw[0:1];

    // CAN_PMOD
    logic can_re[0:1];
    logic can_txd[0:1];
    logic can_rxd[0:1];
    logic can_de[0:1];

    genvar i;
    generate
        for(i=0;i<2; i++)begin
            lt16soc_top #(
                .CLK_FREQ(CLK_FREQ), // MHz;
                .RST_ACTIVE_HIGH(1'b1)
            ) dut (
                .clk_sys(clk),
                .rst(rstn),

                .led(led[i]),
                .sw(sw[i]),
                .btn(btn[i]),
                .AN(AN[i]),
                .cathodes(cathodes[i]),

                .can_re(can_re[i]),
                .can_txd(can_txd[i]),
                .can_rxd(can_rxd[i]),
                .can_de(can_de[i])
            );
            
        end
    endgenerate


    always #(CLK_PERIOD/2) clk = ~clk;

    logic connect_en = 1'b0;

    initial begin
        rstn = 0;
        #(CLK_PERIOD*5);
        rstn = 1;

        btn = {'0, '0};
        sw = {16'd0, 16'd0};

        // connect_en = 1'b0; // disconnect devices;

        #(CLK_PERIOD*500); // wait till initialization tasks
        
        set_speed(16'hFF, clk);
        # 100000
        add_data(5'b10001,clk);
        # 100000
        clear_data(clk);
        # 100000
        add_data(5'b10010,clk);
        # 100000
        add_data(5'b10011,clk);
        # 100000
        add_data(5'b10100,clk);
        # 100000
        // connect_en = 1'b1;
        // # 100000
        // init_dataset(clk);
        // # 500000
        add_data(5'b10101,clk);
        # 100000
        add_data(5'b10110,clk);
        # 100000
        add_data(5'b10111,clk);
        # 100000
        add_data(5'b11000,clk);
        # 100000
        add_data(5'b11001,clk);
        # 100000
        clear_data(clk);
        # 100000
        
        $finish;
    end

    task automatic set_speed(input logic[15:0]counter_val, ref logic clk);
        @(posedge clk);
        sw[0] = counter_val;
        repeat(BUTTON_PUSH_DELAY)#(CLK_PERIOD);
        @(posedge clk);
        btn[0][BTNL] = 1'b1;
        repeat(BUTTON_PUSH_DELAY)#(CLK_PERIOD);
        @(posedge clk);
        sw[0] = '0;
        btn[0][BTNL] = 1'b0;
    endtask //automatic

    task automatic add_data(input logic[4:0]data, ref logic clk);
        @(posedge clk);
        sw[0][4:0] = data;
        repeat(BUTTON_PUSH_DELAY)#(CLK_PERIOD);
        @(posedge clk);
        btn[0][BTNU] = 1'b1;
        repeat(BUTTON_PUSH_DELAY)#(CLK_PERIOD);
        @(posedge clk);
        sw[0][4:0] = '0;
        btn[0][BTNU] = 1'b0;
    endtask

    task automatic clear_data(ref logic clk);
        @(posedge clk);
        btn[0][BTND] = 1'b1;
        repeat(BUTTON_PUSH_DELAY)#(CLK_PERIOD);
        @(posedge clk);
        btn[0][BTND] = 1'b0;
    endtask

    task automatic init_dataset(ref logic clk);
        @(posedge clk);
        btn[1][BTNM] = 1'b1;
        repeat(BUTTON_PUSH_DELAY)#(CLK_PERIOD);
        @(posedge clk);
        btn[1][BTNM] = 1'b0;
    endtask

assign can_rxd[0] = can_txd[1] & can_txd[0];
assign can_rxd[1] = can_txd[1] & can_txd[0];
// assign can_rxd[0] = (connect_en == 1'b0)? can_txd[0] : can_txd[1] & can_txd[0];
// assign can_rxd[1] = (connect_en == 1'b0)? can_txd[0] : can_txd[1] & can_txd[0];
    


endmodule