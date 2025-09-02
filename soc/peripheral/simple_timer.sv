module simple_timer # (
    parameter logic [31:0] timer_start
    )(
        input logic clk,
        input logic rst,
        output logic timer_overflow
    );

logic [31:0] timer_count;
logic rst_timer;

always_ff @( posedge clk ) begin 
    if(rst) begin
        timer_count <= timer_start;
    end
    else begin      
        if (rst_timer) begin
            timer_count <= timer_start;
        end else begin
            timer_count <= timer_count -1;
        end
    end
end

always_comb begin
    timer_overflow = 0;
    rst_timer = 0;
    if (timer_count == 0) begin
        timer_overflow = 1;
        rst_timer = 1;
    end
end


endmodule