import data_bus_pkg::*;
import config_pkg::*;

module mem2ib #(
	parameter base_addr_type memaddr = CFG_BADR_MEM,
	parameter addr_mask_type addrmask = CFG_MADR_MEM
	) (
	input logic clk,
	input logic rst,

	output logic [31:0] raddr,
    output logic ren,
    input  logic [31:0] rdata,
    input  logic ready,
	input  logic fault,

	INSTR_BUS.Slave islv
	);

	typedef enum { IDLE, ACCESS } ACCESS_STATE;
	ACCESS_STATE state_q, state_d;

	logic [31:0] last_addr_q, last_addr_d;

	assign islv.rdata = rdata;
	assign islv.err = fault;

	always_comb begin: mem2islv_fsm
        raddr = islv.addr;
		last_addr_d = last_addr_q;
		islv.gnt = 0;
		islv.rvalid = 0;
		ren = 0;
		state_d = IDLE;
        case (state_q)
            IDLE: begin
				islv.rvalid = 0;
                if(islv.req) begin
					islv.gnt = 1'b1;
					state_d  = ACCESS;
					ren = 1'b1;
					last_addr_d = islv.addr;
				end else begin
					islv.gnt = 1'b0;
					state_d  = IDLE;
					ren      = 1'b0;
				end
            end
            ACCESS: begin
				if(ready) begin            //ready
					islv.rvalid = 1'b1;
					if(islv.req) begin     // successive request
						islv.gnt = 1'b1;
						state_d  = ACCESS;
						ren      = 1'b1;
						last_addr_d = islv.addr;
					end else begin         // no new request
						islv.gnt = 1'b0;
						state_d  = IDLE;
						ren      = 1'b0;
					end
				end else begin             //not ready: stay in ACCESS, keep up ren, 
					islv.rvalid = 1'b0;    //   no valid data rdy yet, do not grant
					islv.gnt = 1'b0;       //   new reqest if present
					state_d  = ACCESS;
					ren = 1'b1;
					raddr = last_addr_q;
				end
            end
		endcase
    end

	always_ff @(posedge clk) begin: fsm_regs
		if (rst) begin
			state_q <= IDLE;
			last_addr_q <= '0;
		end else begin
			state_q <= state_d;
			last_addr_q <= last_addr_d;
		end
	end

endmodule