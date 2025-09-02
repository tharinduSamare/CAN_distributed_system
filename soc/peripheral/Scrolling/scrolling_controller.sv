module scrolling_controller(
    input logic clk,
    input logic rst,
    input logic on_off,
    output logic cnt_start,
    input logic cnt_done,
    output logic next_char,
    input logic [4:0] hex_char,
    output logic [3:0] seg_data,
    output logic seg_off,
    output logic seg_shift,
    output logic seg_write,
    output logic seg_clear
);

typedef enum { OFF, UPDATE, WAIT } STATE;
STATE state_q, state_d;

always_ff @( posedge clk ) begin 
    if(rst) begin
        state_q <= OFF;
    end
    else begin
        state_q <= state_d;
    end
end

always_comb begin 
    state_d = state_q;
    cnt_start = '0;
    next_char = '0;
    seg_data = '0;
    seg_off = '0;
    seg_shift = '0;
    seg_write = '0;
    seg_clear = '0;
    case (state_q)
        OFF: begin
            if(rst) begin
                state_d = OFF;
                seg_clear = 1;
            end
            else if(on_off == 0) begin
                state_d = OFF;
            end
            else begin // on_off = 1
                state_d = UPDATE;
                cnt_start = '1;
                next_char = '1;
                seg_data = hex_char[3:0];
                seg_off = hex_char[4];
                seg_shift = '1;
                seg_write = '1;
            end
        end
        UPDATE: begin
            if (on_off) begin
                state_d = OFF;
                seg_clear = '1;
            end
            else begin
                state_d = WAIT;
                seg_data = hex_char[3:0];
                seg_off = hex_char[4];
                seg_shift = '1;
                seg_write = '1;
            end
        end
        WAIT: begin
            if (on_off) begin
                state_d = OFF;
                seg_clear = '1;
            end
            else if (cnt_done) begin
                state_d = UPDATE;
                cnt_start = '1;
                next_char = '1;
            end
            else begin
                state_d = WAIT;
            end
        end 
    endcase
    
end


endmodule