import config_pkg::*;

`ifndef PROGRAMFILENAME
    `define PROGRAMFILENAME "/import/lab/esylab/esylab01/ESL/esylabrv/programs/main.rom"
    // `define PROGRAMFILENAME "/import/lab/esylab/esylab01/ESL/esylabrv/programs/blinky.rom"
`endif

module memdiv_32 (
    input logic clk, //clock signal
    input logic rst, //reset signal, active high, synchronous

    input logic [31:0] dmem_write_data,
    input logic [31:0] dmem_addr,
    input logic [ 1:0] dmem_size,
    input logic dmem_read_en,
    input logic dmem_write_en,

    output logic [31:0] dmem_read_data,
    output logic dmem_ready,
    
    input logic [31:0] imem_addr,
    input logic imem_read_en,

    output logic [31:0] imem_read_data,
    output logic imem_ready,

    output logic fault //fault signal, active high
  );
    parameter integer width = 32;

    //memory array
    logic [31:0] memory      [0:  IMEMSZ-1];
    
    //init memory array with program file
    initial begin
        // $readmemh(PROGRAMFILENAME, memory);
        $readmemh(`PROGRAMFILENAME, memory);
        // $readmemh("<path-to-esylabrv>/programs/blinky.rom", memory);
    end

    // internal data signals for use with ready signals in simulation
    logic [31:0] imem_data;
    logic [31:0] dmem_data;

    // fault signal for dmem read fault
    logic dmem_read_fault;
    // fault signal for dmem write fault
    logic dmem_write_fault;
    // fault signal for imem read faults
    logic imem_read_fault;

    // fault logic
    assign fault = dmem_read_fault || dmem_write_fault || imem_read_fault;

    // imem read
    always @(posedge clk) begin
        // variable to store calculated word address
        int wordaddress;
        if (rst) begin
            // in reset, set outputs to 0 and no fault
            imem_data <= '{default: '0};
            imem_ready <= 1'b1;
            imem_read_fault <= 1'b0;
        end

        else if (imem_read_en) begin
	        // if read is enabled
	        // set no fault
	        imem_read_fault <= 1'b0;
	
	        // calculate word address
            wordaddress = int'({2'b00, imem_addr[$high(imem_addr) : 2]});
	
            // read data
            if (wordaddress < IMEMSZ) begin
                imem_data[31: 0] <= memory[wordaddress];
            end else begin
                // memory access out of bounds
                imem_read_fault <= 1'b1;
                imem_data <= '{default: 'X};
            end
        end
    end

    // dmem read
    always @(posedge clk) begin :dmem_read
       // calculated word address
       int wordaddress;
       // Calculated word address
       logic [1:0] byteaddress;
       //read full word
       logic [31:0] word;

       if (rst) begin
            // In reset, zero output and no fault
            dmem_data <= '{default: '0};
            dmem_read_fault <= 1'b0;
        end

        else begin
            // Standard output
            dmem_read_fault <= 1'b0;
            if (dmem_read_en)begin
                // If read is enabled, otherwise keep old data
                // Calculate word address and address of byte inside of word
                // wordaddress = int'(in_dmem.read_addr[$high(in_dmem.read_addr): 2]);
                wordaddress = int'({2'b00, dmem_addr[$high(dmem_addr) : 2]});
                byteaddress = dmem_addr[1:0];

                if (!wordaddress) dmem_data <= '{default: '0};

                else if (wordaddress < IMEMSZ) begin
                    // In memory range
                    // Read word from memory array
                    // // word = memory[wordaddress];
                    // word[31:24] = memory[wordaddress+3];
                    // word[23:16] = memory[wordaddress+2];
                    // word[15: 8] = memory[wordaddress+1];
                    word[31 : 0] = memory[wordaddress];
      
                    // Get correct bits from full word
                    case (dmem_size)
                        2'b00: begin // Byte access
                            // Clear non-byte bits
                            dmem_data[31:8] <= '{default: '0};
                            // Fill last byte of output word with read data
                            case (byteaddress)
                                2'b00: dmem_data[7:0] <= word[31:24];
                                2'b01: dmem_data[7:0] <= word[23:16];
                                2'b10: dmem_data[7:0] <= word[15:8];
                                2'b11: dmem_data[7:0] <= word[7:0];
                                default: dmem_data[7:0] <= '{default: 'X}; // will not happen in synthesis, but might in simulation
                            endcase
                        end
                        2'b01: begin // Halfword access
                            // Clear non-halfword bits
                            dmem_data[31:16] <= '{default: '0};
                                // Fill last halfword of output word with read data
                            case (byteaddress)
                                2'b00: dmem_data[15:0] <= word[31:16];
                                2'b01: dmem_data[15:0] <= word[31:16];
                                2'b10: dmem_data[15:0] <= word[15:0];
                                2'b11: dmem_data[15:0] <= word[15:0];
                                default: begin
                                    //memory access exceeds word boundaries
                                    dmem_read_fault <= 1'b1;
                                    assert (0)//assert false
                                        else $error("memory access exceeds word boundaries (16bit dmem read at %d)", dmem_addr);
                                end
                            endcase
                        end
                        2'b10 : begin//word access
                            //fill all bits of output word with read data
                            if (byteaddress == 2'b00) dmem_data <= word;
                            else begin
                                //memory access exceeds word boundaries
                                dmem_read_fault <= 1'b1;
                                assert (0)//assert false
                                    else $error("memory access exceeds word boundaries (32bit dmem read at %d)", dmem_addr);
                            end
                        end
                        default: begin
                            // memory size not implemented
                            dmem_read_fault <= 1'b1;
                            assert (0)//assert false
                                else $error("memory size not implemented");
                        end
                    endcase
                end

                else begin //(wordaddress >= size)
                    // memory access out of bounds
                    dmem_read_fault <= 1'b1;
                    dmem_data <= '{default: 'X};
                    assert (0)//assert false
                        else $error("memory access out of bound (dmem read at %d)", dmem_addr);
                end
            end
        end
    end

    //dmem write
    always @(posedge clk) begin : dmem_write
        // calculated word address
        int wordaddress;
        // Calculated word address
        logic [1:0] byteaddress;
        //read full word
        logic [width - 1:0] word;

        byteaddress = dmem_addr[1:0];
        wordaddress = int'({2'b00, dmem_addr[$high(dmem_addr) : 2]});
            
        if (rst) begin
            dmem_write_fault <= 1'b0;
            // write_state	<= read_old;
            // old_word <= '{default: '0};
            dmem_ready <= 1'b1; 
        end

        else if (dmem_write_en) begin
            case (dmem_size)
                2'b00: begin //byte access
                    case (byteaddress)
                        2'b00: word[31:24] = dmem_write_data[7:0];
                        2'b01: word[23:16] = dmem_write_data[7:0];
                        2'b10: word[15:8]  = dmem_write_data[7:0];
                        2'b11: word[7:0]   = dmem_write_data[7:0];
                        default: begin
                            //will not happen in synthesis, but might in simulation
                            word[7:0] = '{default: 'X};
                        end
                    endcase
                end

                2'b01: begin //halfword access
                    case (byteaddress)
                        2'b00: word[31:16] = dmem_write_data[15:0];
                        2'b01: word[23:8]  = dmem_write_data[15:0];
                        2'b10: word[15:0]  = dmem_write_data[15:0];
                        default: begin
                            //memory access exceeds word boundaries
							dmem_write_fault <= 1'b1;
                            assert (0)//assert false
                                else $error("memory access out of bound (16bit dmem write at %d)", dmem_addr);
                        end
                    endcase
                end

                2'b10: begin
                    if (byteaddress == 2'b00) 
                        word = dmem_write_data;
                    else begin
                        //memory access exceeds word boundaries
                        dmem_write_fault <= 1'b1;
                        assert (0)//assert false
                            else $error("memory size not implemented");
                    end
                end
            endcase

            // memory[wordaddress+3] = word[31:24];
            // memory[wordaddress+2] = word[23:16];
            // memory[wordaddress+1] = word[15: 8];
            memory[wordaddress]   = word[31: 0];

        end
    end	

    assign imem_read_data = imem_data;
    // assign imem_ready     = imem_ready;
    assign dmem_read_data = dmem_data;
    // assign dmem_ready     = dmem_ready;

endmodule
