module scrolling_timer (
    input logic clk,
    input logic rst,
    input logic cnt_start,
    output logic cnt_done,
    input logic [31:0] cnt_value
);

logic [31:0] timer_count_q;
logic counting;

always_ff @( posedge clk ) begin 
    if(rst) begin
        timer_count_q <= 0;
        counting <= 0;
    end
    else begin 
        if(cnt_start)   begin
            timer_count_q <= cnt_value;
            counting <= 1;
        end  
        else begin
            if(timer_count_q > 0)
            begin
                timer_count_q <= timer_count_q - 1;
            end
            else begin
                counting <= 0;
                timer_count_q <= 0;
            end
            
        end
        
    end
end
always_comb begin 
    cnt_done = 0;
    if(timer_count_q == 0 && counting) begin
        cnt_done = 1;
    end
end

endmodule

