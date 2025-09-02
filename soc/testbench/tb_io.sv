module tb_io;


    logic clk = 0;
    logic rst = 0;
    always #5 clk = ~clk;

    // signal declarations
    logic [4:0]  buttons; // inputs
    logic [15:0] switches; // inputs

    DATA_BUS dslv();
    io_sw io_dut(
        .clk(clk), 
        .rst(rst), 

        .buttons(buttons), 
        .switches(switches),
        .dslv(dslv)
    );
    

    initial begin
        #10
        rst = 1;
        #10
         rst = 0;
        #10;
        buttons = 'b10101;
        switches = '1;

        dslv.req = 0;
        dslv.addr = 0;
        dslv.we = 0;
        dslv.be = '1;
        dslv.wdata = '0;
        
        // read from the switches
        #20
        dslv.we = 0;
        dslv.req = 1;
        wait(dslv.gnt);
        wait(dslv.rvalid);
        #10
        dslv.req = 0;

        #100;
        
        $finish;
    end
endmodule