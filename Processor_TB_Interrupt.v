

`timescale 1ns / 1ps

module Processor_TB_Interrupt;

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
    
    // ALL ADDITIONAL DECLARATIONS AT MODULE LEVEL
    integer i, j, k;
    reg [7:0] sp_before;
    reg old_z, old_c, old_n, old_v;
    
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
        reg [7:0] physical_addr;
        begin
            #1;
            // Map logical address (0-127) to physical address (128-255)
            physical_addr =(mem_addr>128)? mem_addr : mem_addr + 8'd128;
            if (uut.UnifiedMem.mem[physical_addr] === expected_value) begin
                $display("[PASS] %0s: MEM[0x%02h] (Physical:0x%02h) = 0x%02h (Expected: 0x%02h)", 
                         test_name, mem_addr, physical_addr, uut.UnifiedMem.mem[physical_addr], expected_value);
                passed_tests = passed_tests + 1;
            end else begin
                $display("[FAIL] %0s: MEM[0x%02h] (Physical:0x%02h) = 0x%02h (Expected: 0x%02h)", 
                         test_name, mem_addr, physical_addr, uut.UnifiedMem.mem[physical_addr], expected_value);
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
            $display("R0 = 0x%02h | R1 = 0x%02h | R2 = 0x%02h | R3(SP) = 0x%02h", 
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

    task preload_data_memory;
        input [7:0] logical_addr;
        input [7:0] value;
        reg [7:0] physical_addr;
        begin
            // Map logical address (0-127) to physical address (128-255)
            // physical_addr = logical_addr + 8'd128;
            uut.UnifiedMem.mem[logical_addr] = value;
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
        $display("                        INTERRUPT HANDLING TESTBENCH");
        $display("================================================================================");
        $display("Testing interrupt request, ISR execution, and RTI");
        $display("According to ISA: X[SP--]←PC; PC←M[1]; Flags preserved");
        $display("Clock Period: 10ns | Simulation Start Time: %0t", $time);
        $display("================================================================================\n");
       
        // =====================================================================
        //              TEST 1: Basic Interrupt - Save PC and Jump to ISR
        // =====================================================================
        display_test_header("Basic Interrupt: PC Save and ISR Jump");
        clear_instruction_memory();
        
        // Set ISR address at M[1]
        //uut.RAM.mem[1] = 8'h50; // ISR starts at 0x50
        
        // Main program
        uut.UnifiedMem.mem[0] = 8'h02 ;
        uut.UnifiedMem.mem[1] = 8'h50 ;
        uut.UnifiedMem.mem[2] = 8'hC0; uut.UnifiedMem.mem[3] = 8'h11; // LDM R0, 0x11
        uut.UnifiedMem.mem[4] = 8'hC1; uut.UnifiedMem.mem[5] = 8'h22; // LDM R1, 0x22
        uut.UnifiedMem.mem[6] = 8'hC2; uut.UnifiedMem.mem[7] = 8'h33; // LDM R2, 0x33 (will be interrupted)
        uut.UnifiedMem.mem[8] = 8'h00; // NOP (should execute after RTI)
        
        // ISR at 0x50
        uut.UnifiedMem.mem[80] = 8'hC0; uut.UnifiedMem.mem[81] = 8'hAA; // LDM R0, 0xAA (modify R0 in ISR)
        uut.UnifiedMem.mem[82] = 8'hBC; // RTI (Opcode=11, brx=3, rb=0) -> 0xBC
        
        reset_processor();
        
        // Run for a few cycles, then trigger interrupt
        wait_cycles(15);
        
        $display("Triggering interrupt at time %0t", $time);
        Interrupt = 1;
        @(posedge clk);
        Interrupt = 0;
        
        wait_cycles(40);
        
        // Check that PC was saved to stack
        check_memory(8'hFF, 8'h10, "Interrupt: PC saved to stack (should be 0x10)");
        
        // Check that R0 was modified by ISR
        check_register(0, 8'hAA, "Interrupt: ISR executed (R0 modified)");
        
        // Check that R1 still has original value
        check_register(1, 8'h22, "Interrupt: R1 preserved");
        
        display_registers();
        
        // =====================================================================
        //              TEST 2: Flag Preservation During Interrupt
        // =====================================================================
        display_test_header("Interrupt: Flag Preservation");
        clear_instruction_memory();
        
        // Set ISR address
        uut.UnifiedMem.mem[0] = 8'h02 ;
        uut.UnifiedMem.mem[1] = 8'h60 ;

        
        // Main program - set some flags
        uut.UnifiedMem.mem[2] = 8'hC0; uut.UnifiedMem.mem[3] = 8'hFF; // LDM R0, 0xFF
        uut.UnifiedMem.mem[4] = 8'hC1; uut.UnifiedMem.mem[5] = 8'h01; // LDM R1, 0x01
        uut.UnifiedMem.mem[6] = 8'h01; // LDM R1, 0x01
        uut.UnifiedMem.mem[7] = 8'h21; // ADD R0, R1 -> Sets C=1, Z=1
        uut.UnifiedMem.mem[8] = 8'h00; // NOP
        uut.UnifiedMem.mem[9] = 8'h00; // NOP
        
        // ISR at 0x60 - modifies flags
        uut.UnifiedMem.mem[96] = 8'hC2; uut.UnifiedMem.mem[97] = 8'h05; // LDM R2, 0x05
        uut.UnifiedMem.mem[98] = 8'h30; // SUB R0, R0 -> Sets Z=1, clears C
        uut.UnifiedMem.mem[99] = 8'hBC; // RTI
        
        reset_processor();
        wait_cycles(20);
        
        // Store flags before interrupt
        old_z = uut.Flags_Reg.ccr_regs[0];
        old_c = uut.Flags_Reg.ccr_regs[2];
        old_n = uut.Flags_Reg.ccr_regs[1];
        old_v = uut.Flags_Reg.ccr_regs[3];
        
        $display("Flags before interrupt: V=%b C=%b N=%b Z=%b", old_v, old_c, old_n, old_z);
        
        // Trigger interrupt
        Interrupt = 1;
        @(posedge clk);
        Interrupt = 0;
        
        wait_cycles(40);
        
        // Check flags restored after RTI
        $display("Flags after RTI: V=%b C=%b N=%b Z=%b", 
                 uut.Flags_Reg.ccr_regs[3], uut.Flags_Reg.ccr_regs[2],
                 uut.Flags_Reg.ccr_regs[1], uut.Flags_Reg.ccr_regs[0]);
        
        check_flag(uut.Flags_Reg.ccr_regs[0], old_z, "Zero Flag", "Flag Restoration");
        check_flag(uut.Flags_Reg.ccr_regs[2], old_c, "Carry Flag", "Flag Restoration");
        
        display_registers();
        
        // =====================================================================
        //              TEST 3: Nested Interrupts (if supported)
        // =====================================================================
        display_test_header("Nested Interrupts Test");
        clear_instruction_memory();
        
        // Note: Since interrupt is non-maskable, true nesting may not be supported
        // This test checks if system handles multiple interrupt requests properly
        uut.UnifiedMem.mem[0] = 8'h02;
        uut.UnifiedMem.mem[1] = 8'h70; // ISR address
        
        // Main program
        uut.UnifiedMem.mem[2] = 8'hC0; uut.UnifiedMem.mem[3] = 8'h01; // LDM R0, 0x01
        uut.UnifiedMem.mem[4] = 8'h88; // INC R0
        uut.UnifiedMem.mem[5] = 8'h88; // INC R0
        uut.UnifiedMem.mem[6] = 8'h88; // INC R0
        
        // ISR at 0x70
        uut.UnifiedMem.mem[112] = 8'h89; // INC R1
        uut.UnifiedMem.mem[113] = 8'hBC; // RTI
        
        reset_processor();
        wait_cycles(10);
        
        // First interrupt
        Interrupt = 1;
        @(posedge clk);
        Interrupt = 0;
        
        wait_cycles(20);
        
        // Second interrupt (should be handled properly)
        Interrupt = 1;
        @(posedge clk);
        Interrupt = 0;
        
        wait_cycles(30);
        
        check_register(1, 8'h02, "Nested Interrupts: Both ISRs executed");
        display_registers();
        
        // =====================================================================
        //              TEST 4: Interrupt During Multi-Cycle Instruction
        // =====================================================================
        display_test_header("Interrupt During 2-Byte Instruction");
        clear_instruction_memory();
        uut.UnifiedMem.mem[0] = 8'h02;
        uut.UnifiedMem.mem[1] = 8'h70; // ISR address
        
        // Main program
        uut.UnifiedMem.mem[2] = 8'hC0; uut.UnifiedMem.mem[3] = 8'h10; // LDM R0, 0x10 (2-byte)
        uut.UnifiedMem.mem[4] = 8'h88; // INC R0
        uut.UnifiedMem.mem[5] = 8'h00; // NOP
        
        // ISR
        uut.UnifiedMem.mem[112] = 8'hC1; uut.UnifiedMem.mem[113] = 8'hBB; // LDM R1, 0xBB
        uut.UnifiedMem.mem[114] = 8'hBC; // RTI
        
        reset_processor();
        wait_cycles(8); // Interrupt during LDM execution
        
        Interrupt = 1;
        @(posedge clk);
        Interrupt = 0;
        
        wait_cycles(40);
        
        check_register(1, 8'hBB, "2-Byte Interrupt: ISR executed");
        display_registers();
        
        // =====================================================================
        //              TEST 5: RTI Return Address Verification
        // =====================================================================
        display_test_header("RTI: Return Address Verification");
        clear_instruction_memory();
        
        uut.UnifiedMem.mem[0] = 8'h02;
        uut.UnifiedMem.mem[1] = 8'h70; // ISR address
        
        // Main program
        uut.UnifiedMem.mem[2]  = 8'hC0; // LDM R0, 0x00
        uut.UnifiedMem.mem[3]  = 8'h00;
        uut.UnifiedMem.mem[4]  = 8'h88; // INC R0 -> R0 = 0x01
        uut.UnifiedMem.mem[5]  = 8'h00; // NOP
        uut.UnifiedMem.mem[6]  = 8'h00; // NOP
        uut.UnifiedMem.mem[7]  = 8'h00; // NOP
        uut.UnifiedMem.mem[8]  = 8'h88; // INC R0 -> R0 = 0x02 (interrupt here, PC=0x04 saved)
        uut.UnifiedMem.mem[9]  = 8'h00; // NOP
        uut.UnifiedMem.mem[10]  = 8'h00; // NOP
        uut.UnifiedMem.mem[11]  = 8'h00; // NOP
        uut.UnifiedMem.mem[12]  = 8'h88; // INC R0 -> R0 = 0x03 (execute after RTI)
        uut.UnifiedMem.mem[13]  = 8'h00; // NOP
        uut.UnifiedMem.mem[14] = 8'h00; // NOP
        uut.UnifiedMem.mem[15]  = 8'h00; // NOP
        uut.UnifiedMem.mem[16] = 8'h88; // INC R0 -> R0 = 0x04

        
        // ISR at 0x90
        uut.UnifiedMem.mem[112] = 8'h00; // NOP
        uut.UnifiedMem.mem[113] = 8'hBC; // RTI
        
        reset_processor();
        wait_cycles(9); // Let R0 become 0x02
        
        Interrupt = 1;
        @(posedge clk);
        Interrupt = 0;
        
        wait_cycles(70);
        
        // R0 should be 0x04 (0x02 + 2 more increments after RTI)
        check_register(0, 8'h04, "RTI: Correct return and continuation");
        display_registers();
        /*
        // =====================================================================
        //              TEST 6: Stack Pointer Management During Interrupt
        // =====================================================================
        display_test_header("Interrupt: Stack Pointer Behavior");
        clear_instruction_memory();
        
        uut.UnifiedMem.mem[0] = 8'h02;
        uut.UnifiedMem.mem[1] = 8'h70; // ISR address
        
        // Main program
        uut.UnifiedMem.mem[2] = 8'hC0; uut.UnifiedMem.mem[3] = 8'hDE; // LDM R0, 0xDE
        uut.UnifiedMem.mem[4] = 8'h70; // PUSH R0 (SP: 0xFF -> 0xFE)
        uut.UnifiedMem.mem[5] = 8'h00; // NOP (interrupt here, SP=0xFE, saves to 0xFE)
        uut.UnifiedMem.mem[6] = 8'h00; // NOP
        
        // ISR at 0xA0
        uut.UnifiedMem.mem[112] = 8'h75; // POP R1 (should not interfere with saved PC)
        uut.UnifiedMem.mem[113] = 8'hBC; // RTI (pops PC from stack)
        
        reset_processor();
        wait_cycles(20);
        
        sp_before = uut.RF.Registers[3];
        
        Interrupt = 1;
        @(posedge clk);
        Interrupt = 0;
        
        wait_cycles(40);
        
        $display("SP before interrupt: 0x%02h", sp_before);
        $display("SP after RTI: 0x%02h", uut.RF.Registers[3]);
        
        // SP should be restored properly
        check_register(3, sp_before, "Interrupt: SP restored after RTI");
        display_registers();
        */
        // =====================================================================
        //              TEST 7: Interrupt with Modified SP
        // =====================================================================
        display_test_header("Interrupt: Non-Standard SP Value");
        clear_instruction_memory();
        
        uut.UnifiedMem.mem[0] = 8'h02;
        uut.UnifiedMem.mem[1] = 8'h70; // ISR address
        
        // Main program - modify SP
        uut.UnifiedMem.mem[2] = 8'hC0; uut.UnifiedMem.mem[3] = 8'hF0; // LDM R0, 0xF0
        uut.UnifiedMem.mem[4] = 8'h70; // PUSH R0 (several times)
        uut.UnifiedMem.mem[5] = 8'h70; // PUSH R0
        uut.UnifiedMem.mem[6] = 8'h70; // PUSH R0 (SP now at 0xFC)
        uut.UnifiedMem.mem[7] = 8'h00; // NOP (interrupt here)
        
        // ISR
        uut.UnifiedMem.mem[112] = 8'hC1; uut.UnifiedMem.mem[113] = 8'hCC; // LDM R1, 0xCC
        uut.UnifiedMem.mem[114] = 8'hBC; // RTI
        
        reset_processor();
        wait_cycles(30);
        
        Interrupt = 1;
        @(posedge clk);
        Interrupt = 0;
        
        wait_cycles(40);
        
        check_register(1, 8'hCC, "Modified SP: ISR executed");
        display_registers();
        
        // =====================================================================
        //              TEST 8: Rapid Interrupt Requests
        // =====================================================================
        display_test_header("Rapid Interrupts: Multiple Quick Requests");
        clear_instruction_memory();
        
        uut.UnifiedMem.mem[0] = 8'h02;
        uut.UnifiedMem.mem[1] = 8'h70; // ISR address
        
        // Main program
        uut.UnifiedMem.mem[2] = 8'hC0; uut.UnifiedMem.mem[3] = 8'h00; // LDM R0, 0x00
        uut.UnifiedMem.mem[4] = 8'h88; // INC R0
        uut.UnifiedMem.mem[5] = 8'h88; // INC R0
        uut.UnifiedMem.mem[6] = 8'h88; // INC R0
        
        // ISR
        uut.UnifiedMem.mem[112] = 8'h89; // INC R1
        uut.UnifiedMem.mem[113] = 8'hBC; // RTI
        
        reset_processor();
        
        // Send multiple interrupt pulses
        for (i = 0; i < 3; i = i + 1) begin
            wait_cycles(15);
            Interrupt = 1;
            @(posedge clk);
            Interrupt = 0;
        end
        
        wait_cycles(50);
        
        check_register(1, 8'h03, "Rapid Interrupts: All 3 handled");
        display_registers();
        
        // =====================================================================
        //                         FINAL SUMMARY
        // =====================================================================
        $display("\n");
        $display("================================================================================");
        $display("                    INTERRUPT HANDLING TEST SUMMARY");
        $display("================================================================================");
        $display("Total Tests Run:    %0d", passed_tests + failed_tests);
        $display("Tests Passed:       %0d", passed_tests);
        $display("Tests Failed:       %0d", failed_tests);
        if (passed_tests + failed_tests > 0)
            $display("Pass Rate:          %0.1f%%", (passed_tests * 100.0) / (passed_tests + failed_tests));
        $display("================================================================================");
        
        if (failed_tests == 0) begin
            $display("\n*** ALL INTERRUPT TESTS PASSED! ***");
            $display("*** Interrupt handling is working correctly ***\n");
        end else begin
            $display("\n*** SOME TESTS FAILED - Review interrupt logic ***\n");
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
        $dumpfile("processor_interrupt.vcd");
        $dumpvars(0, Processor_TB_Interrupt);
    end

endmodule