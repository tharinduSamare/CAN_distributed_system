import data_bus_pkg::*;

interface DATA_BUS (input clk);

	logic req;
	logic [31:0] addr;
	logic we;
	logic [ 3:0] be;
	logic [31:0] wdata;
	logic gnt;
	logic rvalid;
	logic err;
	logic [31:0] rdata;
	config_type conf;

	modport Master (
				input gnt, rvalid, err, rdata, conf, clk,
				output req, addr, we, be, wdata
	);
	modport Slave (
				input req, addr, we, be, wdata, clk,
				output gnt, rvalid, err, rdata, conf
	);

	property req_gnt_p;
		@(posedge clk)
		// @(posedge clk) disable iff(rst)
		req |=> ##[0:$](gnt & req);
	endproperty

	property req_rvalid_p;
		@(posedge clk)
		req |-> ##[0:$]rvalid;
	endproperty

	assert property(req_gnt_p)
	// $display("[DBUS_IF] Hit req_gnt_property");
	else   $error("gnt should be high before req goes low again.");

	assert property(req_rvalid_p)
	// $display("[DBUS_IF] Hit req_rvalid_pproperty");
	else $error("rvalid should be high after req goes high");
	
	
endinterface