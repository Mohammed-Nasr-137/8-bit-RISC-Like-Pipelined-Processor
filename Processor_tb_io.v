`timescale 1ns / 1ns

module Processor_TB_I_O;

    reg clk;
    reg rst;
    reg Interrupt;
    reg [7:0] IN_Port;
    // wire [7:0] Out_Port;

    wire [7:0] Result_Debug;
    wire [7:0] PC_Debug;
    
    Processor_Top uut (
        .clk(clk), .rst(rst), .Interrupt(Interrupt),
        .IN_Port(IN_Port),
        // .Out_Port(Out_Port),
        .Result_Debug(Result_Debug), .PC_Debug(PC_Debug)
    );
    
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst = 1; Interrupt = 0; IN_Port = 8'h00;
        #20; rst = 0;
        
        $display("STARTING PIPELINED I/O TEST");
        
        // =========================================================
        // TEST 1: IN R1 (Reads 0x55)
        // =========================================================
        IN_Port = 8'h55; 
        
        // Wait for IN (Addr 00) to reach WB (5 cycles = 50ns)
        #60; 
        
        if (uut.RF.Registers[1] === 8'h55) 
            $display("[PASS] IN R1: 0x55");
        else 
            $display("[FAIL] IN R1: 0x%h (Expected 0x55)", uut.RF.Registers[1]);

        // =========================================================
        // TEST 2: OUT R2 (Writes 0xAA)
        // =========================================================
        // LDM R2 (Addr 05) -> WB at ~110ns
        // OUT R2 (Addr 0B) -> WB at ~170ns
        #90; // Wait sufficient time for pipeline to flush
        
        // Note: Out_Port will show data from EVERY instruction at WB stage.
        // We check it specifically when the OUT instruction finishes.
        $display("%0t", $time);
        if (Result_Debug === 8'hAA) 
            $display("[PASS] OUT R2: 0xAA");
        else 
            $display("[FAIL] OUT R2: 0x%h (Expected 0xAA)", Result_Debug);

        $stop;
    end
endmodule