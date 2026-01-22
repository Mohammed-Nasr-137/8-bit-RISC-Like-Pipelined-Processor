`timescale 1ns / 1ps

module Processor_TB_Forwarding;

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
    always #5 clk = ~clk;  // 10ns period = 100MHz
    
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
                $display("[PASS] %0s: R%0d = 0x%02h (Expected: 0x%02h)", 
                         test_name, reg_addr, uut.RF.Registers[reg_addr], expected_value);
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
            $display("\n--- Register File State ---");
            $display("R0 = 0x%02h (%3d) | R1 = 0x%02h (%3d)", 
                     uut.RF.Registers[0], uut.RF.Registers[0],
                     uut.RF.Registers[1], uut.RF.Registers[1]);
            $display("R2 = 0x%02h (%3d) | R3 = 0x%02h (%3d) [SP]", 
                     uut.RF.Registers[2], uut.RF.Registers[2],
                     uut.RF.Registers[3], uut.RF.Registers[3]);
            $display("Forward_A = %b | Forward_B = %b", uut.Forward_A, uut.Forward_B);
        end
    endtask
    
    task clear_instruction_memory;
        integer i;
        begin
            // Clear instruction memory (addresses 0-127)
            for (i = 0; i < 128; i = i + 1) begin
                uut.UnifiedMem.mem[i] = 8'h00;
            end
            // Set reset vector
            uut.UnifiedMem.mem[0] = 8'h01;
        end
    endtask
    
    task preload_data_memory;
        input [7:0] logical_addr;
        input [7:0] value;
        reg [7:0] physical_addr;
        begin
            // Map logical address to physical (128-255)
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
        $display("       DATA FORWARDING TESTBENCH - VON NEUMANN + MERGED VERSION");
        $display("================================================================================");
        $display("Testing pipeline data hazards and forwarding mechanisms");
        $display("Clock Period: 10ns | Simulation Start Time: %0t", $time);
        $display("================================================================================\n");
      
        // =====================================================================
        //              TEST 1: RAW Hazard - EX to EX Forwarding
        // =====================================================================
        display_test_header("RAW HAZARD: EX-to-EX Forwarding (Back-to-Back)");
        clear_instruction_memory();
        
        // LDM R0, 0x10
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h10;
        
        // ADD R0, R0 (uses R0 which was just loaded - needs forwarding)
        uut.UnifiedMem.mem[3] = 8'h20;
        
        // MOV R1, R0 (uses result of ADD)
        uut.UnifiedMem.mem[4] = 8'h14;
        
        reset_processor();
        wait_cycles(30);
        
        check_register(0, 8'h20, "EX-to-EX: ADD result (0x10 + 0x10 = 0x20)");
        check_register(1, 8'h20, "EX-to-EX: MOV forwarded result");
        display_registers();
        
        // =====================================================================
        //              TEST 2: RAW Hazard - MEM to EX Forwarding
        // =====================================================================
        display_test_header("RAW HAZARD: MEM-to-EX Forwarding");
        clear_instruction_memory();
        
        // LDM R0, 0x05
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h05;
        
        // NOP (1 cycle delay)
        uut.UnifiedMem.mem[3] = 8'h00;
        
        // ADD R1, R0 (R0 is in MEM stage when this is in EX)
        uut.UnifiedMem.mem[4] = 8'h24;
        
        reset_processor();
        wait_cycles(30);
        
        check_register(1, 8'h05, "MEM-to-EX: ADD with 1 NOP delay");
        display_registers();
        
        // =====================================================================
        //              TEST 3: Load-Use Hazard (Should Forward from WB)
        // =====================================================================
        display_test_header("LOAD-USE HAZARD: Memory Load followed by Use");
        clear_instruction_memory();
        
        // Pre-load data memory
        
        
        // LDD R0, 0x50 (Load from memory)
        uut.UnifiedMem.mem[1] = 8'hC4; uut.UnifiedMem.mem[2] = 8'h50;
        
        // ADD R1, R0 (Immediate use - should stall or forward from WB)
        uut.UnifiedMem.mem[3] = 8'h24;
        
        reset_processor();
        preload_data_memory(8'd208, 8'h42);
        wait_cycles(35);
        
        check_register(0, 8'h42, "Load-Use: LDD loaded correctly");
        check_register(1, 8'h42, "Load-Use: ADD used loaded value");
        display_registers();
        
        // =====================================================================
        //              TEST 4: Complex RAW Chain
        // =====================================================================
        display_test_header("COMPLEX RAW: Chained Dependencies");
        clear_instruction_memory();
        
        // LDM R0, 0x02
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h02;
        
        // ADD R0, R0 -> R0 = 0x04
        uut.UnifiedMem.mem[3] = 8'h20;
        
        // ADD R0, R0 -> R0 = 0x08
        uut.UnifiedMem.mem[4] = 8'h20;
        
        // ADD R0, R0 -> R0 = 0x10
        uut.UnifiedMem.mem[5] = 8'h20;
        
        // MOV R1, R0 -> R1 = 0x10
        uut.UnifiedMem.mem[6] = 8'h14;
        
        reset_processor();
        wait_cycles(40);
        
        check_register(0, 8'h10, "Complex RAW: R0 = 0x10 (2*2*2*2)");
        check_register(1, 8'h10, "Complex RAW: R1 = R0");
        display_registers();
        
        // =====================================================================
        //              TEST 5: Multiple Source Dependencies
        // =====================================================================
        display_test_header("MULTI-SOURCE: Both operands need forwarding");
        clear_instruction_memory();
        
        // LDM R0, 0x10
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h10;
        
        // LDM R1, 0x20
        uut.UnifiedMem.mem[3] = 8'hC1; uut.UnifiedMem.mem[4] = 8'h20;
        
        // ADD R0, R1 (both just loaded)
        uut.UnifiedMem.mem[5] = 8'h21;
        
        reset_processor();
        wait_cycles(35);
        
        check_register(0, 8'h30, "Multi-Source: 0x10 + 0x20 = 0x30");
        display_registers();
        
        // =====================================================================
        //              TEST 6: ALU Result Forwarding Chain
        // =====================================================================
        display_test_header("ALU CHAIN: Consecutive ALU operations");
        clear_instruction_memory();
        
        // LDM R0, 0xFF
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'hFF;
        
        // INC R0 -> 0x00 (overflow)
        uut.UnifiedMem.mem[3] = 8'h88;
        
        // NOT R0 -> 0xFF
        uut.UnifiedMem.mem[4] = 8'h80;
        
        // DEC R0 -> 0xFE
        uut.UnifiedMem.mem[5] = 8'h8C;
        
        reset_processor();
        wait_cycles(35);
        
        check_register(0, 8'hFE, "ALU Chain: INC->NOT->DEC = 0xFE");
        display_registers();
        
        // =====================================================================
        //              TEST 7: Memory-to-ALU Forwarding
        // =====================================================================
        display_test_header("MEM-to-ALU: Load followed by arithmetic");
        clear_instruction_memory();
        
        
        
        // LDD R0, 0x60
        uut.UnifiedMem.mem[1] = 8'hC4; uut.UnifiedMem.mem[2] = 8'h60;
        
        // LDD R1, 0x70
        uut.UnifiedMem.mem[3] = 8'hC5; uut.UnifiedMem.mem[4] = 8'h70;
        
        // OR R0, R1 -> 0xFF
        uut.UnifiedMem.mem[5] = 8'h51;
        
        reset_processor();
        // Setup data memory
        preload_data_memory(8'd224, 8'h0F);
        preload_data_memory(8'd240, 8'hF0);
        wait_cycles(40);
        
        check_register(0, 8'hFF, "MEM-to-ALU: 0x0F | 0xF0 = 0xFF");
        display_registers();
        
        // =====================================================================
        //              TEST 8: Stack Operations with Forwarding
        // =====================================================================
        display_test_header("STACK FORWARDING: PUSH/POP dependencies");
        clear_instruction_memory();
        
        // LDM R0, 0xDE
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'hDE;
        
        // PUSH R0
        uut.UnifiedMem.mem[3] = 8'h70;
        
        // POP R1 (should get 0xDE)
        uut.UnifiedMem.mem[4] = 8'h75;
        
        // ADD R0, R1 (both should be 0xDE)
        uut.UnifiedMem.mem[5] = 8'h21;
        
        reset_processor();
        wait_cycles(35);
        
        check_register(0, 8'hBC, "Stack: 0xDE + 0xDE = 0xBC (with carry)");
        check_register(1, 8'hDE, "Stack: POP retrieved value");
        display_registers();
        
        // =====================================================================
        //              TEST 9: Indirect Addressing with Forwarding
        // =====================================================================
        display_test_header("INDIRECT FORWARDING: LDI/STI operations");
        clear_instruction_memory();
        
        
        
        // LDM R0, 0x80 (address)
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h50;
        
        // LDI R1, R0 (R1 = M[R0])
        uut.UnifiedMem.mem[3] = 8'hD1;
        
        // INC R1 (use immediately)
        uut.UnifiedMem.mem[4] = 8'h89;
        
        reset_processor();
        // Setup
        preload_data_memory(8'd208, 8'h33);
        wait_cycles(35);
        
        check_register(1, 8'h34, "Indirect: LDI then INC (0x33 + 1)");
        display_registers();
        
        // =====================================================================
        //              TEST 10: WB-to-EX Forwarding (2 cycle distance)
        // =====================================================================
        display_test_header("WB-to-EX FORWARDING: 2 Cycle Distance");
        clear_instruction_memory();
        
        // LDM R0, 0x07
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h07;
        
        // NOP
        uut.UnifiedMem.mem[3] = 8'h00;
        
        // NOP
        uut.UnifiedMem.mem[4] = 8'h00;
        
        // ADD R1, R0 (R0 from WB stage)
        uut.UnifiedMem.mem[5] = 8'h24;
        
        reset_processor();
        wait_cycles(35);
        
        check_register(1, 8'h07, "WB-to-EX: 2 NOPs delay forwarding");
        display_registers();
    
        // =====================================================================
        //                         FINAL SUMMARY
        // =====================================================================
        $display("\n");
        $display("================================================================================");
        $display("                    DATA FORWARDING TEST SUMMARY");
        $display("================================================================================");
        $display("Total Tests Run:    %0d", passed_tests + failed_tests);
        $display("Tests Passed:       %0d", passed_tests);
        $display("Tests Failed:       %0d", failed_tests);
        if (passed_tests + failed_tests > 0)
            $display("Pass Rate:          %0.1f%%", (passed_tests * 100.0) / (passed_tests + failed_tests));
        $display("================================================================================");
        
        if (failed_tests == 0) begin
            $display("\n*** ALL FORWARDING TESTS PASSED! ***");
            $display("*** Data forwarding is working correctly ***\n");
        end else begin
            $display("\n*** SOME TESTS FAILED - Review forwarding logic ***\n");
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
        $dumpfile("processor_forwarding_merged.vcd");
        $dumpvars(0, Processor_TB_Forwarding);
    end

endmodule