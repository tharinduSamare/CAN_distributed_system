import data_bus_pkg::*;
import config_pkg::*;

module data_interconnect (
    input logic clk,
    input logic rst,

    DATA_BUS.Slave  mst [NMST-1 : 0], // .Master and .Slave are reversed because
    DATA_BUS.Master slv [NSLV-1 : 0]  // of the POV of the interconnect 
);

    typedef enum { IDLE, ACCESS } BUS_STATE;

    BUS_STATE state_q, state_d;

    logic        mst_req    [NMST-1 : 0];
	logic [31:0] mst_addr   [NMST-1 : 0];
	logic        mst_we     [NMST-1 : 0];
	logic [ 3:0] mst_be     [NMST-1 : 0];
	logic [31:0] mst_wdata  [NMST-1 : 0];
	logic        mst_gnt    [NMST-1 : 0];
	logic        mst_rvalid [NMST-1 : 0];
	logic        mst_err    [NMST-1 : 0];
	logic [31:0] mst_rdata  [NMST-1 : 0];

    logic        slv_req    [NSLV-1 : 0];
	logic [31:0] slv_addr   [NSLV-1 : 0];
	logic        slv_we     [NSLV-1 : 0];
	logic [ 3:0] slv_be     [NSLV-1 : 0];
	logic [31:0] slv_wdata  [NSLV-1 : 0];
	logic        slv_gnt    [NSLV-1 : 0];
	logic        slv_rvalid [NSLV-1 : 0];
	logic        slv_err    [NSLV-1 : 0];
	logic [31:0] slv_rdata  [NSLV-1 : 0];
	config_type  slv_conf   [NSLV-1 : 0];

    //assign interface signals to internal wires
    generate
        for(genvar i = 0; i < NMST; i++) begin: connect_mst_interface
            assign mst[i].gnt    = mst_gnt[i];
            assign mst[i].rvalid = mst_rvalid[i];
            assign mst[i].err    = mst_err[i];
            assign mst[i].rdata  = mst_rdata[i]; 
            assign mst_req [i]   = mst[i].req;
            assign mst_addr[i]   = mst[i].addr;
            assign mst_we [i]    = mst[i].we;
            assign mst_be [i]    = mst[i].be;
            assign mst_wdata [i] = mst[i].wdata;
         end
    endgenerate

    generate
        for(genvar i = 0; i < NSLV; i++) begin: connect_slv_interface
            assign slv_gnt [i]   = slv[i].gnt;
            assign slv_rvalid[i] = slv[i].rvalid;
            assign slv_err[i]    = slv[i].err;
            assign slv_rdata[i]  = slv[i].rdata; 
            assign slv[i].req    = slv_req [i];
            assign slv[i].addr   = slv_addr[i];
            assign slv[i].we     = slv_we [i];
            assign slv[i].be     = slv_be [i];
            assign slv[i].wdata  = slv_wdata [i];
            assign slv_conf[i]   = slv[i].conf; 
         end
    endgenerate

    logic [NSLV-1:0] slave_select, last_slave_select, current_slave_select;
    logic [NSLV-1:0] gnt_resp_select, slave_resp_select_d, slave_resp_select_q;

    logic        mgnt_req;
	logic [31:0] mgnt_addr;
	logic        mgnt_we;
	logic [ 3:0] mgnt_be;
	logic [31:0] mgnt_wdata;
	logic        ssel_gnt;
	logic        ssel_rvalid;
	logic        ssel_err;
	logic [31:0] ssel_rdata;


    always_comb begin
        for (int i = 0; i < NSLV; i++) begin
            slave_select[i] = (((slv_conf[i].base_addr ^ mgnt_addr) & slv_conf[i].addr_mask) == 0) & SLV_MASK_VECTOR[i] & mgnt_req & (state_q == IDLE);
        end
    end

    always_comb begin: slave_mux_gnt
        ssel_gnt = 0;
        for (int i = 0; i < NSLV; i++)
            if (slave_select[i] == 1) begin
                ssel_gnt = slv_gnt[i];
            end
    end
    
    always_comb begin: slave_mux_rest
        ssel_rvalid = 0;
        ssel_err = 0;
        ssel_rdata = '0;
        for (int i = 0; i < NSLV; i++)
            if (slave_resp_select_q[i] == 1) begin
                ssel_rvalid = slv_rvalid [i];
                ssel_err    = slv_err    [i];
                ssel_rdata  = slv_rdata  [i];
            end
    end

    // always_comb begin: master_mux
    always_comb begin: master_mux
        mgnt_req   <=  0;
        mgnt_addr  <= '0;
        mgnt_we    <=  0;
        mgnt_be    <= '0;
        mgnt_wdata <= '0;
        for (int i = 0; i < NMST; i++)
            if (i == 0) begin
                mgnt_req   <= mst_req   [i];
                mgnt_addr  <= mst_addr  [i];
                mgnt_we    <= mst_we    [i];
                mgnt_be    <= mst_be    [i];
                mgnt_wdata <= mst_wdata [i];
            end
    end

    always_comb begin: slave_demux
        for (int i = 0; i < NSLV; i++)
            if (slave_select[i] == 1) begin
                slv_req   [i] = mgnt_req;
                slv_addr  [i] = mgnt_addr;
                slv_we    [i] = mgnt_we;
                slv_be    [i] = mgnt_be;
                slv_wdata [i] = mgnt_wdata;
            end else begin
                slv_req   [i] =  0;
                slv_addr  [i] = '0;
                slv_we    [i] =  0;
                slv_be    [i] =  0;
                slv_wdata [i] = '0;
            end
    end

    always_comb begin: master_demux
        for (int i = 0; i < NMST; i++)
            if (i == 0) begin
                mst_gnt    [i] = ssel_gnt;
                mst_rvalid [i] = ssel_rvalid;
                mst_err    [i] = ssel_err;
                mst_rdata  [i] = ssel_rdata;
            end else begin
                mst_gnt    [i] =  0;
                mst_rvalid [i] =  0;
                mst_err    [i] =  0;
                mst_rdata  [i] = '0;
            end
    end

    always_ff @(posedge clk) begin: registers
        if(rst == 1) begin
            slave_resp_select_q <= '0;
            state_q <= IDLE;
        end else begin
            slave_resp_select_q <= slave_resp_select_d;
            state_q <= state_d;
        end
    end

    always_comb begin: slave_resp_fsm
        slave_resp_select_d = slave_resp_select_q;
        state_d = state_q;
        case (state_q)
            IDLE: begin                                 // Case: no ongoing access
                if(ssel_gnt) begin                      // If selected slave grants an access
                    state_d  = ACCESS;
                    slave_resp_select_d = slave_select; // Next CC's slave response channel will be set to current slave select
                end else begin
                    state_d  = IDLE;
                    slave_resp_select_d = '0;           // There is no ongoing or requested access: response channel is not connected
                end
            end
            ACCESS: begin                                   // Case: no ongoing access
                if(ssel_rvalid) begin                       // If rvalid is set, the access is concluded
                    if(ssel_gnt) begin                      // If granted master requested a new access that is granted combinationally:
                        state_d  = ACCESS;
                        slave_resp_select_d = slave_select; // Next CC's slave response channel will be set to current slave select
                    end else begin
                        state_d  = IDLE;
                        slave_resp_select_d = '0;           // Last access is conluded and nor new accesses granted: response channel closed
                    end
                end else begin                                  // Ongoing access:
                    slave_resp_select_d = slave_resp_select_q;  // keep open response channel until rvalid is detected
                    state_d  = ACCESS;
                end
            end
        endcase    
    end
    
endmodule