`timescale 1ns / 1ps

module Processor_TB_Hazards;

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
    integer cycle_count;
    
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
    always #5 clk = ~clk;  // 10ns period
    
    // Cycle counter
    always @(posedge clk) begin
        if (rst)
            cycle_count = 0;
        else
            cycle_count = cycle_count + 1;
    end
    
    // =========================================================================
    //                          TEST MANAGEMENT TASKS
    // =========================================================================
    task reset_processor;
        begin
            rst = 1;
            Interrupt = 0;
            IN_Port = 8'h00;
            cycle_count = 0;
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
            $display("\n--- Register File ---");
            $display("R0=0x%02h R1=0x%02h R2=0x%02h R3=0x%02h", 
                     uut.RF.Registers[0], uut.RF.Registers[1],
                     uut.RF.Registers[2], uut.RF.Registers[3]);
            $display("PC=0x%02h Stall=%b", PC_Debug, uut.ID_Stall);
        end
    endtask
    
    task clear_instruction_memory;
        integer i;
        begin
            for (i = 0; i < 128; i = i + 1) begin
                uut.UnifiedMem.mem[i] = 8'h00;
            end
            uut.UnifiedMem.mem[0] = 8'h01;
        end
    endtask
    
    task preload_data_memory;
        input [7:0] logical_addr;
        input [7:0] value;
        reg [7:0] physical_addr;
        begin
            // physical_addr = (logical_addr >= 128) ? logical_addr : logical_addr + 8'd128;
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
        $display("         HAZARD DETECTION & HANDLING - VON NEUMANN + MERGED VERSION");
        $display("================================================================================");
        $display("Testing RAW, WAW, WAR, Load-Use, and Control Hazards");
        $display("Clock Period: 10ns | Start Time: %0t", $time);
        $display("================================================================================\n");
        
        // =====================================================================
        //              TEST 1: RAW Distance 0 - EX Forwarding
        // =====================================================================
        display_test_header("RAW HAZARD: Distance 0 (EX Forwarding)");
        clear_instruction_memory();
        
        // LDM R0, 0x10
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h10;
        
        // LDM R1, 0x05
        uut.UnifiedMem.mem[3] = 8'hC1; uut.UnifiedMem.mem[4] = 8'h05;
        
        // ADD R0, R1  -> R0 = 0x15
        uut.UnifiedMem.mem[5] = 8'h21;
        
        // ADD R2, R0  -> Immediate use (RAW)
        uut.UnifiedMem.mem[6] = 8'h28;
        
        reset_processor();
        wait_cycles(35);
        
        check_register(2, 8'h15, "RAW-0: EX forwarding");
        display_registers();
        
        // =====================================================================
        //              TEST 2: RAW Distance 1 - MEM Forwarding
        // =====================================================================
        display_test_header("RAW HAZARD: Distance 1 (MEM Forwarding)");
        clear_instruction_memory();
        
        // LDM R0, 0x20
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h20;
        
        // LDM R1, 0x0A
        uut.UnifiedMem.mem[3] = 8'hC1; uut.UnifiedMem.mem[4] = 8'h0A;
        
        // ADD R0, R1  -> R0 = 0x2A
        uut.UnifiedMem.mem[5] = 8'h21;
        
        // NOP
        uut.UnifiedMem.mem[6] = 8'h00;
        
        // ADD R2, R0  -> MEM stage forward
        uut.UnifiedMem.mem[7] = 8'h28;
        
        reset_processor();
        wait_cycles(40);
        
        check_register(2, 8'h2A, "RAW-1: MEM forwarding");
        display_registers();
        
        // =====================================================================
        //              TEST 3: Load-Use Hazard (Stall Required)
        // =====================================================================
        display_test_header("LOAD-USE HAZARD: Stall Detection");
        clear_instruction_memory();
        
        
        
        // LDD R0, 0x50
        uut.UnifiedMem.mem[1] = 8'hC4; uut.UnifiedMem.mem[2] = 8'h50;
        
        // ADD R1, R0  -> Load-use hazard!
        uut.UnifiedMem.mem[3] = 8'h24;
        
        reset_processor();
        preload_data_memory(8'd208, 8'h42);
        $display("Monitoring stall signal...");
        wait_cycles(15);
        
        check_register(0, 8'h42, "Load-Use: Data loaded");
        check_register(1, 8'h42, "Load-Use: Hazard resolved");
        display_registers();
        
        // =====================================================================
        //              TEST 4: Both Operands RAW
        // =====================================================================
        display_test_header("DUAL RAW: Both Operands Need Forwarding");
        clear_instruction_memory();
        
        // LDM R0, 0x05
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h05;
        
        // LDM R2, 0x03
        uut.UnifiedMem.mem[3] = 8'hC2; uut.UnifiedMem.mem[4] = 8'h03;
        
        // INC R0  -> R0 = 0x06
        uut.UnifiedMem.mem[5] = 8'h88;
        
        // INC R2  -> R2 = 0x04
        uut.UnifiedMem.mem[6] = 8'h8A;
        
        // ADD R2, R0  -> Both forwarded
        uut.UnifiedMem.mem[7] = 8'h28;
        
        reset_processor();
        wait_cycles(45);
        
        check_register(2, 8'h0A, "Dual RAW: 0x04 + 0x06 = 0x0A");
        display_registers();
        
        // =====================================================================
        //              TEST 5: WAW Hazard
        // =====================================================================
        display_test_header("WAW HAZARD: Multiple Writes to Same Register");
        clear_instruction_memory();
        
        // LDM R0, 0xAA
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'hAA;
        
        // LDM R0, 0xBB
        uut.UnifiedMem.mem[3] = 8'hC0; uut.UnifiedMem.mem[4] = 8'hBB;
        
        // LDM R0, 0xCC
        uut.UnifiedMem.mem[5] = 8'hC0; uut.UnifiedMem.mem[6] = 8'hCC;
        
        // MOV R1, R0
        uut.UnifiedMem.mem[7] = 8'h14;
        
        reset_processor();
        wait_cycles(40);
        
        check_register(0, 8'hCC, "WAW: Last write wins");
        check_register(1, 8'hCC, "WAW: Correct read");
        display_registers();
        
        // =====================================================================
        //              TEST 6: Complex RAW Chain
        // =====================================================================
        display_test_header("COMPLEX CHAIN: Long RAW Dependency");
        clear_instruction_memory();
        
        // LDM R0, 0x02
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h02;
        
        // ADD R0, R0  -> R0 = 0x04
        uut.UnifiedMem.mem[3] = 8'h20;
        
        // ADD R0, R0  -> R0 = 0x08
        uut.UnifiedMem.mem[4] = 8'h20;
        
        // ADD R0, R0  -> R0 = 0x10
        uut.UnifiedMem.mem[5] = 8'h20;
        
        reset_processor();
        wait_cycles(35);
        
        check_register(0, 8'h10, "Chain: 2→4→8→16");
        display_registers();
        
        // =====================================================================
        //              TEST 7: Load-Load-Use Pattern
        // =====================================================================
        display_test_header("LOAD-LOAD-USE: Multiple Loads Then Operation");
        clear_instruction_memory();
        
        
        
        // LDD R0, 0x60
        uut.UnifiedMem.mem[1] = 8'hC4; uut.UnifiedMem.mem[2] = 8'h60;
        
        // LDD R1, 0x70
        uut.UnifiedMem.mem[3] = 8'hC5; uut.UnifiedMem.mem[4] = 8'h70;
        
        // ADD R2, R0
        uut.UnifiedMem.mem[5] = 8'h28;
        
        reset_processor();
        preload_data_memory(8'd224, 8'h11);
        preload_data_memory(8'd240, 8'h22);
        wait_cycles(45);
        
        check_register(0, 8'h11, "Load-Load-Use: R0");
        check_register(1, 8'h22, "Load-Load-Use: R1");
        check_register(2, 8'h11, "Load-Load-Use: R2=R0");
        display_registers();
        
        // =====================================================================
        //              TEST 8: Branch Hazard
        // =====================================================================
        display_test_header("CONTROL HAZARD: Branch with Flush");
        clear_instruction_memory();
        
        // LDM R0, 0x05
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h05;
        
        // SUB R0, R0  -> Z=1
        uut.UnifiedMem.mem[3] = 8'h30;
        
        // LDM R1, 0x21  (target)
        uut.UnifiedMem.mem[4] = 8'hC1; uut.UnifiedMem.mem[5] = 8'h21;
        
        // JZ R1
        uut.UnifiedMem.mem[6] = 8'h91;
        
        // Should be flushed
        uut.UnifiedMem.mem[7] = 8'hC2; uut.UnifiedMem.mem[8] = 8'hAA;
        
        // Target
        uut.UnifiedMem.mem[33] = 8'hC2; uut.UnifiedMem.mem[34] = 8'hBB;
        
        reset_processor();
        wait_cycles(50);
        
        check_register(2, 8'hBB, "Branch: Jumped correctly");
        display_registers();
        
        // =====================================================================
        //              TEST 9: Stack with Forwarding
        // =====================================================================
        display_test_header("STACK HAZARD: PUSH/POP with Dependencies");
        clear_instruction_memory();
        
        // LDM R0, 0xDE
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'hDE;
        
        // INC R0  -> R0 = 0xDF
        uut.UnifiedMem.mem[3] = 8'h88;
        
        // PUSH R0
        uut.UnifiedMem.mem[8] = 8'h70;
        
        // POP R1
        uut.UnifiedMem.mem[9] = 8'h75;
        
        reset_processor();
        wait_cycles(35);
        
        check_register(1, 8'hDF, "Stack: Correct value");
        display_registers();
        
        // =====================================================================
        //              TEST 10: Indirect Load with Forwarding
        // =====================================================================
        display_test_header("INDIRECT HAZARD: LDI with Address Forwarding");
        clear_instruction_memory();
        
        
        
        // LDM R0, 0x90
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h90;
        
        // LDI R1, R0  -> Address needs forwarding
        uut.UnifiedMem.mem[3] = 8'hD1;
        
        reset_processor();
        preload_data_memory(8'h90, 8'h44);
        wait_cycles(35);
        
        check_register(0, 8'h90, "Indirect: Address");
        check_register(1, 8'h44, "Indirect: Data loaded");
        display_registers();
        
        // =====================================================================
        //                         FINAL SUMMARY
        // =====================================================================
        $display("\n");
        $display("================================================================================");
        $display("                    HAZARD DETECTION TEST SUMMARY");
        $display("================================================================================");
        $display("Total Tests:    %0d", passed_tests + failed_tests);
        $display("Passed:         %0d", passed_tests);
        $display("Failed:         %0d", failed_tests);
        if (passed_tests + failed_tests > 0)
            $display("Pass Rate:      %0.1f%%", (passed_tests * 100.0) / (passed_tests + failed_tests));
        $display("================================================================================");
        
        $display("\nHazard Types Tested:");
        $display("  ✓ RAW (Read-After-Write) - EX/MEM/WB forwarding");
        $display("  ✓ WAW (Write-After-Write)");
        $display("  ✓ Load-Use with stall detection");
        $display("  ✓ Control hazards with pipeline flush");
        $display("  ✓ Complex dependency chains");
        $display("  ✓ Stack operation hazards");
        $display("  ✓ Indirect addressing hazards");
        
        if (failed_tests == 0) begin
            $display("\n*** ALL HAZARD TESTS PASSED! ***\n");
        end else begin
            $display("\n*** SOME TESTS FAILED ***\n");
        end
        
        $display("Simulation completed at: %0t", $time);
        $display("================================================================================\n");
        
        #100;
        $finish;
    end
    
    // =========================================================================
    //                    WAVEFORM DUMP
    // =========================================================================
    initial begin
        $dumpfile("processor_hazards_merged.vcd");
        $dumpvars(0, Processor_TB_Hazards);
    end

endmodule