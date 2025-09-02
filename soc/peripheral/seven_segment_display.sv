import data_bus_pkg::*;
import config_pkg::*;

module seven_segment_display #(
    parameter base_addr_type base_addr = CFG_BADR_SevenSegment,
    parameter addr_mask_type addr_mask = CFG_MADR_SevenSegment,
    parameter real CLK_FREQ = 100, // MHz
    parameter real REFRESH_RATE = 100 //Hz
)
(
    input logic clk, //clock signal
    input logic rst, //external reset button
    DATA_BUS.Slave dslv,
    output logic [7:0] cathodes,
    output logic [7:0] AN

);

    localparam N_WORDS = 2; 

    logic [N_WORDS-1:0][31:0] reg_data_o; 
    logic [N_WORDS-1:0][31:0] reg_data_i; 
    logic [4:0] hex;
    logic [7:0] anode;
    assign AN = ~ anode;
    logic new_data_i, timer_overflow;
    logic read_ocur;

    assign new_data_i = 1'b0;
    assign reg_data_i = '0;

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

    hex2physical hex2physical_inst(
        .hex(hex),
        .cathodes(cathodes)
   );

    localparam int REFRESH_PERIOD = CLK_FREQ * 1000000 / REFRESH_RATE; // number of clk cycles
    localparam int LOW_TIME = REFRESH_PERIOD / 8; // number of clk cycles
    simple_timer  # (LOW_TIME) simple_timer_inst(
        .clk(clk),
        .rst(rst),
        .timer_overflow(timer_overflow)
    );
    logic [2:0] turn;
    logic [4:0] hex_d;
    logic [7:0] anode_d;
    always_ff @(posedge clk) begin
        if (rst) begin
            hex <= '0;
            anode <= '0;
            turn <= '0;
        end
        else begin
            hex <= hex_d;
            anode <= anode_d;
            if(timer_overflow) begin
                turn <= (turn +1)%8;  
            end
        end
    end

    always_comb begin 
        //hex_d = reg_data_o[turn/4][(4+8*(turn%4)):(8*(turn%4))];
        //anode_d = 2^turn;
        hex_d = hex;
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