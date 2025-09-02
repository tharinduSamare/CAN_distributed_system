import data_bus_pkg::*;
import config_pkg::*;

module db_reg_intf_simple #(
	parameter base_addr_type base_addr = CFG_BADR_LED,
	parameter addr_mask_type addr_mask = CFG_MADR_LED,

	parameter logic [31:0] reg_init  = '0
	) (
	input  logic clk,
	input  logic rst,

	output logic [31:0] reg_data_o,
	
	DATA_BUS.Slave dslv
	);

	typedef enum { IDLE, ACCESS } ACCESS_STATE;
	ACCESS_STATE state_q, state_d;
	logic [31:0] reg_data_q, reg_data_d;

	assign reg_data_o = reg_data_q;

	assign dslv.err = 1'b0;
	assign dslv.conf.base_addr = base_addr;
	assign dslv.conf.addr_mask = addr_mask;
	
	always_comb begin: mem2dslv_fsm
		reg_data_d = reg_data_q;
		dslv.gnt = 0;
		dslv.rvalid = 0;
		state_d = state_q;
        case (state_q)
            IDLE: begin
				dslv.rvalid = 0;
                if(dslv.req) begin
					dslv.gnt = 1'b1;
					if (dslv.we)  // write request
						reg_data_d = dslv.wdata;					
					state_d  = ACCESS;
				end else begin
					dslv.gnt = 1'b0;
					state_d  = IDLE;
				end
            end
            ACCESS: begin
				dslv.rvalid = 1'b1;
				if(dslv.req) begin     // successive request
					dslv.gnt = 1'b1;
					state_d  = ACCESS;
					if (dslv.we)
						reg_data_d = dslv.wdata;
				end else begin         // no new request
					dslv.gnt = 1'b0;
					state_d  = IDLE;
				end
            end
		endcase
    end

	always_ff @(posedge clk) begin: fsm_regs
		if (rst) begin
			state_q <= IDLE;
			reg_data_q <= reg_init;
		end else begin
			state_q <= state_d;
			reg_data_q <= reg_data_d;
		end
	end

endmodule