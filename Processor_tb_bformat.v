`timescale 1ns / 1ns

module Processor_TB_BFormat;

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
        integer i;
        begin
            for (i = 0; i < cycles; i = i + 1) begin
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
    
    task check_pc;
        input [7:0] expected_pc;
        input [200*8:1] test_name;
        begin
            #1;
            if (PC_Debug === expected_pc) begin
                $display("[PASS] %0s: PC = 0x%02h", test_name, PC_Debug);
                passed_tests = passed_tests + 1;
            end else begin
                $display("[FAIL] %0s: PC = 0x%02h (Expected: 0x%02h)", 
                         test_name, PC_Debug, expected_pc);
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
            $display("\n========================================");
            $display("TEST %0d: %0s", test_num, test_name);
            $display("========================================");
            test_num = test_num + 1;
        end
    endtask
    
    task display_registers;
        begin
            $display("\n--- Register File State ---");
            $display("R0 = 0x%02h | R1 = 0x%02h | R2 = 0x%02h | R3 = 0x%02h", 
                     uut.RF.Registers[0], uut.RF.Registers[1],
                     uut.RF.Registers[2], uut.RF.Registers[3]);
            $display("PC = 0x%02h", PC_Debug);
            $display("Flags: V=%b C=%b N=%b Z=%b", 
                     uut.Flags_Reg.ccr_regs[3], uut.Flags_Reg.ccr_regs[2],
                     uut.Flags_Reg.ccr_regs[1], uut.Flags_Reg.ccr_regs[0]);
        end
    endtask
    
    task clear_instruction_memory;
        integer i;
        begin
            // Clear instruction memory (addresses 0-127)
            for (i = 0; i < 128; i = i + 1) begin
                uut.UnifiedMem.mem[i] = 8'h00;
            end
            // Set reset vector at M[0] to point to address 1
            uut.UnifiedMem.mem[0] = 8'h01;
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
        $display("           B-FORMAT BRANCH INSTRUCTIONS - VON NEUMANN TESTBENCH");
        $display("================================================================================");
        $display("Testing JZ, JN, JC, JV, LOOP, JMP, CALL, RET, RTI");
        $display("Clock Period: 10ns | Simulation Start Time: %0t", $time);
        $display("Von Neumann: Unified memory with instruction offset by 1");
        $display("================================================================================\n");
   
        // =====================================================================
        //              TEST 1: JMP (Unconditional Jump)
        // =====================================================================
        display_test_header("JMP: Unconditional Jump");
        clear_instruction_memory();
        
        // LDM R0, 0x11 (target address - offset by 1)
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h11;
        
        // JMP R0 (Opcode=11, brx=0, rb=0) -> 0xB0
        uut.UnifiedMem.mem[3] = 8'hB0;
        
        // These should be skipped
        uut.UnifiedMem.mem[4] = 8'hC1; uut.UnifiedMem.mem[5] = 8'hAA;
        
        // Target at 0x11 (was 0x10 + 1)
        uut.UnifiedMem.mem[17] = 8'hC1; uut.UnifiedMem.mem[18] = 8'hBB; // LDM R1, 0xBB
        
        reset_processor();
        wait_cycles(30);
        
        check_register(1, 8'hBB, "JMP: Jumped to 0x11 and executed");
        display_registers();
        
        // =====================================================================
        //              TEST 2: JZ (Jump if Zero) - Taken
        // =====================================================================
        display_test_header("JZ: Jump if Zero - TAKEN");
        clear_instruction_memory();
        
        // LDM R0, 0x05
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h05;
        
        // SUB R0, R0 -> Z=1
        uut.UnifiedMem.mem[3] = 8'h30;
        
        // LDM R1, 0x21 (target address - offset by 1)
        uut.UnifiedMem.mem[4] = 8'hC1; uut.UnifiedMem.mem[5] = 8'h21;
        
        // JZ R1 (Opcode=9, brx=0, rb=1) -> 0x91
        uut.UnifiedMem.mem[6] = 8'h91;
        
        // Should be skipped
        uut.UnifiedMem.mem[7] = 8'hC2; uut.UnifiedMem.mem[8] = 8'hAA;
        
        // Target at 0x21 (was 0x20 + 1)
        uut.UnifiedMem.mem[33] = 8'hC2; uut.UnifiedMem.mem[34] = 8'hCC; // LDM R2, 0xCC
        
        reset_processor();
        wait_cycles(40);
        
        check_register(2, 8'hCC, "JZ Taken: Jumped to 0x21");
        display_registers();
        
        // =====================================================================
        //              TEST 3: JZ (Jump if Zero) - NOT Taken
        // =====================================================================
        display_test_header("JZ: Jump if Zero - NOT TAKEN");
        clear_instruction_memory();
        
        // LDM R0, 0x05
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h05;
        
        // (Z=0, no operation sets Z)
        
        // LDM R1, 0x21 (target address - won't jump)
        uut.UnifiedMem.mem[3] = 8'hC1; uut.UnifiedMem.mem[4] = 8'h21;
        
        // JZ R1 (Z=0, should NOT jump)
        uut.UnifiedMem.mem[5] = 8'h91;
        
        // Should execute this
        uut.UnifiedMem.mem[6] = 8'hC2; uut.UnifiedMem.mem[7] = 8'hDD; // LDM R2, 0xDD
        
        reset_processor();
        wait_cycles(35);
        
        check_register(2, 8'hDD, "JZ Not Taken: Continued execution");
        display_registers();
       
        // =====================================================================
        //              TEST 4: JN (Jump if Negative) - Taken
        // =====================================================================
        display_test_header("JN: Jump if Negative - TAKEN");
        clear_instruction_memory();
        
        // LDM R0, 0x10
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h10;
        
        // LDM R1, 0x20
        uut.UnifiedMem.mem[3] = 8'hC1; uut.UnifiedMem.mem[4] = 8'h20;
        
        // SUB R0, R1 -> N=1 (negative result)
        uut.UnifiedMem.mem[11] = 8'h31;
        
        // LDM R2, 0x31 (target address - offset by 1)
        uut.UnifiedMem.mem[12] = 8'hC2; uut.UnifiedMem.mem[13] = 8'h31;
        
        // JN R2 (Opcode=9, brx=1, rb=2) -> 0x96
        uut.UnifiedMem.mem[14] = 8'h96;
        
        // Should be skipped
        uut.UnifiedMem.mem[15] = 8'hC0; uut.UnifiedMem.mem[16] = 8'hAA;
        
        // Target at 0x31 (was 0x30 + 1)
        uut.UnifiedMem.mem[49] = 8'hC0; uut.UnifiedMem.mem[50] = 8'hEE; // LDM R0, 0xEE
        
        reset_processor();
        wait_cycles(60);
        
        check_register(0, 8'hEE, "JN Taken: Jumped to 0x31");
        display_registers();

        // =====================================================================
        //              TEST 5: JC (Jump if Carry) - Taken
        // =====================================================================
        display_test_header("JC: Jump if Carry - TAKEN");
        clear_instruction_memory();
        
        // LDM R0, 0xFF
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'hFF;
        
        // LDM R1, 0x01
        uut.UnifiedMem.mem[3] = 8'hC1; uut.UnifiedMem.mem[4] = 8'h01;
        
        // ADD R0, R1 -> C=1 (overflow)
        uut.UnifiedMem.mem[11] = 8'h21;
        
        // LDM R2, 0x41 (target address - offset by 1)
        uut.UnifiedMem.mem[12] = 8'hC2; uut.UnifiedMem.mem[13] = 8'h41;
        
        // JC R2 (Opcode=9, brx=2, rb=2) -> 0x9A
        uut.UnifiedMem.mem[14] = 8'h9A;
        
        // Target at 0x41 (was 0x40 + 1)
        uut.UnifiedMem.mem[65] = 8'hC1; uut.UnifiedMem.mem[66] = 8'hFF; // LDM R1, 0xFF
        
        reset_processor();
        wait_cycles(60);
        
        check_register(1, 8'hFF, "JC Taken: Jumped to 0x41");
        display_registers();
  
        // =====================================================================
        //              TEST 6: JV (Jump if Overflow) - Taken
        // =====================================================================
        display_test_header("JV: Jump if Overflow - TAKEN");
        clear_instruction_memory();
        
        // LDM R0, 0x7F (127)
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h7F;
        
        // LDM R1, 0x01
        uut.UnifiedMem.mem[3] = 8'hC1; uut.UnifiedMem.mem[4] = 8'h01;
        
        // ADD R0, R1 -> V=1 (signed overflow)
        uut.UnifiedMem.mem[11] = 8'h21;
        
        // LDM R2, 0x51 (target address - offset by 1)
        uut.UnifiedMem.mem[12] = 8'hC2; uut.UnifiedMem.mem[13] = 8'h51;
        
        // JV R2 (Opcode=9, brx=3, rb=2) -> 0x9E
        uut.UnifiedMem.mem[14] = 8'h9E;
        
        // Target at 0x51 (was 0x50 + 1)
        uut.UnifiedMem.mem[81] = 8'hC1; uut.UnifiedMem.mem[82] = 8'hAB; // LDM R1, 0xAB
        
        reset_processor();
        wait_cycles(50);
        
        check_register(1, 8'hAB, "JV Taken: Jumped to 0x51");
        display_registers();
       
        // =====================================================================
        //              TEST 7: LOOP Instruction - Multiple Iterations
        // =====================================================================
        display_test_header("LOOP: Decrement and Branch");
        clear_instruction_memory();
        
        // LDM R0, 0x03 (loop counter)
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h03;
        
        // LDM R1, 0x12 (loop body address - offset by 1)
        uut.UnifiedMem.mem[3] = 8'hC1; uut.UnifiedMem.mem[4] = 8'h11;
    
        // LOOP R0, R1 (Opcode=10, ra=0, rb=1) -> 0xA1
        uut.UnifiedMem.mem[8] = 8'hA1;
        
        // After loop exits
        uut.UnifiedMem.mem[14] = 8'hC2; uut.UnifiedMem.mem[15] = 8'hEE; // LDM R2, 0xEE
        
        // Loop body at 0x12 (was 0x11 + 1)
        uut.UnifiedMem.mem[17] = 8'h00; // INC R2
        uut.UnifiedMem.mem[18] = 8'hC2; uut.UnifiedMem.mem[19] = 8'h08; // LDM R1, 0x09 (back to LOOP)
        uut.UnifiedMem.mem[24] = 8'hB2; // JMP R1
        
        reset_processor();
        wait_cycles(80);
        
        check_register(0, 8'h00, "LOOP: Counter decremented to 0");
        // check_register(2, 8'hEE, "LOOP: Exited and continued");
        display_registers();
         
        
        // =====================================================================
        //              TEST 8: CALL and RET
        // =====================================================================
        display_test_header("CALL and RET: Subroutine Call");
        clear_instruction_memory();
        
        // Main program
        // LDM R0, 0x21 (subroutine address - offset by 1)
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h21;
        
        // LDM R1, 0x11 (initial value)
        uut.UnifiedMem.mem[3] = 8'hC1; uut.UnifiedMem.mem[4] = 8'h11;
        
        // CALL R0 (Opcode=11, brx=1, rb=0) -> 0xB4
        uut.UnifiedMem.mem[5] = 8'hB4;
        
        // Return here - check R1 was modified
        uut.UnifiedMem.mem[11] = 8'hC2; uut.UnifiedMem.mem[12] = 8'hFF; // LDM R2, 0xFF
        
        // Subroutine at 0x21 (was 0x20 + 1)
        uut.UnifiedMem.mem[33] = 8'h89; // INC R1
        uut.UnifiedMem.mem[34] = 8'hB8; // RET (Opcode=11, brx=2, rb=0) -> 0xB8
        
        reset_processor();
        wait_cycles(25);
        
        check_register(1, 8'h12, "CALL/RET: Subroutine modified R1");
        check_register(2, 8'hFF, "CALL/RET: Returned to main");
        display_registers();

        // =====================================================================
        //              TEST 9: Nested CALL
        // =====================================================================
        display_test_header("Nested CALL: Multiple subroutine levels");
        clear_instruction_memory();
        
        // Main
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h11; // LDM R0, 0x11
        uut.UnifiedMem.mem[3] = 8'hC1; uut.UnifiedMem.mem[4] = 8'h00; // LDM R1, 0x00
        uut.UnifiedMem.mem[5] = 8'hB4; // CALL R0
        uut.UnifiedMem.mem[6] = 8'h00; // NOP (check R1 final value)
        
        // Subroutine 1 at 0x11 (was 0x10 + 1)
        uut.UnifiedMem.mem[17] = 8'h89; // INC R1
        uut.UnifiedMem.mem[18] = 8'hC0; uut.UnifiedMem.mem[19] = 8'h31; // LDM R0, 0x31
        uut.UnifiedMem.mem[22] = 8'hB4; // CALL R0 (nested call)
        uut.UnifiedMem.mem[26] = 8'hB8; // RET
        
        // Subroutine 2 at 0x31 (was 0x30 + 1)
        uut.UnifiedMem.mem[49] = 8'h89; // INC R1
        uut.UnifiedMem.mem[52] = 8'hB8; // RET
        
        reset_processor();
        wait_cycles(30);
        
        check_register(1, 8'h02, "Nested CALL: R1 incremented twice");
        display_registers();
        
        // =====================================================================
        //              TEST 10: Conditional Branch Chain
        // =====================================================================
        display_test_header("Conditional Branch Chain");
        clear_instruction_memory();
        
        // Set up multiple conditions and branch
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h00; // LDM R0, 0x00
        uut.UnifiedMem.mem[3] = 8'h30; // SUB R0, R0 -> Z=1
        uut.UnifiedMem.mem[4] = 8'hC1; uut.UnifiedMem.mem[5] = 8'h11; // LDM R1, 0x11
        uut.UnifiedMem.mem[6] = 8'h91; // JZ R1 (should jump)
        
        // Skipped
        uut.UnifiedMem.mem[7] = 8'hC2; uut.UnifiedMem.mem[8] = 8'hAA;
        
        // At 0x11 (was 0x10 + 1)
        uut.UnifiedMem.mem[17] = 8'hC2; uut.UnifiedMem.mem[18] = 8'hBB; // LDM R2, 0xBB
        
        reset_processor();
        wait_cycles(40);
        
        check_register(2, 8'hBB, "Branch Chain: Correct path taken");
        display_registers();

        // =====================================================================
        //                         FINAL SUMMARY
        // =====================================================================
        $display("\n");
        $display("================================================================================");
        $display("                    B-FORMAT TEST SUMMARY");
        $display("================================================================================");
        $display("Total Tests Run:    %0d", passed_tests + failed_tests);
        $display("Tests Passed:       %0d", passed_tests);
        $display("Tests Failed:       %0d", failed_tests);
        if (passed_tests + failed_tests > 0)
            $display("Pass Rate:          %0.1f%%", (passed_tests * 100.0) / (passed_tests + failed_tests));
        $display("================================================================================");
        
        if (failed_tests == 0) begin
            $display("\n*** ALL B-FORMAT TESTS PASSED! ***");
            $display("*** Branch and control flow instructions working correctly ***\n");
        end else begin
            $display("\n*** SOME TESTS FAILED - Review branch logic ***\n");
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
        $dumpfile("processor_bformat_vonneumann.vcd");
        $dumpvars(0, Processor_TB_BFormat);
    end

endmodule