`timescale 1ns / 1ns

module test_hex2physical;



    // signal declarations
    logic [7:0] cathodes;
    logic [ 4: 0] hex;


   hex2physical dut(
    .hex(hex),
    .cathodes(cathodes)
   );

    initial begin
        hex[4] = 0; // all cathodes should be 1
        #40
        hex[4] = 1;
        // now we can do the test
        for(int i=0; i<16; i=i+1)begin
            hex[3:0] = i;
            #40;
        end
        
        #500
        $finish;
    end
endmodule