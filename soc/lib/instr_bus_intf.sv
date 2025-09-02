interface INSTR_BUS;

	logic req;
	logic [31:0] addr;
	logic gnt;
	logic rvalid;
	logic err;
	logic [31:0] rdata;

	modport Master (
				input gnt, rvalid, err, rdata,
				output req, addr
	);
	modport Slave (
				input req, addr,
				output gnt, rvalid, err, rdata
	);
	
endinterface