`timescale 1ns / 1ps

module Processor_TB_hdu;

    // --- Signals ---
    reg clk;
    reg rst;
    reg Interrupt;
    reg [7:0] IN_Port;
    // wire [7:0] Out_Port;
    wire [7:0] Result_Debug;
    wire [7:0] PC_Debug;

    // --- Instantiate Processor ---
    Processor_Top uut (
        .clk(clk),
        .rst(rst),
        .Interrupt(Interrupt),
        .IN_Port(IN_Port),
        // .Out_Port(Out_Port),
        .Result_Debug(Result_Debug),
        .PC_Debug(PC_Debug)
    );

    // --- Clock Generation ---
    initial clk = 0;
    always #5 clk = ~clk; // 10ns Period

    // --- Test Logic ---
    initial begin
        $display("===================================================");
        $display("       INTEGRATED HAZARD UNIT TEST (STALLING)      ");
        $display("===================================================");
        
        // 1. Initialize
        rst = 1;
        Interrupt = 0;
        IN_Port = 8'h00;
        
        // 2. Load Program Manually (or use $readmemh)
        // LDD R1, [0A] -> C5 0A
        uut.IM.mem[0] = 8'hC5;
        uut.IM.mem[1] = 8'h0A;
        // ADD R2, R1   -> 29
        uut.IM.mem[2] = 8'h29; 
        
        // Initialize Data Memory at 0x0A with value 0x55
        uut.RAM.mem[8'h0A] = 8'h55;

        // 3. Release Reset
        #20;
        rst = 0;
        $display("Time | PC | Inst Fetch | Note");
        $display("-----|----|------------|---------------------------");

        // --- Monitor Execution ---
        
        // Cycle 1: Fetch LDD (PC=0)
        // @(posedge clk); #1; 
        $display("%4t | %2h |     %2h     | Fetch LDD (Part 1)", $time, PC_Debug, uut.Instruction_Bus);

        // Cycle 2: Fetch Imm (PC=1) -> Decode LDD
        @(posedge clk); #1;
        $display("%4t | %2h |     %2h     | Fetch Imm (Part 2)", $time, PC_Debug, uut.Instruction_Bus);

        // Cycle 3: Fetch ADD (PC=2) -> Execute LDD
        // HDU Logic Check:
        // LDD is in EX stage (ID_EX_MemRead=1, Dest=R1). 
        // ADD is in ID stage (Reads R1).
        // STALL SHOULD TRIGGER HERE.
        @(posedge clk); #1;
        $display("%4t | %2h |     %2h     | Fetch ADD (Potential Hazard)", $time, PC_Debug, uut.Instruction_Bus);

        // Cycle 4: STALL CYCLE
        // If Stalled: PC should STILL be 2 (ADD).
        @(posedge clk); #1;
        if (PC_Debug === 8'h02) 
            $display("%4t | %2h |     --     | [PASS] STALL DETECTED! PC Frozen.", $time, PC_Debug);
        else 
            $display("%4t | %2h |     --     | [FAIL] NO STALL! PC moved to %h", $time, PC_Debug, PC_Debug);

        // Cycle 5: Normal Execution resumes
        // PC should now move to 3
        @(posedge clk); #1;
        $display("%4t | %2h |     %2h     | Resume Execution", $time, PC_Debug, uut.Instruction_Bus);

        // Wait for Writeback
        #50;
        if (uut.RF.Registers[1] === 8'h55)
            $display("[PASS] Data Forwarding/Loading: R1 = 0x55");
        else
             $display("[FAIL] Data Loading: R1 = 0x%h", uut.RF.Registers[1]);

        $stop;
    end

endmodule