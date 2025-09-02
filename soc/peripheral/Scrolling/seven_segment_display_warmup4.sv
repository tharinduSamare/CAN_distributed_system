module seven_segment_display_warmup4#(
    parameter real CLK_FREQ = 100, // MHz
    parameter real REFRESH_RATE = 100 //Hz
)(
    input logic clk,
    input logic rst,
    input logic [3:0] seg_data,
    input logic seg_off,
    input logic seg_shift,
    input logic seg_write,
    input logic seg_clear,
    output logic [7:0] anodes,
    output logic [7:0] cathodes
);
    logic timer_overflow;
    logic [1:0][31:0] reg_data_o;
    logic [7:0] anode;
    logic [7:0] hex_val;
    assign hex_val = {'0, ~seg_off, seg_data};
    assign anodes = ~ anode;
    
    logic [4:0] hex_d;
    hex2physical hex2physical_inst(
        .hex(hex_d), //when seg_off == 1 then we should turn the 7Seg off. and according to the previouse immplementation it has to be 0 to turn it off
        .cathodes(cathodes)
   );

    localparam int REFRESH_PERIOD = CLK_FREQ * 1000000 / REFRESH_RATE; // number of clk cycles
    localparam int LOW_TIME = REFRESH_PERIOD / 8; // number of clk cycles
    simple_timer  # (LOW_TIME) simple_timer_inst(
        .clk(clk),
        .rst(rst),
        .timer_overflow(timer_overflow)
    );
    
    always_ff @(posedge clk) begin
        if(rst) begin
            reg_data_o[0] <= '0;
            reg_data_o[1] <= '0;
        end
        else begin
            if(seg_clear) begin
                reg_data_o[0] <= '0;
                reg_data_o[1] <= '0;
            end
            else if(seg_write && seg_shift) begin
                reg_data_o[1] <= {hex_val, reg_data_o[1][31:8]};
                reg_data_o[0] <= {reg_data_o[1][7:0], reg_data_o[0][31:8]};
            end
            else if(seg_write) begin
                reg_data_o[1] <= {hex_val, reg_data_o[1][23:0]};
                reg_data_o[0] <= reg_data_o[0];
            end
            else if(seg_shift) begin
                reg_data_o[1] <= {8'b0, reg_data_o[1][31:8]};
                reg_data_o[0] <= {reg_data_o[1][7:0], reg_data_o[0][31:8]};
            end
        end
    end

    logic [2:0] turn;
    logic [7:0] anode_d;

    always_ff @(posedge clk) begin
        if (rst) begin
            anode <= '0;
            turn <= '0;
        end
        else begin
            anode <= anode_d;
            if(timer_overflow) begin
                turn <= (turn +1);  
            end
        end
    end
    always_comb begin 
        hex_d = '0;
        anode_d = anode;
        case(turn)
            0: begin
                hex_d = reg_data_o[0][4:0];
                anode_d = 8'b00000001;
            end
            1: begin
                hex_d = reg_data_o[0][12:8];
                anode_d = 8'b00000010;
            end
            2: begin
                hex_d = reg_data_o[0][20:16];
                anode_d = 8'b00000100;
            end
            3: begin
                hex_d = reg_data_o[0][28:24];
                anode_d = 8'b00001000;
            end
            4: begin
                hex_d = reg_data_o[1][4:0];
                anode_d = 8'b00010000;
            end
            5: begin
                
                hex_d = reg_data_o[1][12:8];
                anode_d = 8'b00100000;
            end
            6: begin
                hex_d = reg_data_o[1][20:16];
                anode_d = 8'b01000000;
            end
            7: begin
                hex_d = reg_data_o[1][28:24];
                anode_d = 8'b10000000;
            end
        endcase
    end



endmodule