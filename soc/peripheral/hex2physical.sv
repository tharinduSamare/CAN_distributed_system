module hex2physical(
    input logic [4:0] hex,
    output logic [7:0] cathodes
    );

    logic [7:0] n_cathodes;
    logic CA, CB, CC, CD, CE, CF, CG, DP;

    assign n_cathodes[7] = CA;
    assign n_cathodes[6] = CB;
    assign n_cathodes[5] = CC;
    assign n_cathodes[4] = CD;
    assign n_cathodes[3] = CE;
    assign n_cathodes[2] = CF;
    assign n_cathodes[1] = CG;
    assign n_cathodes[0] = DP;
    
    
    assign cathodes =  ~ n_cathodes; // because Cathodes is active low
    // hex[4] is ised to enable the digit meaning if it is zero turn off the character completely.
    always_comb begin  
        CA = 0;
        CB = 0;
        CC = 0; 
        CD = 0;  
        CE = 0; 
        CF = 0; 
        CG = 0; 
        DP = 0;
        case(hex)
            5'b10000: begin // show 0
                CA = 1;
                CB = 1;
                CC = 1; 
                CD = 1;  
                CE = 1; 
                CF = 1; 
            end
            5'b10001: begin // show 1
                CB = 1;
                CC = 1;
            end
            5'b10010: begin
                CA = 1;
                CB = 1;
                 
                CD = 1;  
                CE = 1; 
                 
                CG = 1;
            end
            5'b10011: begin
                CA = 1;
                CB = 1;
                CC = 1; 
                CD = 1;  
                 
                CG = 1;
            end
            5'b10100: begin
                
                CB = 1;
                CC = 1; 
                 
                CF = 1; 
                CG = 1;
            end
            5'b10101: begin
                CA = 1;
                
                CC = 1; 
                CD = 1;  
                 
                CF = 1; 
                CG = 1;
            end
            5'b10110: begin
                CA = 1;
                
                CC = 1; 
                CD = 1;  
                CE = 1; 
                CF = 1; 
                CG = 1;
            end
            5'b10111: begin
                CA = 1;
                CB = 1;
                CC = 1; 
                
            end
            5'b11000: begin
                CA = 1;
                CB = 1;
                CC = 1; 
                CD = 1;  
                CE = 1; 
                CF = 1; 
                CG = 1;
            end
            5'b11001: begin
                CA = 1;
                CB = 1;
                CC = 1; 
                CD = 1;  
                 
                CF = 1; 
                CG = 1;
            end
            5'b11010: begin// show A
                CA = 1;
                CB = 1;
                CC = 1; 
                 
                CE = 1; 
                CF = 1; 
                CG = 1;
            end
            5'b11011: begin // b
                
                CC = 1; 
                CD = 1;  
                CE = 1; 
                CF = 1; 
                CG = 1;
            end
            5'b11100: begin // C
                CA = 1;
                
                CD = 1;  
                CE = 1; 
                CF = 1; 
                
            end
            5'b11101: begin // d
                
                CB = 1;
                CC = 1; 
                CD = 1;  
                CE = 1; 
                 
                CG = 1;
            end
            5'b11110: begin // E
                CA = 1;
                 
                CD = 1;  
                CE = 1; 
                CF = 1; 
                CG = 1;
            end
            5'b11111: begin //F
                CA = 1;
                 
                  
                CE = 1; 
                CF = 1; 
                CG = 1;
            end
            default: begin
                // n_cathodes = '0;
            end


        endcase


    end



endmodule