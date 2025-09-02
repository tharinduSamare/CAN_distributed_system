module scrolling_buffer_adv #(BUFFER_SIZE = 16) (
    input logic clk,
    input logic rst,
    input logic buffer_clear,
    input logic buffer_write,
    input logic [4:0] buffer_data,
    input logic next_char,
    output logic [4:0] hex_char
);
    localparam ADDR_WIDTH = $clog2(BUFFER_SIZE);
    logic [BUFFER_SIZE-1:0][4:0] buffer;
    logic signed [ADDR_WIDTH:0] ptr_last;
    logic [ADDR_WIDTH-1:0] ptr_read;
    logic [ADDR_WIDTH-1:0] ptr_write;

    // typedef enum  { read_write, write, read, Idle } buffer_state;

    always_ff @(posedge clk) begin
        if(rst) begin
            ptr_last <= -1;
            ptr_read <= 0;
            ptr_write <= 0;
            buffer <= '0;
        end
        else if (buffer_clear) begin
            ptr_last <= -1;
            ptr_read <= 0;
            ptr_write <= 0;
        end
        else begin
            if(buffer_write) begin
                buffer[ptr_write] <= buffer_data;
                if (ptr_last < BUFFER_SIZE - 1) begin
                    ptr_last <= ptr_last + 1;
                end
                //ptr_write <= (ptr_write + 1) % BUFFER_SIZE
                //ptr_write = ptr_write+1;  // overflow so still same result 
                ptr_write <= (ptr_write == BUFFER_SIZE - 1) ? 4'd0 : ptr_write + 1;
            end
            if(next_char) begin
                if(ptr_last == -1) begin 
                    hex_char <= 5'b10000;
                end 
                else if(ptr_last < 7) begin // there are less than 8 characters in the buffer
                    if(ptr_read <= ptr_last) begin
                        hex_char <= buffer[ptr_read];
                        ptr_read <= ptr_read + 1;
                    end
                    else begin // now ptr_read equals ptr_last + 1 which points to nothing
                        // I will make hex_char = 0 for the remaining time of (8 - ptr_last)
                        if (ptr_read < 8) begin
                            hex_char <= 5'b10000;
                            ptr_read <= (ptr_read == 7) ? 4'd0 : ptr_read + 1;
                        end 
                    end
                end
                else begin
                    hex_char <= buffer[ptr_read];
                    //ptr_read <= (ptr_read + 1) % BUFFER_SIZE
                    //ptr_read = ptr_read+1;  // overflow so still same result 
                    ptr_read <= (ptr_read == ptr_last) ? 4'd0 : ptr_read + 1;
                end
            end
            else begin
                hex_char <= 5'b10000;
            end


        end
    end

endmodule