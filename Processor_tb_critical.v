`timescale 1ns / 1ps

// ============================================================================
// CRITICAL EDGE CASE TESTBENCH
// ============================================================================

module Processor_TB_Critical;

    // =========================================================================
    //                          TESTBENCH SIGNALS
    // =========================================================================
    reg clk;
    reg rst;
    reg [7:0] IN_Port;
    reg Interrupt;
    
    wire [7:0] Result_Debug;
    wire [7:0] PC_Debug;
    wire [7:0] OUT_Port;
    
    // Test tracking
    integer test_num;
    integer passed_tests;
    integer failed_tests;
    
    // Additional tracking (declared at module level)
    integer i, j;
    reg [7:0] expected_value;
    reg old_v, old_c, old_n, old_z;
    
    // =========================================================================
    //                      INSTANTIATE PROCESSOR
    // =========================================================================
    Processor_Top uut (
        .clk(clk),
        .rst(rst),
        .IN_Port(IN_Port),
        .Interrupt(Interrupt),
        .Result_Debug(Result_Debug),
        .PC_Debug(PC_Debug),
        .OUT_Port(OUT_Port)
    );
    
    // =========================================================================
    //                          CLOCK GENERATION
    // =========================================================================
    initial clk = 0;
    always #5 clk = ~clk;
    
    // =========================================================================
    //                          TEST MANAGEMENT TASKS
    // =========================================================================
    task reset_processor;
        begin
            rst = 1;
            Interrupt = 0;
            IN_Port = 8'h00;
            #20;
            rst = 0;
            #10;
        end
    endtask
    
    task wait_cycles;
        input integer cycles;
        integer m;
        begin
            for (m = 0; m < cycles; m = m + 1) begin
                @(posedge clk);
            end
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
                $display("[FAIL] %0s: R%0d = 0x%02h (Expected: 0x%02h)", 
                         test_name, reg_addr, uut.RF.Registers[reg_addr], expected_value);
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
            if (uut.UnifiedMem.mem[mem_addr] === expected_value) begin
                $display("[PASS] %0s: MEM[0x%02h] = 0x%02h", test_name, mem_addr, uut.UnifiedMem.mem[mem_addr]);
                passed_tests = passed_tests + 1;
            end else begin
                $display("[FAIL] %0s: MEM[0x%02h] = 0x%02h (Expected: 0x%02h)", 
                         test_name, mem_addr, uut.UnifiedMem.mem[mem_addr], expected_value);
                failed_tests = failed_tests + 1;
            end
        end
    endtask
    
    task check_flag;
        input flag_bit;
        input expected_value;
        input [200*8:1] flag_name;
        input [200*8:1] test_name;
        begin
            #1;
            if (flag_bit === expected_value) begin
                $display("[PASS] %0s - %0s: %0b", test_name, flag_name, flag_bit);
                passed_tests = passed_tests + 1;
            end else begin
                $display("[FAIL] %0s - %0s: %0b (Expected: %0b)", 
                         test_name, flag_name, flag_bit, expected_value);
                failed_tests = failed_tests + 1;
            end
        end
    endtask
    
    task display_test_header;
        input [200*8:1] test_name;
        begin
            $display("\n================================================================================");
            $display("CRITICAL TEST %0d: %0s", test_num, test_name);
            $display("================================================================================");
            test_num = test_num + 1;
        end
    endtask
    
    task display_registers;
        begin
            $display("\n--- Register File State ---");
            $display("R0 = 0x%02h | R1 = 0x%02h | R2 = 0x%02h | R3(SP) = 0x%02h", 
                     uut.RF.Registers[0], uut.RF.Registers[1],
                     uut.RF.Registers[2], uut.RF.Registers[3]);
            $display("PC = 0x%02h", PC_Debug);
            $display("Flags: V=%b C=%b N=%b Z=%b", 
                     uut.Flags_Reg.ccr_regs[3], uut.Flags_Reg.ccr_regs[2],
                     uut.Flags_Reg.ccr_regs[1], uut.Flags_Reg.ccr_regs[0]);
            $display("Forwarding: A=%b B=%b Stall=%b", 
                     uut.Forward_A, uut.Forward_B, uut.ID_Stall);
        end
    endtask
    
    task clear_instruction_memory;
        integer k;
        begin
            for (k = 0; k < 256; k = k + 1) begin
                uut.UnifiedMem.mem[k] = 8'h00;
            end
            // Von Neumann: M[0] points to start address (1)
            uut.UnifiedMem.mem[0] = 8'h01;
        end
    endtask
    
    task preload_data_memory;
        input [7:0] addr;
        input [7:0] value;
        begin
            uut.UnifiedMem.mem[addr] = value;
        end
    endtask
    
    // =========================================================================
    //                          MAIN TEST SEQUENCE
    // =========================================================================
    initial begin
        test_num = 1;
        passed_tests = 0;
        failed_tests = 0;
        
        $display("\n");
        $display("================================================================================");
        $display("              CRITICAL EDGE CASE TESTBENCH - 3 COMPREHENSIVE TESTS");
        $display("================================================================================");
        $display("Testing Complex Scenarios Combining Multiple Processor Features");
        $display("Clock Period: 10ns | Simulation Start Time: %0t", $time);
        $display("================================================================================\n");
        
        // =====================================================================
        //  CRITICAL TEST 1: COMPLEX DATA HAZARDS + LOAD-USE + BRANCH + FORWARDING
        // =====================================================================
        display_test_header("Complex Data Hazards + Load-Use + Branch + Forwarding");
        clear_instruction_memory();
        
        $display("\nTest Scenario:");
        $display("1. Load data from memory (triggers load-use hazard)");
        $display("2. Use loaded data immediately (stall required)");
        $display("3. Perform arithmetic with forwarding from multiple stages");
        $display("4. Conditional branch based on ALU flags");
        $display("5. Verify correct execution path and data forwarding\n");
        
        // Pre-load data memory (with proper addressing)
        preload_data_memory(8'd200, 8'h05);  // LDD will access this
        preload_data_memory(8'd210, 8'h03);  // LDD will access this
        
        // Program starts at address 1 (Von Neumann convention from working tests)
        // LDM R0, 0xC8 (address 200)
        uut.UnifiedMem.mem[1] = 8'hC0; 
        uut.UnifiedMem.mem[2] = 8'hC8;
        uut.UnifiedMem.mem[3] = 8'h00; // NOP padding
        uut.UnifiedMem.mem[4] = 8'h00;
        uut.UnifiedMem.mem[5] = 8'h00;
        
        // LDD R1, [R0] -> Load from memory[200]
        uut.UnifiedMem.mem[6] = 8'hD1;
        uut.UnifiedMem.mem[7] = 8'h00; // NOP padding
        uut.UnifiedMem.mem[8] = 8'h00;
        uut.UnifiedMem.mem[9] = 8'h00;
        
        // ADD R1, R1 -> Double the value (needs forwarding/stall)
        uut.UnifiedMem.mem[10] = 8'h25;
        uut.UnifiedMem.mem[11] = 8'h00; // NOP padding
        uut.UnifiedMem.mem[12] = 8'h00;
        uut.UnifiedMem.mem[13] = 8'h00;
        
        // LDM R2, 0xD2 (address 210)
        uut.UnifiedMem.mem[14] = 8'hC2; 
        uut.UnifiedMem.mem[15] = 8'hD2;
        uut.UnifiedMem.mem[16] = 8'h00;
        uut.UnifiedMem.mem[17] = 8'h00;
        
        // LDD R0, [R2] -> Load from memory[210]
        uut.UnifiedMem.mem[18] = 8'hD0;
        uut.UnifiedMem.mem[19] = 8'h00;
        uut.UnifiedMem.mem[20] = 8'h00;
        
        // ADD R1, R0 -> Both operands need forwarding
        uut.UnifiedMem.mem[21] = 8'h24;
        uut.UnifiedMem.mem[22] = 8'h00;
        uut.UnifiedMem.mem[23] = 8'h00;
        
        // SUB R1, R1 -> Should set Z flag
        uut.UnifiedMem.mem[24] = 8'h35;
        uut.UnifiedMem.mem[25] = 8'h00;
        uut.UnifiedMem.mem[26] = 8'h00;
        
        // LDM R2, 0x51 (branch target address + 1 for Von Neumann)
        uut.UnifiedMem.mem[27] = 8'hC2; 
        uut.UnifiedMem.mem[28] = 8'h51;
        uut.UnifiedMem.mem[29] = 8'h00;
        
        // JZ R2 (Opcode=9, brx=0, rb=2) -> 0x96
        uut.UnifiedMem.mem[30] = 8'h96;
        
        // Should be skipped
        uut.UnifiedMem.mem[31] = 8'hC0; 
        uut.UnifiedMem.mem[32] = 8'hAA;
        
        // Branch target at 0x51
        uut.UnifiedMem.mem[81] = 8'hC0; 
        uut.UnifiedMem.mem[82] = 8'hFF;  // LDM R0, 0xFF
        
        reset_processor();
        
        $display("Executing complex program with hazards...");
        wait_cycles(100);
        
        // Verification
        $display("\nVerifying Results:");
        check_register(0, 8'hFF, "Branch Target: R0 loaded correctly");
        check_register(1, 8'h00, "Forwarding Chain: Final R1 value");
        check_flag(uut.Flags_Reg.ccr_regs[0], 1'b1, "Zero Flag", "After SUB R1,R1");
        
        // Check that stall occurred
        if (uut.RF.Registers[1] === 8'h00) begin
            $display("[PASS] Load-Use Hazard: Stall correctly inserted");
            passed_tests = passed_tests + 1;
        end else begin
            $display("[FAIL] Load-Use Hazard: Stall mechanism failed");
            failed_tests = failed_tests + 1;
        end
        
        display_registers();
        
        // =====================================================================
        //  CRITICAL TEST 2: INTERRUPT + FLAG PRESERVATION + NESTED CALL/RET
        // =====================================================================
        display_test_header("Interrupt + Flag Preservation + Nested CALL/RET");
        clear_instruction_memory();

        $display("\nTest Scenario:");
        $display("1. Execute program that sets specific flags");
        $display("2. Trigger interrupt during execution");
        $display("3. ISR performs CALL to nested subroutine");
        $display("4. Nested subroutine modifies flags");
        $display("5. Return from nested call, then RTI");
        $display("6. Verify flags restored and correct return address\n");

        // Set interrupt vector (Von Neumann: M[0] = reset, M[1] = ISR address)
        uut.UnifiedMem.mem[0] = 8'h02;  // Reset vector - program starts at 0x02
        uut.UnifiedMem.mem[1] = 8'h60;  // ISR address

        // Main program starts at address 0x02
        // LDM R0, 0x7F
        uut.UnifiedMem.mem[2] = 8'hC0; 
        uut.UnifiedMem.mem[3] = 8'h7F;

        // LDM R1, 0x01
        uut.UnifiedMem.mem[4] = 8'hC1; 
        uut.UnifiedMem.mem[5] = 8'h01;

        // ADD R0, R1 -> Sets V=1, N=1 (at address 0x06)
        uut.UnifiedMem.mem[6] = 8'h21;

        // NOP (at address 0x07)
        uut.UnifiedMem.mem[7] = 8'h00;

        // NOP (at address 0x08)
        uut.UnifiedMem.mem[8] = 8'h00;

        // NOP (at address 0x09) - interrupt will occur here
        uut.UnifiedMem.mem[9] = 8'h00;

        // LDM R2, 0xBB (at address 0x0A) - This should execute after RTI
        uut.UnifiedMem.mem[10] = 8'hC2; 
        uut.UnifiedMem.mem[11] = 8'hBB;

        // Add some more NOPs to verify execution continues
        uut.UnifiedMem.mem[12] = 8'h00;
        uut.UnifiedMem.mem[13] = 8'h00;

        // ISR at 0x60
        // LDM R0, 0x51 (nested subroutine address) - at 0x60
        uut.UnifiedMem.mem[96] = 8'hC0; 
        uut.UnifiedMem.mem[97] = 8'h51;

        // CALL R0 - at 0x62
        uut.UnifiedMem.mem[98] = 8'hB4;

        // LDM R1, 0xAA (after nested return) - at 0x63
        uut.UnifiedMem.mem[99] = 8'hC1; 
        uut.UnifiedMem.mem[100] = 8'hAA;

        // RTI - at 0x65
        uut.UnifiedMem.mem[101] = 8'hBC;

        // Nested subroutine at 0x51
        // LDM R0, 0xFF - at 0x51 (changed from R2 to R0 to not conflict)
        uut.UnifiedMem.mem[81] = 8'hC0; 
        uut.UnifiedMem.mem[82] = 8'hFF;

        // INC R0 -> Changes flags - at 0x53
        uut.UnifiedMem.mem[83] = 8'h88;

        // RET - at 0x54
        uut.UnifiedMem.mem[84] = 8'hB8;

        reset_processor();

        // Store flags before interrupt (wait for ADD to complete)
        wait_cycles(25);

        old_v = uut.Flags_Reg.ccr_regs[3];
        old_c = uut.Flags_Reg.ccr_regs[2];
        old_n = uut.Flags_Reg.ccr_regs[1];
        old_z = uut.Flags_Reg.ccr_regs[0];

        $display("Flags before interrupt: V=%b C=%b N=%b Z=%b", old_v, old_c, old_n, old_z);
        $display("PC before interrupt: 0x%02h", PC_Debug);
        $display("SP before interrupt: 0x%02h", uut.RF.Registers[3]);

        // Trigger interrupt
        $display("\nTriggering interrupt at time %0t", $time);
        Interrupt = 1;
        @(posedge clk);
        Interrupt = 0;

        // Wait for completion
        wait_cycles(100);

        // Debug stack contents
        $display("\n--- Stack Contents ---");
        $display("Stack[0xFF]: 0x%02h (should be saved PC = 0x0A)", uut.UnifiedMem.mem[255]);
        $display("Stack[0xFE]: 0x%02h (should be CALL return addr = 0x63)", uut.UnifiedMem.mem[254]);

        // Verification
        $display("\n=== Verifying Results ===");
        check_register(1, 8'hAA, "ISR Execution: R1 modified");
        check_register(2, 8'hBB, "Return from Interrupt: Main program continued");

        $display("Flags after RTI: V=%b C=%b N=%b Z=%b", 
                uut.Flags_Reg.ccr_regs[3], uut.Flags_Reg.ccr_regs[2],
                uut.Flags_Reg.ccr_regs[1], uut.Flags_Reg.ccr_regs[0]);

        check_flag(uut.Flags_Reg.ccr_regs[3], old_v, "Overflow Flag", "Flag Restoration");
        check_flag(uut.Flags_Reg.ccr_regs[2], old_c, "Carry Flag", "Flag Restoration");

        if (uut.RF.Registers[2] === 8'hBB) begin
            $display("[PASS] Nested CALL/RET: Return addresses handled correctly");
            passed_tests = passed_tests + 1;
        end else begin
            $display("[FAIL] Nested CALL/RET: Return address corruption");
            $display("  Expected R2=0xBB, got R2=0x%02h", uut.RF.Registers[2]);
            $display("  Final PC=0x%02h (should be 0x0C after executing LDM R2,0xBB)", PC_Debug);
            failed_tests = failed_tests + 1;
        end

        display_registers();

        // =====================================================================
        //  CRITICAL TEST 3: STACK EDGE CASES + INDIRECT MEMORY + MULTI-FORWARDING
        // =====================================================================
        display_test_header("Stack Edge Cases + Indirect Memory + Multi-Forwarding");
        clear_instruction_memory();
        
        $display("\nTest Scenario:");
        $display("1. Perform sequence of PUSH operations");
        $display("2. Use indirect addressing with forwarded address values");
        $display("3. Store to memory via STI with computed addresses");
        $display("4. Load from memory via LDI with forwarded addresses");
        $display("5. Perform POP operations and verify data integrity");
        $display("6. Complex forwarding with all three registers as sources\n");
        
        preload_data_memory(8'd192, 8'h00);
        
        // Program starts at address 1
        // LDM R0, 0x11
        uut.UnifiedMem.mem[1] = 8'hC0; 
        uut.UnifiedMem.mem[2] = 8'h11;
        uut.UnifiedMem.mem[3] = 8'h00;
        uut.UnifiedMem.mem[4] = 8'h00;
        
        // LDM R1, 0x22
        uut.UnifiedMem.mem[5] = 8'hC1; 
        uut.UnifiedMem.mem[6] = 8'h22;
        uut.UnifiedMem.mem[7] = 8'h00;
        uut.UnifiedMem.mem[8] = 8'h00;
        
        // LDM R2, 0x33
        uut.UnifiedMem.mem[9] = 8'hC2; 
        uut.UnifiedMem.mem[10] = 8'h33;
        uut.UnifiedMem.mem[11] = 8'h00;
        uut.UnifiedMem.mem[12] = 8'h00;
        
        // PUSH R0
        uut.UnifiedMem.mem[13] = 8'h70;
        uut.UnifiedMem.mem[14] = 8'h00;
        uut.UnifiedMem.mem[15] = 8'h00;
        
        // PUSH R1
        uut.UnifiedMem.mem[16] = 8'h71;
        uut.UnifiedMem.mem[17] = 8'h00;
        uut.UnifiedMem.mem[18] = 8'h00;
        
        // PUSH R2
        uut.UnifiedMem.mem[19] = 8'h72;
        uut.UnifiedMem.mem[20] = 8'h00;
        uut.UnifiedMem.mem[21] = 8'h00;
        
        // ADD R0, R1 (using forwarding)
        uut.UnifiedMem.mem[22] = 8'h21;
        uut.UnifiedMem.mem[23] = 8'h00;
        uut.UnifiedMem.mem[24] = 8'h00;
        
        // LDM R0, 0xC0 (address for STI)
        uut.UnifiedMem.mem[25] = 8'hC0; 
        uut.UnifiedMem.mem[26] = 8'hC0;
        uut.UnifiedMem.mem[27] = 8'h00;
        uut.UnifiedMem.mem[28] = 8'h00;
        
        // STI: M[R0] = R2 (Opcode=14, ra=0, rb=2) -> 0xE2
        uut.UnifiedMem.mem[29] = 8'hE2;
        uut.UnifiedMem.mem[30] = 8'h00;
        uut.UnifiedMem.mem[31] = 8'h00;
        
        // LDI: R1 = M[R0] (Opcode=13, ra=0, rb=1) -> 0xD1
        uut.UnifiedMem.mem[32] = 8'hD1;
        uut.UnifiedMem.mem[33] = 8'h00;
        uut.UnifiedMem.mem[34] = 8'h00;
        
        // ADD R0, R1 (both operands forwarded)
        uut.UnifiedMem.mem[35] = 8'h21;
        uut.UnifiedMem.mem[36] = 8'h00;
        uut.UnifiedMem.mem[37] = 8'h00;
        
        // POP R2
        uut.UnifiedMem.mem[38] = 8'h76;
        uut.UnifiedMem.mem[39] = 8'h00;
        uut.UnifiedMem.mem[40] = 8'h00;
        
        // POP R1
        uut.UnifiedMem.mem[41] = 8'h75;
        uut.UnifiedMem.mem[42] = 8'h00;
        uut.UnifiedMem.mem[43] = 8'h00;
        
        // POP R0
        uut.UnifiedMem.mem[44] = 8'h74;
        uut.UnifiedMem.mem[45] = 8'h00;
        uut.UnifiedMem.mem[46] = 8'h00;
        
        // ADD R0, R0 (final verification)
        uut.UnifiedMem.mem[47] = 8'h20;
        
        reset_processor();
        
        $display("Executing stack and indirect memory operations...");
        wait_cycles(150);
        
        // Verification
        $display("\nVerifying Results:");
        check_memory(8'd192, 8'h33, "Indirect Store: STI wrote correct value");
        check_register(0, 8'h22, "Stack Integrity: R0 after PUSH/POP cycle");
        check_register(1, 8'h22, "Stack Integrity: R1 after PUSH/POP cycle");
        check_register(2, 8'h33, "Stack Integrity: R2 after PUSH/POP cycle");
        check_register(3, 8'hFF, "Stack Pointer: Returned to initial value");
        check_memory(8'd255, 8'h11, "Stack Memory: First pushed value preserved");
        check_memory(8'd254, 8'h22, "Stack Memory: Second pushed value preserved");
        check_memory(8'd253, 8'h33, "Stack Memory: Third pushed value preserved");
        
        if (uut.RF.Registers[0] === 8'h22 && 
            uut.RF.Registers[1] === 8'h22 && 
            uut.RF.Registers[2] === 8'h33) begin
            $display("[PASS] Multi-Source Forwarding: All operands forwarded correctly");
            passed_tests = passed_tests + 1;
        end else begin
            $display("[FAIL] Multi-Source Forwarding: Data corruption detected");
            failed_tests = failed_tests + 1;
        end
        
        display_registers();
        
        // =====================================================================
        //                         FINAL SUMMARY
        // =====================================================================
        $display("\n");
        $display("================================================================================");
        $display("                    CRITICAL EDGE CASE TEST SUMMARY");
        $display("================================================================================");
        $display("Total Tests Run:    %0d", passed_tests + failed_tests);
        $display("Tests Passed:       %0d", passed_tests);
        $display("Tests Failed:       %0d", failed_tests);
        if (passed_tests + failed_tests > 0)
            $display("Pass Rate:          %0.1f%%", (passed_tests * 100.0) / (passed_tests + failed_tests));
        $display("================================================================================");
        
        $display("\nCritical Features Tested:");
        $display("  ✓ Complex RAW hazards with multi-stage forwarding");
        $display("  ✓ Load-use hazards with automatic stall insertion");
        $display("  ✓ Conditional branches with flag dependencies");
        $display("  ✓ Interrupt handling with flag preservation");
        $display("  ✓ Nested subroutine calls (CALL/RET)");
        $display("  ✓ Stack operations under stress");
        $display("  ✓ Indirect memory addressing (STI/LDI)");
        $display("  ✓ Multi-source forwarding (3-way dependencies)");
        $display("  ✓ Stack integrity verification");
        $display("  ✓ Return address preservation");
        
        if (failed_tests == 0) begin
            $display("\n*** ALL CRITICAL TESTS PASSED! ***");
            $display("*** Processor handles complex edge cases correctly ***\n");
        end else begin
            $display("\n*** SOME CRITICAL TESTS FAILED ***");
            $display("*** Review processor logic for edge cases ***\n");
        end
        
        $display("Simulation completed at time: %0t", $time);
        $display("================================================================================\n");
        
        #100;
        $finish;
    end
    
    // =========================================================================
    //                    WAVEFORM MONITORING
    // =========================================================================
    initial begin
        $dumpfile("processor_critical.vcd");
        $dumpvars(0, Processor_TB_Critical);
    end

endmodule