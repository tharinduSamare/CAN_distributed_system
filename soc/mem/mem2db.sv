import data_bus_pkg::*;
import config_pkg::*;

module mem2db #(
	parameter base_addr_type base_addr = CFG_BADR_MEM,
	parameter addr_mask_type addr_mask = CFG_MADR_MEM
	) (
	input  logic clk,
	input  logic rst,

	input  logic fault,

	output logic [31:0] wdata,
    output logic [31:0] addr,
    output logic [ 1:0] size,
    output logic        ren,
    output logic        wen,
    input  logic [31:0] rdata,
    input  logic        ready,

	DATA_BUS.Slave dslv
	);

	typedef enum { IDLE, ACCESS } ACCESS_STATE;
	ACCESS_STATE state_q, state_d;

	typedef struct {
		logic [31 : 0] addr;
		logic we;
		logic size;
		logic wdata;
	} access_type;

	access_type last_access_q, last_access_d;

	assign dslv.rdata = rdata;
	assign dslv.err   = fault;
	assign dslv.conf.base_addr = base_addr;
	assign dslv.conf.addr_mask = addr_mask;
	

	always_comb begin: mem2dslv_fsm
        addr =   dslv.addr;
		size  =  2'b10; //dslv.be;
		ren   = ~dslv.we;
		wen   =  dslv.we;
		wdata =  dslv.wdata;
		last_access_d = last_access_q;
		dslv.gnt = 1'b0;
		dslv.rvalid = 0;
		state_d  = IDLE;
        case (state_q)
            IDLE: begin
				dslv.rvalid = 0;
                if(dslv.req) begin
					dslv.gnt = 1'b1;
					state_d  = ACCESS;
					ren = 1'b1;
					last_access_d.addr  = dslv.addr;
					last_access_d.size  = 2'b10; //dslv.be;
					last_access_d.we    = dslv.we;
					last_access_d.wdata = dslv.wdata;

				end else begin
					dslv.gnt = 1'b0;
					state_d  = IDLE;
					ren      = 1'b0;
				end
            end
            ACCESS: begin
				if(ready) begin            //ready
					dslv.rvalid = 1'b1;
					if(dslv.req) begin     // successive request
						dslv.gnt = 1'b1;
						state_d  = ACCESS;
						ren      = 1'b1;
						last_access_d.addr  = dslv.addr;
						last_access_d.size  = 2'b10; //dslv.be;
						last_access_d.we    = dslv.we;
						last_access_d.wdata = dslv.wdata;
					end else begin         // no new request
						dslv.gnt = 1'b0;
						state_d  = IDLE;
						ren      = 1'b0;
					end
				end else begin             //not ready: stay in ACCESS, keep up ren, 
					dslv.rvalid = 1'b0;    //   no valid data rdy yet, do not grant
					dslv.gnt = 1'b0;       //   new reqest if present
					state_d  = ACCESS;
					ren = 1'b1;
					addr  =  last_access_q.addr;
					size  =  last_access_q.size;
					ren   = ~last_access_q.we;
					wen   =  last_access_q.we;
					wdata =  last_access_q.wdata;
				end
            end
		endcase
    end

	always_ff @(posedge clk) begin: fsm_regs
		if (rst) begin
			state_q <= IDLE;
			last_access_q.addr <= {'0, '0, '0, '0};
		end else begin
			state_q <= state_d;
			last_access_q <= last_access_d;
		end
	end

endmodule