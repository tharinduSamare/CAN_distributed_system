import data_bus_pkg::*;
import config_pkg::*;

module db_reg_intf #(
    parameter N_WORDS=1,
    parameter base_addr_type base_addr = 32'h1 << $clog2(N_WORDS), // ex:- 32'h0001_0000 (N_WORDS = 2^16)
    parameter addr_mask_type addr_mask = base_addr-1, // ex:- 32'h0000_ffff (N_WORDS = 2^16)
    parameter logic [N_WORDS-1:0] [31:0] reg_init = '0
) (
    input logic clk,
    input logic rst,
    output logic [N_WORDS-1:0] [31:0] reg_data_o,
    input logic [N_WORDS-1:0] [31:0] reg_data_i,
    output logic reg_read_o,
    input logic new_data_i,

    DATA_BUS.Slave dslv
);


    typedef enum { IDLE, ACCESS, BUSY, BUSY_ACCESS } ACCESS_STATE;
    ACCESS_STATE state_q, state_d;
    logic [N_WORDS-1:0][31:0] reg_data_q, reg_data_d;
    logic [31:0]rdata_q, rdata_d;
    logic reg_read_o_d;

    base_addr_type address;
    assign address = (dslv.addr & ~addr_mask) >> 2; // select only the local address with 4 byte alignment

    assign reg_data_o = reg_data_q;

    assign dslv.err = 1'b0;
    assign dslv.conf.base_addr = base_addr;
    assign dslv.conf.addr_mask = addr_mask;

    //FSM
    always_comb begin
        state_d = state_q;
        case (state_q)
            IDLE: begin
                if(new_data_i) begin
                    if(dslv.req && ~dslv.we)begin
                        state_d = BUSY_ACCESS; // peripheral write + bus read
                    end
                    else begin
                        state_d = BUSY; // peripheral write
                    end
                end
                else if(dslv.req) begin // bus read / bus write
                    state_d = ACCESS;
                end
            end
            BUSY: begin
                if(new_data_i && (dslv.req && ~dslv.we)) begin // peripheral write + bus read
                    state_d = BUSY_ACCESS;
                end
                else if(!new_data_i) begin
                    if(dslv.req) begin // bus read / bus write
                        state_d = ACCESS;
                    end
                    else begin
                        state_d = IDLE;
                    end
                end
            end
            ACCESS:begin
                if(new_data_i) begin
                    if(dslv.req && ~dslv.we)begin
                        state_d = BUSY_ACCESS; // peripheral write + bus read
                    end
                    else begin
                        state_d = BUSY; // peripheral write
                    end
                end
                else if(!dslv.req) begin
                    state_d = IDLE;
                end
            end
            BUSY_ACCESS:begin
                if (~new_data_i) begin
                    if(dslv.req) begin
                        state_d = ACCESS;
                    end
                    else begin
                        state_d = IDLE;
                    end
                end
                else begin
                    if(!(dslv.req && ~dslv.we)) begin
                        state_d = BUSY;
                    end
                end
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) state_q <= IDLE;
        else state_q <= state_d;
    end

    // consider dslv.be write mask
    logic [31:0]wdata_wire;
    genvar i;
    for (i=0; i<4; i++) begin
        assign wdata_wire[i*8+:8] = (dslv.be[i]==1'b1)? dslv.wdata[i*8+:8] : reg_data_q[address][i*8+:8];
    end

    // data path
    always_comb begin
        reg_data_d = reg_data_q;
        dslv.gnt = 1'b0;
        dslv.rvalid = 1'b0;
        reg_read_o_d = 1'b0;
        rdata_d = '0;
        case (state_q)
            IDLE: begin
                dslv.rvalid = 0;
                if(new_data_i) begin
                    reg_data_d = reg_data_i;
                end
                else if(dslv.req && dslv.we && ~new_data_i) begin // bus write only allowed when no peripheral write
                    dslv.gnt = 1'b1;
                    reg_data_d[address] = wdata_wire;
                end

                if(dslv.req && ~dslv.we) begin // bus read can be done even during peripheral write
                    dslv.gnt = 1'b1;
                    rdata_d = reg_data_q[address];
                    reg_read_o_d = 1'b1;
                end          
            end
            ACCESS: begin
                dslv.rvalid = 1'b1;
                if(new_data_i) begin
                    reg_data_d = reg_data_i;
                end
                if(dslv.req && dslv.we && ~new_data_i) begin     // successive write req (only allowed when no peripheral write)
                    dslv.gnt = 1'b1;
                    reg_data_d[address] = wdata_wire;
                end 
                
                if (dslv.req && ~dslv.we) begin         // successive read req (can be done even during peripheral write)
                    dslv.gnt = 1'b1;
                    rdata_d = reg_data_q[address];
                    reg_read_o_d = 1'b1;
                end
            end
            BUSY: begin
                if(new_data_i) begin // successive peripheral write
                    reg_data_d = reg_data_i;
                end
                else if(dslv.req && dslv.we && ~new_data_i) begin // bus write only allowed when no peripheral write
                    dslv.gnt = 1'b1;
                    reg_data_d[address] = wdata_wire;
                end
                if(dslv.req && ~dslv.we) begin // bus read can be done even during peripheral write
                    dslv.gnt = 1'b1;
                    rdata_d = reg_data_q[address];
                    reg_read_o_d = 1'b1;
                end  
            end
            BUSY_ACCESS:begin
                dslv.rvalid = 1'b1;
                if(new_data_i) begin // successive peripheral write
                    reg_data_d = reg_data_i;
                end
                else if(dslv.req && dslv.we && ~new_data_i) begin // bus write only allowed when no peripheral write
                    dslv.gnt = 1'b1;
                    reg_data_d[address] = wdata_wire;
                end
                if(dslv.req && ~dslv.we) begin // bus read can be done even during peripheral write
                    dslv.gnt = 1'b1;
                    rdata_d = reg_data_q[address];
                    reg_read_o_d = 1'b1;
                end  
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            reg_data_q <= reg_init;
            rdata_q <= '0;
            reg_read_o <= 1'b0;
        end else begin
            reg_data_q <= reg_data_d;
            rdata_q <= rdata_d;
            reg_read_o <= reg_read_o_d;
        end
    end

    assign dslv.rdata = rdata_q;

endmodule