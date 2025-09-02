package data_bus_pkg;
	
	parameter int NMST = 4;  //Number of master connectors on the Interconnect
	parameter int NSLV = 16; //Number of slave connectors on the Interconnect

	// type defenitions

	typedef logic [31:0] base_addr_type;
	typedef logic [31:0] addr_mask_type;

	typedef struct {
		base_addr_type base_addr;
		addr_mask_type addr_mask;
	} config_type;

endpackage
