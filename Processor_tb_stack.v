`timescale 1ns / 1ps

module Processor_TB_stack;

    reg clk;
    reg rst;
    reg Interrupt;
    
    wire [7:0] Result_Debug;
    wire [7:0] PC_Debug;
    
    integer test_num;
    integer passed_tests;
    integer failed_tests;
    
    Processor_Top uut (
        .clk(clk),
        .rst(rst),
        .Interrupt(Interrupt),
        .Result_Debug(Result_Debug),
        .PC_Debug(PC_Debug)
    );
    
    initial clk = 0;
    always #5 clk = ~clk;  

    // --- TASKS ---
    task reset_processor;
        begin
            rst = 1; Interrupt = 0;
            #20; rst = 0; #10;
        end
    endtask
    
    task wait_cycles;
        input integer cycles;
        integer i;
        begin
            for (i = 0; i < cycles; i = i + 1) @(posedge clk);
        end
    endtask
    
    task check_register;
        input [1:0] reg_addr;
        input [7:0] expected_value;
        input [200*8:1] test_name;
        begin
            #1;
            if (uut.RF.Registers[reg_addr] === expected_value) begin
                $display("[PASS] %0s: R%0d = 0x%02h", test_name, reg_addr, uut.RF.Registers[reg_addr]);
                passed_tests = passed_tests + 1;
            end else begin
                $display("[FAIL] %0s: R%0d = 0x%02h (Expected: 0x%02h)", test_name, reg_addr, uut.RF.Registers[reg_addr], expected_value);
                failed_tests = failed_tests + 1;
            end
        end
    endtask
    
    // Check Stack Pointer (R3) specifically
    task check_sp;
        input [7:0] expected_value;
        input [200*8:1] test_name;
        begin
            #1;
            if (uut.RF.Registers[3] === expected_value) begin
                $display("[PASS] %0s: SP (R3) = 0x%02h", test_name, uut.RF.Registers[3]);
                passed_tests = passed_tests + 1;
            end else begin
                $display("time: %0t, [FAIL] %0s: SP (R3) = 0x%02h (Expected: 0x%02h)", $time, test_name, uut.RF.Registers[3], expected_value);
                failed_tests = failed_tests + 1;
            end
        end
    endtask

    task check_memory;
        input [7:0] mem_addr;
        input [7:0] expected_value;
        input [200*8:1] test_name;
        begin
            #1;
            if (uut.RAM.mem[mem_addr] === expected_value) begin
                $display("[PASS] %0s: MEM[0x%02h] = 0x%02h", test_name, mem_addr, uut.RAM.mem[mem_addr]);
                passed_tests = passed_tests + 1;
            end else begin
                $display("[FAIL] %0s: MEM[0x%02h] = 0x%02h (Expected: 0x%02h)", test_name, mem_addr, uut.RAM.mem[mem_addr], expected_value);
                failed_tests = failed_tests + 1;
            end
        end
    endtask

    task clear_instruction_memory;
        integer i;
        begin
            for (i = 0; i < 256; i = i + 1) uut.IM.mem[i] = 8'h00;
        end
    endtask

    // --- MAIN TEST ---
    initial begin
        test_num = 1; passed_tests = 0; failed_tests = 0;
        $display("===================================================");
        $display("       STACK OPERATION TESTBENCH (PUSH/POP)        ");
        $display("===================================================");

        // =========================================================
        // TEST 1: PUSH R0
        // =========================================================
        // 1. LDM R0, 0xAA (Load data to push)
        // 2. PUSH R0      (Store 0xAA to M[SP], then Dec SP)
        // =========================================================
        clear_instruction_memory();
        
        // C0 AA -> LDM R0, 0xAA
        uut.IM.mem[0] = 8'hC0; uut.IM.mem[1] = 8'hAA; 
        
        // PADDING (NOPs)
        uut.IM.mem[2] = 8'h00; uut.IM.mem[3] = 8'h00; 
        uut.IM.mem[4] = 8'h00; uut.IM.mem[5] = 8'h00;

        // 70 -> PUSH R0 (Op=7, ra=0[Push], rb=0[R0])
        uut.IM.mem[6] = 8'h70; 

        reset_processor();
        
        // Wait for execution
        wait_cycles(20);
        
        $display("\nTEST 1: PUSH R0 (0xAA)");
        // SP starts at FF. PUSH writes to FF, then becomes FE.
        check_sp(8'hFE, "SP Decremented");
        check_memory(8'hFF, 8'hAA, "Memory[0xFF] holds pushed value");


        // =========================================================
        // TEST 2: POP R1
        // =========================================================
        // 1. (Assume Stack has 0xAA at 0xFF from previous test)
        // 2. POP R1 (Inc SP to FF, Read M[FF] into R1)
        // =========================================================
        clear_instruction_memory();
        
        // Pre-condition: Set Memory and SP manually for independent test
        uut.RAM.mem[8'hFF] = 8'hBB; // Data on stack
        $display("1: %0t", $time);
        
        // 75 -> POP R1 (Op=7, ra=1[Pop], rb=1[R1])
        uut.IM.mem[0] = 8'h75;
        $display("2: %0t", $time);
        // Reset Processor (SP resets to FF)
        reset_processor();
        // Force SP to FE (as if we pushed something previously)
        // We do this by injecting an instruction? No, let's just force the register for this specific test
        // Or better: Run a PUSH then a POP in one sequence.
        
        // Let's do a sequence:
        // LDM R0, 0xCC -> PUSH R0 -> POP R1
        // Result should be R1 == 0xCC
        uut.IM.mem[0] = 8'hC0;
        uut.PC.PC_Out = 'b0;
        uut.IM.mem[1] = 8'hCC; // LDM R0, CC
        $display("3: %0t", $time);
        uut.IM.mem[6] = 8'h70; // PUSH R0
        $display("4: %0t", $time);
        uut.IM.mem[10] = 8'h75; // POP R1
        $display("5: %0t", $time);

        wait_cycles(30);
        
        $display("\nTEST 2: PUSH R0 (0xCC) -> POP R1");
        check_register(1, 8'hCC, "R1 popped correct value");
        check_sp(8'hFF, "SP returned to initial (0xFF)");
        $display("6: %0t", $time);


        // =========================================================
        // TEST 3: CALL (Simulated)
        // =========================================================
        // Verifies that CALL pushes the PC+1 to the stack.
        // We won't check if it Jumps (since that's Phase 2), 
        // but we CHECK if the return address is saved to memory.
        // =========================================================
        clear_instruction_memory();
        
        // CALL R0 (Op=11/0xB, ra=1, rb=0) -> Hex B4
        // PC is at 0. PC+1 is 1. 
        // If CALL is at address 0x05, saved PC should be 0x06.
        
        // 00: NOP
        // 01: NOP
        // 02: NOP
        // 03: NOP
        // 04: NOP
        // 05: CALL R0 (Hex B4)
        
        uut.IM.mem[5] = 8'hB4; 
        
        reset_processor();
        wait_cycles(20);
        
        $display("\nTEST 3: CALL Instruction (Stack verification)");
        // CALL at 0x05. Return Address is 0x06.
        // SP starts FF. Pushes 0x06 to M[FF]. SP becomes FE.
        check_memory(8'hFF, 8'h06, "Return Address Pushed to Stack");
        check_sp(8'hFE, "SP Decremented after CALL");

        $display("\n===================================================");
        $display("Passed: %d, Failed: %d", passed_tests, failed_tests);
        $stop;
    end
endmodule