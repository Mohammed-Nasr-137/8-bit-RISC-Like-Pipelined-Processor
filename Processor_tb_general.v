`timescale 1ns / 1ps

module Processor_TB;

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
            #10;
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
    
    task check_memory;
        input [7:0] mem_addr;
        input [7:0] expected_value;
        input [200*8:1] test_name;
        reg [7:0] physical_addr;
        begin
            #1;
            // Map logical address (0-127) to physical address (128-255)
            physical_addr = mem_addr + 8'd128;
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
                $display("[PASS] %0s - %0s: %0b (Expected: %0b)", 
                         test_name, flag_name, flag_bit, expected_value);
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
            $display("R0 = 0x%02h (%3d) | R1 = 0x%02h (%3d)", 
                     uut.RF.Registers[0], uut.RF.Registers[0],
                     uut.RF.Registers[1], uut.RF.Registers[1]);
            $display("R2 = 0x%02h (%3d) | R3 = 0x%02h (%3d) [SP]", 
                     uut.RF.Registers[2], uut.RF.Registers[2],
                     uut.RF.Registers[3], uut.RF.Registers[3]);
            $display("Flags: V=%b C=%b N=%b Z=%b", 
                     uut.Flags_Reg.ccr_regs[3],
                     uut.Flags_Reg.ccr_regs[2],
                     uut.Flags_Reg.ccr_regs[1],
                     uut.Flags_Reg.ccr_regs[0]);
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
        $display("     8-BIT PIPELINED PROCESSOR - VON NEUMANN ARCHITECTURE TESTBENCH");
        $display("================================================================================");
        $display("Testing A-Format (including PUSH/POP/IN/OUT) & L-Format Instructions");
        $display("Clock Period: 10ns | Simulation Start Time: %0t", $time);
        $display("Von Neumann: Unified memory with instruction offset by 1");
        $display("================================================================================\n");
        
        // =====================================================================
        //                    TEST 1: RESET VERIFICATION
        // =====================================================================
        display_test_header("RESET VERIFICATION");
        clear_instruction_memory();
        reset_processor();
        wait_cycles(10);
        
        check_register(0, 8'h00, "Reset R0");
        check_register(1, 8'h00, "Reset R1");
        check_register(2, 8'h00, "Reset R2");
        check_register(3, 8'hFF, "Reset R3 (SP)");
        
        // =====================================================================
        //              A-FORMAT TESTS (ARITHMETIC & LOGICAL)
        // =====================================================================
        
        // =====================================================================
        //              TEST 2: ADD with Multiple Values
        // =====================================================================
        display_test_header("A-FORMAT: ADD Multiple Values");
        clear_instruction_memory();
        
        // NOTE: All instructions now start at address 1 (M[0] is reset vector)
        // LDM R0, 0x25
        uut.UnifiedMem.mem[1] = 8'hC0;  
        uut.UnifiedMem.mem[2] = 8'h25;  
        uut.UnifiedMem.mem[3] = 8'h00; uut.UnifiedMem.mem[4] = 8'h00; 
        uut.UnifiedMem.mem[5] = 8'h00; uut.UnifiedMem.mem[6] = 8'h00; uut.UnifiedMem.mem[7] = 8'h00;
        
        // LDM R1, 0x3A
        uut.UnifiedMem.mem[8] = 8'hC1;  
        uut.UnifiedMem.mem[9] = 8'h3A;  
        uut.UnifiedMem.mem[10] = 8'h00; uut.UnifiedMem.mem[11] = 8'h00;
        uut.UnifiedMem.mem[12] = 8'h00; uut.UnifiedMem.mem[13] = 8'h00; uut.UnifiedMem.mem[14] = 8'h00;
        
        // ADD R0, R1 -> R0 = 0x5F
        uut.UnifiedMem.mem[15] = 8'h21;  
        uut.UnifiedMem.mem[16] = 8'h00; uut.UnifiedMem.mem[17] = 8'h00;
        uut.UnifiedMem.mem[18] = 8'h00; uut.UnifiedMem.mem[19] = 8'h00; uut.UnifiedMem.mem[20] = 8'h00;
        
        reset_processor();
        wait_cycles(30);
        
        check_register(0, 8'h5F, "ADD R0, R1 (0x25 + 0x3A = 0x5F)");
        check_register(1, 8'h3A, "R1 unchanged");
        display_registers();
        
        // =====================================================================
        //              TEST 3: SUB with Borrow
        // =====================================================================
        display_test_header("A-FORMAT: SUB with Borrow");
        clear_instruction_memory();
        
        // LDM R0, 0x10
        uut.UnifiedMem.mem[1] = 8'hC0;  
        uut.UnifiedMem.mem[2] = 8'h10;  
        uut.UnifiedMem.mem[3] = 8'h00; uut.UnifiedMem.mem[4] = 8'h00;
        uut.UnifiedMem.mem[5] = 8'h00; uut.UnifiedMem.mem[6] = 8'h00; uut.UnifiedMem.mem[7] = 8'h00;
        
        // LDM R1, 0x25
        uut.UnifiedMem.mem[8] = 8'hC1;  
        uut.UnifiedMem.mem[9] = 8'h25;  
        uut.UnifiedMem.mem[10] = 8'h00; uut.UnifiedMem.mem[11] = 8'h00;
        uut.UnifiedMem.mem[12] = 8'h00; uut.UnifiedMem.mem[13] = 8'h00; uut.UnifiedMem.mem[14] = 8'h00;
        
        // SUB R0, R1 -> R0 = 0xEB (underflow)
        uut.UnifiedMem.mem[15] = 8'h31;  
        uut.UnifiedMem.mem[16] = 8'h00; uut.UnifiedMem.mem[17] = 8'h00;
        uut.UnifiedMem.mem[18] = 8'h00; uut.UnifiedMem.mem[19] = 8'h00; uut.UnifiedMem.mem[20] = 8'h00;
        
        reset_processor();
        wait_cycles(30);
        
        check_register(0, 8'hEB, "SUB R0, R1 (0x10 - 0x25 = 0xEB)");
        check_flag(uut.Flags_Reg.ccr_regs[1], 1'b1, "Negative Flag", "SUB with underflow");
        display_registers();
        
        // =====================================================================
        //              TEST 4: AND Operation
        // =====================================================================
        display_test_header("A-FORMAT: AND Operation");
        clear_instruction_memory();
        
        // LDM R0, 0xF0
        uut.UnifiedMem.mem[1] = 8'hC0;  
        uut.UnifiedMem.mem[2] = 8'hF0;  
        uut.UnifiedMem.mem[3] = 8'h00; uut.UnifiedMem.mem[4] = 8'h00;
        uut.UnifiedMem.mem[5] = 8'h00; uut.UnifiedMem.mem[6] = 8'h00; uut.UnifiedMem.mem[7] = 8'h00;
        
        // LDM R1, 0x33
        uut.UnifiedMem.mem[8] = 8'hC1;  
        uut.UnifiedMem.mem[9] = 8'h33;  
        uut.UnifiedMem.mem[10] = 8'h00; uut.UnifiedMem.mem[11] = 8'h00;
        uut.UnifiedMem.mem[12] = 8'h00; uut.UnifiedMem.mem[13] = 8'h00; uut.UnifiedMem.mem[14] = 8'h00;
        
        // AND R0, R1 -> R0 = 0x30
        uut.UnifiedMem.mem[15] = 8'h41;  
        uut.UnifiedMem.mem[16] = 8'h00; uut.UnifiedMem.mem[17] = 8'h00;
        uut.UnifiedMem.mem[18] = 8'h00; uut.UnifiedMem.mem[19] = 8'h00; uut.UnifiedMem.mem[20] = 8'h00;
        
        reset_processor();
        wait_cycles(30);
        
        check_register(0, 8'h30, "AND R0, R1 (0xF0 & 0x33 = 0x30)");
        display_registers();
        
        // =====================================================================
        //              TEST 5: OR Operation
        // =====================================================================
        display_test_header("A-FORMAT: OR Operation");
        clear_instruction_memory();
        
        // LDM R0, 0xA5
        uut.UnifiedMem.mem[1] = 8'hC0;  
        uut.UnifiedMem.mem[2] = 8'hA5;  
        uut.UnifiedMem.mem[3] = 8'h00; uut.UnifiedMem.mem[4] = 8'h00;
        uut.UnifiedMem.mem[5] = 8'h00; uut.UnifiedMem.mem[6] = 8'h00; uut.UnifiedMem.mem[7] = 8'h00;
        
        // LDM R1, 0x5A
        uut.UnifiedMem.mem[8] = 8'hC1;  
        uut.UnifiedMem.mem[9] = 8'h5A;  
        uut.UnifiedMem.mem[10] = 8'h00; uut.UnifiedMem.mem[11] = 8'h00;
        uut.UnifiedMem.mem[12] = 8'h00; uut.UnifiedMem.mem[13] = 8'h00; uut.UnifiedMem.mem[14] = 8'h00;
        
        // OR R0, R1 -> R0 = 0xFF
        uut.UnifiedMem.mem[15] = 8'h51;  
        uut.UnifiedMem.mem[16] = 8'h00; uut.UnifiedMem.mem[17] = 8'h00;
        uut.UnifiedMem.mem[18] = 8'h00; uut.UnifiedMem.mem[19] = 8'h00; uut.UnifiedMem.mem[20] = 8'h00;
        
        reset_processor();
        wait_cycles(30);
        
        check_register(0, 8'hFF, "OR R0, R1 (0xA5 | 0x5A = 0xFF)");
        display_registers();
        
        // =====================================================================
        //              TEST 6: INC and DEC Chaining
        // =====================================================================
        display_test_header("A-FORMAT: INC and DEC Chain");
        clear_instruction_memory();
        
        // LDM R0, 0x50
        uut.UnifiedMem.mem[1] = 8'hC0;  
        uut.UnifiedMem.mem[2] = 8'h50;  
        uut.UnifiedMem.mem[3] = 8'h00; uut.UnifiedMem.mem[4] = 8'h00;
        uut.UnifiedMem.mem[5] = 8'h00; uut.UnifiedMem.mem[6] = 8'h00; uut.UnifiedMem.mem[7] = 8'h00;
        
        // INC R0 -> R0 = 0x51
        uut.UnifiedMem.mem[8] = 8'h88;  
        uut.UnifiedMem.mem[9] = 8'h00; uut.UnifiedMem.mem[10] = 8'h00;
        uut.UnifiedMem.mem[11] = 8'h00; uut.UnifiedMem.mem[12] = 8'h00; uut.UnifiedMem.mem[13] = 8'h00;
        
        // INC R0 -> R0 = 0x52
        uut.UnifiedMem.mem[14] = 8'h88;  
        uut.UnifiedMem.mem[15] = 8'h00; uut.UnifiedMem.mem[16] = 8'h00;
        uut.UnifiedMem.mem[17] = 8'h00; uut.UnifiedMem.mem[18] = 8'h00; uut.UnifiedMem.mem[19] = 8'h00;
        
        // DEC R0 -> R0 = 0x51
        uut.UnifiedMem.mem[20] = 8'h8C;  
        uut.UnifiedMem.mem[21] = 8'h00; uut.UnifiedMem.mem[22] = 8'h00;
        uut.UnifiedMem.mem[23] = 8'h00; uut.UnifiedMem.mem[24] = 8'h00; uut.UnifiedMem.mem[25] = 8'h00;
        
        reset_processor();
        wait_cycles(40);
        
        check_register(0, 8'h51, "INC-INC-DEC sequence (0x50->0x51->0x52->0x51)");
        display_registers();
        
        // =====================================================================
        //              TEST 7: NOT and NEG Operations
        // =====================================================================
        display_test_header("A-FORMAT: NOT and NEG");
        clear_instruction_memory();
        
        // LDM R0, 0x55
        uut.UnifiedMem.mem[1] = 8'hC0;  
        uut.UnifiedMem.mem[2] = 8'h55;  
        uut.UnifiedMem.mem[3] = 8'h00; uut.UnifiedMem.mem[4] = 8'h00;
        uut.UnifiedMem.mem[5] = 8'h00; uut.UnifiedMem.mem[6] = 8'h00; uut.UnifiedMem.mem[7] = 8'h00;
        
        // NOT R0 -> R0 = 0xAA
        uut.UnifiedMem.mem[8] = 8'h80;  
        uut.UnifiedMem.mem[9] = 8'h00; uut.UnifiedMem.mem[10] = 8'h00;
        uut.UnifiedMem.mem[11] = 8'h00; uut.UnifiedMem.mem[12] = 8'h00; uut.UnifiedMem.mem[13] = 8'h00;
        
        // LDM R1, 0x10
        uut.UnifiedMem.mem[14] = 8'hC1;  
        uut.UnifiedMem.mem[15] = 8'h10;  
        uut.UnifiedMem.mem[16] = 8'h00; uut.UnifiedMem.mem[17] = 8'h00;
        uut.UnifiedMem.mem[18] = 8'h00; uut.UnifiedMem.mem[19] = 8'h00; uut.UnifiedMem.mem[20] = 8'h00;
        
        // NEG R1 -> R1 = 0xF0
        uut.UnifiedMem.mem[21] = 8'h85;  
        uut.UnifiedMem.mem[22] = 8'h00; uut.UnifiedMem.mem[23] = 8'h00;
        uut.UnifiedMem.mem[24] = 8'h00; uut.UnifiedMem.mem[25] = 8'h00; uut.UnifiedMem.mem[26] = 8'h00;
        
        reset_processor();
        wait_cycles(45);
        
        check_register(0, 8'hAA, "NOT R0 (0x55 -> 0xAA)");
        check_register(1, 8'hF0, "NEG R1 (0x10 -> 0xF0)");
        display_registers();
        
        // =====================================================================
        //              TEST 8: PUSH Instruction
        // =====================================================================
        display_test_header("A-FORMAT: PUSH Instruction");
        clear_instruction_memory();
        
        // LDM R0, 0xAA (Data to push)
        uut.UnifiedMem.mem[1] = 8'hC0;  
        uut.UnifiedMem.mem[2] = 8'hAA;  
        uut.UnifiedMem.mem[3] = 8'h00; uut.UnifiedMem.mem[4] = 8'h00;
        uut.UnifiedMem.mem[5] = 8'h00; uut.UnifiedMem.mem[6] = 8'h00; uut.UnifiedMem.mem[7] = 8'h00;
        
        // PUSH R0 (Opcode=7, ra=0, rb=0) -> 0x70
        uut.UnifiedMem.mem[8] = 8'h70;  
        uut.UnifiedMem.mem[9] = 8'h00; uut.UnifiedMem.mem[10] = 8'h00;
        uut.UnifiedMem.mem[11] = 8'h00; uut.UnifiedMem.mem[12] = 8'h00; uut.UnifiedMem.mem[13] = 8'h00;
        
        reset_processor();
        wait_cycles(25);
        
        // Stack grows down from 0xFF (physical 255), PUSH stores at SP then decrements
        check_memory(8'h7F, 8'hAA, "PUSH R0 stored at logical MEM[0x7F] (physical 0xFF)");
        check_register(3, 8'hFE, "SP decremented to 0xFE");
        display_registers();
        
        // =====================================================================
        //              TEST 9: POP Instruction
        // =====================================================================
        display_test_header("A-FORMAT: POP Instruction");
        clear_instruction_memory();
        
        // Pre-setup: Load value, push it, then pop it into different register
        // LDM R0, 0xBB
        uut.UnifiedMem.mem[1] = 8'hC0;  
        uut.UnifiedMem.mem[2] = 8'hBB;  
        uut.UnifiedMem.mem[3] = 8'h00; uut.UnifiedMem.mem[4] = 8'h00;
        uut.UnifiedMem.mem[5] = 8'h00; uut.UnifiedMem.mem[6] = 8'h00; uut.UnifiedMem.mem[7] = 8'h00;
        
        // PUSH R0
        uut.UnifiedMem.mem[8] = 8'h70;  
        uut.UnifiedMem.mem[9] = 8'h00; uut.UnifiedMem.mem[10] = 8'h00;
        uut.UnifiedMem.mem[11] = 8'h00; uut.UnifiedMem.mem[12] = 8'h00; uut.UnifiedMem.mem[13] = 8'h00;
        
        // POP R1 (Opcode=7, ra=1, rb=1) -> 0x75
        uut.UnifiedMem.mem[14] = 8'h75;  
        uut.UnifiedMem.mem[15] = 8'h00; uut.UnifiedMem.mem[16] = 8'h00;
        uut.UnifiedMem.mem[17] = 8'h00; uut.UnifiedMem.mem[18] = 8'h00; uut.UnifiedMem.mem[19] = 8'h00;
        
        reset_processor();
        wait_cycles(35);
        
        check_register(1, 8'hBB, "POP R1 retrieved 0xBB");
        check_register(3, 8'hFF, "SP returned to 0xFF");
        display_registers();
        
        // =====================================================================
        //              TEST 10: IN Instruction 
        // =====================================================================
        display_test_header("A-FORMAT: IN Instruction");
        clear_instruction_memory();

        // Write instructions FIRST
        uut.UnifiedMem.mem[1] = 8'h7E;  // IN R2 (Opcode=7, ra=3, rb=2)
        uut.UnifiedMem.mem[2] = 8'h00; uut.UnifiedMem.mem[3] = 8'h00;
        uut.UnifiedMem.mem[4] = 8'h00; uut.UnifiedMem.mem[5] = 8'h00; 
        uut.UnifiedMem.mem[6] = 8'h00; uut.UnifiedMem.mem[7] = 8'h00;

        // Set IN_Port BEFORE reset
        IN_Port = 8'h77;

        // Reset - but DON'T use reset_processor task!
        rst = 1;
        Interrupt = 0;
        #20;
        rst = 0;

        // Keep IN_Port stable
        IN_Port = 8'h77;

        // Wait for instruction to complete
        wait_cycles(6);

        // NOW check the register
        check_register(2, 8'h77, "IN R2 read from IN_Port");
        display_registers();

        // =====================================================================
        //              TEST 11: OUT Instruction 
        // =====================================================================
        display_test_header("A-FORMAT: OUT Instruction");
        clear_instruction_memory();

        // LDM R0, 0x99
        uut.UnifiedMem.mem[1] = 8'hC0;  
        uut.UnifiedMem.mem[2] = 8'h99;  
        uut.UnifiedMem.mem[3] = 8'h00; uut.UnifiedMem.mem[4] = 8'h00;
        uut.UnifiedMem.mem[5] = 8'h00; uut.UnifiedMem.mem[6] = 8'h00; 
        uut.UnifiedMem.mem[7] = 8'h00;

        // OUT R0 (Opcode=7, ra=2, rb=0)
        uut.UnifiedMem.mem[8] = 8'h78;  
        uut.UnifiedMem.mem[9] = 8'h00; uut.UnifiedMem.mem[10] = 8'h00;
        uut.UnifiedMem.mem[11] = 8'h00; uut.UnifiedMem.mem[12] = 8'h00; 
        uut.UnifiedMem.mem[13] = 8'h00; uut.UnifiedMem.mem[14] = 8'h00;

        reset_processor();
        wait_cycles(12);

        // NOW we can test the OUT_Port
        
        if (uut.OUT_Port === 8'h99) begin
            $display("[PASS] OUT R0: OUT_Port = 0x%02h (Expected: 0x99)", uut.OUT_Port);
            passed_tests = passed_tests + 1;
        end else begin
            $display("[FAIL] OUT R0: OUT_Port = 0x%02h (Expected: 0x99)", uut.OUT_Port);
            failed_tests = failed_tests + 1;
        end

        display_registers();

        // Continue with remaining tests...
        // =====================================================================
        //              TEST 12: RLC (Rotate Left Through Carry)
        // =====================================================================
        display_test_header("A-FORMAT: RLC Operation");
        clear_instruction_memory();
        
        // First set carry flag to 1 using addition overflow
        // LDM R0, 0xFF
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'hFF;  
        uut.UnifiedMem.mem[3] = 8'h00; uut.UnifiedMem.mem[4] = 8'h00;
        uut.UnifiedMem.mem[5] = 8'h00; uut.UnifiedMem.mem[6] = 8'h00; uut.UnifiedMem.mem[7] = 8'h00;
        
        // LDM R1, 0x01
        uut.UnifiedMem.mem[8] = 8'hC1; uut.UnifiedMem.mem[9] = 8'h01;  
        uut.UnifiedMem.mem[10] = 8'h00; uut.UnifiedMem.mem[11] = 8'h00;
        uut.UnifiedMem.mem[12] = 8'h00; uut.UnifiedMem.mem[13] = 8'h00; uut.UnifiedMem.mem[14] = 8'h00;
        
        // ADD R0, R1 -> Sets Carry flag
        uut.UnifiedMem.mem[15] = 8'h21;  
        uut.UnifiedMem.mem[16] = 8'h00; uut.UnifiedMem.mem[17] = 8'h00;
        uut.UnifiedMem.mem[18] = 8'h00; uut.UnifiedMem.mem[19] = 8'h00; uut.UnifiedMem.mem[20] = 8'h00;
        
        // LDM R2, 0xA5
        uut.UnifiedMem.mem[21] = 8'hC2; uut.UnifiedMem.mem[22] = 8'hA5;  
        uut.UnifiedMem.mem[23] = 8'h00; uut.UnifiedMem.mem[24] = 8'h00;
        uut.UnifiedMem.mem[25] = 8'h00; uut.UnifiedMem.mem[26] = 8'h00; uut.UnifiedMem.mem[27] = 8'h00;
        
        // RLC R2
        uut.UnifiedMem.mem[28] = 8'h62;  
        uut.UnifiedMem.mem[29] = 8'h00; uut.UnifiedMem.mem[30] = 8'h00;
        uut.UnifiedMem.mem[31] = 8'h00; uut.UnifiedMem.mem[32] = 8'h00; uut.UnifiedMem.mem[33] = 8'h00;
        
        reset_processor();
        wait_cycles(55);
        
        check_register(2, 8'h4B, "RLC R2 (0xA5 rotated left with C=1)");
        display_registers();

        // =====================================================================
        //              L-FORMAT TESTS
        // =====================================================================
        
        // =====================================================================
        //              TEST 13: LDM Multiple Registers
        // =====================================================================
        display_test_header("L-FORMAT: LDM to All Registers");
        clear_instruction_memory();
        
        // LDM R0, 0xAA
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'hAA;  
        uut.UnifiedMem.mem[3] = 8'h00; uut.UnifiedMem.mem[4] = 8'h00;
        uut.UnifiedMem.mem[5] = 8'h00; uut.UnifiedMem.mem[6] = 8'h00; uut.UnifiedMem.mem[7] = 8'h00;
        
        // LDM R1, 0xBB
        uut.UnifiedMem.mem[8] = 8'hC1; uut.UnifiedMem.mem[9] = 8'hBB;  
        uut.UnifiedMem.mem[10] = 8'h00; uut.UnifiedMem.mem[11] = 8'h00;
        uut.UnifiedMem.mem[12] = 8'h00; uut.UnifiedMem.mem[13] = 8'h00; uut.UnifiedMem.mem[14] = 8'h00;
        
        // LDM R2, 0xCC
        uut.UnifiedMem.mem[15] = 8'hC2; uut.UnifiedMem.mem[16] = 8'hCC;  
        uut.UnifiedMem.mem[17] = 8'h00; uut.UnifiedMem.mem[18] = 8'h00;
        uut.UnifiedMem.mem[19] = 8'h00; uut.UnifiedMem.mem[20] = 8'h00; uut.UnifiedMem.mem[21] = 8'h00;
        
        reset_processor();
        wait_cycles(35);
        
        check_register(0, 8'hAA, "LDM R0, 0xAA");
        check_register(1, 8'hBB, "LDM R1, 0xBB");
        check_register(2, 8'hCC, "LDM R2, 0xCC");
        display_registers();
        
        // =====================================================================
        //              TEST 14: STD to Different Memory Locations
        // =====================================================================
        display_test_header("L-FORMAT: STD Multiple Locations");
        clear_instruction_memory();
        
        // LDM R0, 0x11
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h11;  
        uut.UnifiedMem.mem[3] = 8'h00; uut.UnifiedMem.mem[4] = 8'h00;
        uut.UnifiedMem.mem[5] = 8'h00; uut.UnifiedMem.mem[6] = 8'h00; uut.UnifiedMem.mem[7] = 8'h00;
        
        // STD R0, 0x50
        uut.UnifiedMem.mem[8] = 8'hC8; uut.UnifiedMem.mem[9] = 8'h50;  
        uut.UnifiedMem.mem[10] = 8'h00; uut.UnifiedMem.mem[11] = 8'h00;
        uut.UnifiedMem.mem[12] = 8'h00; uut.UnifiedMem.mem[13] = 8'h00; uut.UnifiedMem.mem[14] = 8'h00;
        
        // LDM R1, 0x22
        uut.UnifiedMem.mem[15] = 8'hC1; uut.UnifiedMem.mem[16] = 8'h22;  
        uut.UnifiedMem.mem[17] = 8'h00; uut.UnifiedMem.mem[18] = 8'h00;
        uut.UnifiedMem.mem[19] = 8'h00; uut.UnifiedMem.mem[20] = 8'h00; uut.UnifiedMem.mem[21] = 8'h00;
        
        // STD R1, 0x60
        uut.UnifiedMem.mem[22] = 8'hC9; uut.UnifiedMem.mem[23] = 8'h60;  
        uut.UnifiedMem.mem[24] = 8'h00; uut.UnifiedMem.mem[25] = 8'h00;
        uut.UnifiedMem.mem[26] = 8'h00; uut.UnifiedMem.mem[27] = 8'h00; uut.UnifiedMem.mem[28] = 8'h00;
        
        reset_processor();
        wait_cycles(45);
        
        check_memory(8'h50, 8'h11, "STD R0 to logical MEM[0x50]");
        check_memory(8'h60, 8'h22, "STD R1 to logical MEM[0x60]");
        display_registers();
        
        // =====================================================================
        //              TEST 15: LDD from Different Memory Locations
        // =====================================================================
        display_test_header("L-FORMAT: LDD Multiple Locations");
        clear_instruction_memory();
        
        
        
        // LDD R0, 0x70
        uut.UnifiedMem.mem[1] = 8'hC4; uut.UnifiedMem.mem[2] = 8'd124;  
        uut.UnifiedMem.mem[3] = 8'h00; uut.UnifiedMem.mem[4] = 8'h00;
        uut.UnifiedMem.mem[5] = 8'h00; uut.UnifiedMem.mem[6] = 8'h00; uut.UnifiedMem.mem[7] = 8'h00;
        
        // LDD R1, 0x80 (note: 0x80 logical maps to 0x80+128=208 physical)
        uut.UnifiedMem.mem[8] = 8'hC5; uut.UnifiedMem.mem[9] = 8'd125;  
        uut.UnifiedMem.mem[10] = 8'h00; uut.UnifiedMem.mem[11] = 8'h00;
        uut.UnifiedMem.mem[12] = 8'h00; uut.UnifiedMem.mem[13] = 8'h00; uut.UnifiedMem.mem[14] = 8'h00;
        
        reset_processor();
        // Pre-load memory using logical addresses
        preload_data_memory(8'd252, 8'h33);
        preload_data_memory(8'd253, 8'h44);
        wait_cycles(30);
        
        check_register(0, 8'h33, "LDD R0 from logical MEM[0x70]");
        check_register(1, 8'h44, "LDD R1 from logical MEM[0x80]");
        display_registers();

        // =====================================================================
        //              TEST 16: STI (Indirect Store)
        // =====================================================================
        display_test_header("L-FORMAT: STI (Store Indirect)");
        clear_instruction_memory();
        
        // LDM R0, 0x10 (Logical address - will map to physical 0x90)
        uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h10;  
        uut.UnifiedMem.mem[3] = 8'h00; uut.UnifiedMem.mem[4] = 8'h00;
        uut.UnifiedMem.mem[5] = 8'h00; uut.UnifiedMem.mem[6] = 8'h00; uut.UnifiedMem.mem[7] = 8'h00;
        
        // LDM R1, 0x55 (Data)
        uut.UnifiedMem.mem[8] = 8'hC1; uut.UnifiedMem.mem[9] = 8'h55;  
        uut.UnifiedMem.mem[10] = 8'h00; uut.UnifiedMem.mem[11] = 8'h00;
        uut.UnifiedMem.mem[12] = 8'h00; uut.UnifiedMem.mem[13] = 8'h00; uut.UnifiedMem.mem[14] = 8'h00;
        
        // STI: M[R0] = R1
        uut.UnifiedMem.mem[15] = 8'hE1;  
        uut.UnifiedMem.mem[16] = 8'h00; uut.UnifiedMem.mem[17] = 8'h00;
        uut.UnifiedMem.mem[18] = 8'h00; uut.UnifiedMem.mem[19] = 8'h00; uut.UnifiedMem.mem[20] = 8'h00;
        
        reset_processor();
        wait_cycles(35);
        
        check_memory(8'h10, 8'h55, "STI: M[R0] = R1 at logical 0x10");
        display_registers();
        
        
   // =====================================================================
//              TEST 17: Combined A-Format Chain
// =====================================================================
display_test_header("COMBINED: A-Format Operation Chain");
clear_instruction_memory();

// LDM R0, 0x0F
uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h0F;  
uut.UnifiedMem.mem[3] = 8'h00; uut.UnifiedMem.mem[4] = 8'h00;
uut.UnifiedMem.mem[5] = 8'h00; uut.UnifiedMem.mem[6] = 8'h00; uut.UnifiedMem.mem[7] = 8'h00;

// LDM R1, 0xF0
uut.UnifiedMem.mem[8] = 8'hC1; uut.UnifiedMem.mem[9] = 8'hF0;  
uut.UnifiedMem.mem[10] = 8'h00; uut.UnifiedMem.mem[11] = 8'h00;
uut.UnifiedMem.mem[12] = 8'h00; uut.UnifiedMem.mem[13] = 8'h00; uut.UnifiedMem.mem[14] = 8'h00;

// OR R0, R1 -> R0 = 0xFF
uut.UnifiedMem.mem[15] = 8'h51;  
uut.UnifiedMem.mem[16] = 8'h00; uut.UnifiedMem.mem[17] = 8'h00;
uut.UnifiedMem.mem[18] = 8'h00; uut.UnifiedMem.mem[19] = 8'h00; uut.UnifiedMem.mem[20] = 8'h00;

// INC R0 -> R0 = 0x00 (overflow)
uut.UnifiedMem.mem[21] = 8'h88;  
uut.UnifiedMem.mem[22] = 8'h00; uut.UnifiedMem.mem[23] = 8'h00;
uut.UnifiedMem.mem[24] = 8'h00; uut.UnifiedMem.mem[25] = 8'h00; uut.UnifiedMem.mem[26] = 8'h00;

reset_processor();
wait_cycles(45);

check_register(0, 8'h00, "OR then INC (0xFF + 1 = 0x00)");
check_flag(uut.Flags_Reg.ccr_regs[0], 1'b1, "Zero Flag", "After INC overflow");
display_registers();

// =====================================================================
//              TEST 18: Combined L-Format Chain
// =====================================================================
display_test_header("COMBINED: L-Format Operation Chain");
clear_instruction_memory();

// LDM R0, 0x77
uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h77;  
uut.UnifiedMem.mem[3] = 8'h00; uut.UnifiedMem.mem[4] = 8'h00;
uut.UnifiedMem.mem[5] = 8'h00; uut.UnifiedMem.mem[6] = 8'h00; uut.UnifiedMem.mem[7] = 8'h00;

// STD R0, 0x30 (will map to physical address 158 = 128+30)
uut.UnifiedMem.mem[8] = 8'hC8; uut.UnifiedMem.mem[9] = 8'h30;  
uut.UnifiedMem.mem[10] = 8'h00; uut.UnifiedMem.mem[11] = 8'h00;
uut.UnifiedMem.mem[12] = 8'h00; uut.UnifiedMem.mem[13] = 8'h00; uut.UnifiedMem.mem[14] = 8'h00;

// LDD R1, 0x30 (Read back)
uut.UnifiedMem.mem[15] = 8'hC5; uut.UnifiedMem.mem[16] = 8'h30;  
uut.UnifiedMem.mem[17] = 8'h00; uut.UnifiedMem.mem[18] = 8'h00;
uut.UnifiedMem.mem[19] = 8'h00; uut.UnifiedMem.mem[20] = 8'h00; uut.UnifiedMem.mem[21] = 8'h00;

// MOV R2, R1
uut.UnifiedMem.mem[22] = 8'h19;  
uut.UnifiedMem.mem[23] = 8'h00; uut.UnifiedMem.mem[24] = 8'h00;
uut.UnifiedMem.mem[25] = 8'h00; uut.UnifiedMem.mem[26] = 8'h00; uut.UnifiedMem.mem[27] = 8'h00;

reset_processor();
wait_cycles(45);

check_memory(8'd48, 8'h77, "STD wrote to memory (physical 158)");
check_register(1, 8'h77, "LDD read from memory");
check_register(2, 8'h77, "MOV copied value");
display_registers();

// =====================================================================
//              TEST 19: Flag Testing - Zero Flag
// =====================================================================
display_test_header("FLAGS: Zero Flag from SUB");
clear_instruction_memory();

// LDM R0, 0x42
uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h42;  
uut.UnifiedMem.mem[3] = 8'h00; uut.UnifiedMem.mem[4] = 8'h00;
uut.UnifiedMem.mem[5] = 8'h00; uut.UnifiedMem.mem[6] = 8'h00; uut.UnifiedMem.mem[7] = 8'h00;

// SUB R0, R0 -> Z=1
uut.UnifiedMem.mem[8] = 8'h30;  
uut.UnifiedMem.mem[9] = 8'h00; uut.UnifiedMem.mem[10] = 8'h00;
uut.UnifiedMem.mem[11] = 8'h00; uut.UnifiedMem.mem[12] = 8'h00; uut.UnifiedMem.mem[13] = 8'h00;

reset_processor();
wait_cycles(25);

check_register(0, 8'h00, "SUB R0, R0 = 0");
check_flag(uut.Flags_Reg.ccr_regs[0], 1'b1, "Zero Flag", "After SUB result = 0");
display_registers();

// =====================================================================
//              TEST 20: Flag Testing - Carry Flag
// =====================================================================
display_test_header("FLAGS: Carry Flag from ADD");
clear_instruction_memory();

// LDM R0, 0xFE
uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'hFE;  
uut.UnifiedMem.mem[3] = 8'h00; uut.UnifiedMem.mem[4] = 8'h00;
uut.UnifiedMem.mem[5] = 8'h00; uut.UnifiedMem.mem[6] = 8'h00; uut.UnifiedMem.mem[7] = 8'h00;

// LDM R1, 0x03
uut.UnifiedMem.mem[8] = 8'hC1; uut.UnifiedMem.mem[9] = 8'h03;  
uut.UnifiedMem.mem[10] = 8'h00; uut.UnifiedMem.mem[11] = 8'h00;
uut.UnifiedMem.mem[12] = 8'h00; uut.UnifiedMem.mem[13] = 8'h00; uut.UnifiedMem.mem[14] = 8'h00;

// ADD R0, R1 -> C=1
uut.UnifiedMem.mem[15] = 8'h21;  
uut.UnifiedMem.mem[16] = 8'h00; uut.UnifiedMem.mem[17] = 8'h00;
uut.UnifiedMem.mem[18] = 8'h00; uut.UnifiedMem.mem[19] = 8'h00; uut.UnifiedMem.mem[20] = 8'h00;

reset_processor();
wait_cycles(30);

check_register(0, 8'h01, "ADD with carry (0xFE + 0x03 = 0x01)");
check_flag(uut.Flags_Reg.ccr_regs[2], 1'b1, "Carry Flag", "After ADD overflow");
display_registers();

// =====================================================================
//              TEST 21: Flag Testing - Negative Flag
// =====================================================================
display_test_header("FLAGS: Negative Flag from NEG");
clear_instruction_memory();

// LDM R0, 0x7F
uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h7F;  
uut.UnifiedMem.mem[3] = 8'h00; uut.UnifiedMem.mem[4] = 8'h00;
uut.UnifiedMem.mem[5] = 8'h00; uut.UnifiedMem.mem[6] = 8'h00; uut.UnifiedMem.mem[7] = 8'h00;

// NEG R0 -> R0 = 0x81 (N=1)
uut.UnifiedMem.mem[8] = 8'h84;  
uut.UnifiedMem.mem[9] = 8'h00; uut.UnifiedMem.mem[10] = 8'h00;
uut.UnifiedMem.mem[11] = 8'h00; uut.UnifiedMem.mem[12] = 8'h00; uut.UnifiedMem.mem[13] = 8'h00;

reset_processor();
wait_cycles(25);

check_register(0, 8'h81, "NEG R0 (0x7F -> 0x81)");
check_flag(uut.Flags_Reg.ccr_regs[1], 1'b1, "Negative Flag", "After NEG");
display_registers();

// =====================================================================
//              TEST 22: Flag Testing - Overflow Flag
// =====================================================================
display_test_header("FLAGS: Overflow Flag from ADD");
clear_instruction_memory();

// LDM R0, 0x7F (127)
uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'h7F;  
uut.UnifiedMem.mem[3] = 8'h00; uut.UnifiedMem.mem[4] = 8'h00;
uut.UnifiedMem.mem[5] = 8'h00; uut.UnifiedMem.mem[6] = 8'h00; uut.UnifiedMem.mem[7] = 8'h00;

// LDM R1, 0x01
uut.UnifiedMem.mem[8] = 8'hC1; uut.UnifiedMem.mem[9] = 8'h01;  
uut.UnifiedMem.mem[10] = 8'h00; uut.UnifiedMem.mem[11] = 8'h00;
uut.UnifiedMem.mem[12] = 8'h00; uut.UnifiedMem.mem[13] = 8'h00; uut.UnifiedMem.mem[14] = 8'h00;

// ADD R0, R1 -> V=1
uut.UnifiedMem.mem[15] = 8'h21;  
uut.UnifiedMem.mem[16] = 8'h00; uut.UnifiedMem.mem[17] = 8'h00;
uut.UnifiedMem.mem[18] = 8'h00; uut.UnifiedMem.mem[19] = 8'h00; uut.UnifiedMem.mem[20] = 8'h00;

reset_processor();
wait_cycles(30);

check_register(0, 8'h80, "ADD causing overflow (127+1=128)");
check_flag(uut.Flags_Reg.ccr_regs[3], 1'b1, "Overflow Flag", "Signed overflow");
display_registers();

// =====================================================================
//              TEST 23: PUSH/POP Sequence
// =====================================================================
display_test_header("COMBINED: PUSH/POP Sequence");
clear_instruction_memory();

// LDM R0, 0xDE
uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'hDE;  
uut.UnifiedMem.mem[3] = 8'h00; uut.UnifiedMem.mem[4] = 8'h00;
uut.UnifiedMem.mem[5] = 8'h00; uut.UnifiedMem.mem[6] = 8'h00; uut.UnifiedMem.mem[7] = 8'h00;

// PUSH R0
uut.UnifiedMem.mem[8] = 8'h70;  
uut.UnifiedMem.mem[9] = 8'h00; uut.UnifiedMem.mem[10] = 8'h00;
uut.UnifiedMem.mem[11] = 8'h00; uut.UnifiedMem.mem[12] = 8'h00; uut.UnifiedMem.mem[13] = 8'h00;

// LDM R1, 0xAD
uut.UnifiedMem.mem[14] = 8'hC1; uut.UnifiedMem.mem[15] = 8'hAD;  
uut.UnifiedMem.mem[16] = 8'h00; uut.UnifiedMem.mem[17] = 8'h00;
uut.UnifiedMem.mem[18] = 8'h00; uut.UnifiedMem.mem[19] = 8'h00; uut.UnifiedMem.mem[20] = 8'h00;

// PUSH R1
uut.UnifiedMem.mem[21] = 8'h71;  
uut.UnifiedMem.mem[22] = 8'h00; uut.UnifiedMem.mem[23] = 8'h00;
uut.UnifiedMem.mem[24] = 8'h00; uut.UnifiedMem.mem[25] = 8'h00; uut.UnifiedMem.mem[26] = 8'h00;

// POP R2
uut.UnifiedMem.mem[27] = 8'h76;  
uut.UnifiedMem.mem[28] = 8'h00; uut.UnifiedMem.mem[29] = 8'h00;
uut.UnifiedMem.mem[30] = 8'h00; uut.UnifiedMem.mem[31] = 8'h00; uut.UnifiedMem.mem[32] = 8'h00;

reset_processor();
wait_cycles(50);

check_register(2, 8'hAD, "POP R2 retrieved last pushed value");
check_register(3, 8'hFE, "SP = 0xFE (one item remains)");
display_registers();

// =====================================================================
//              TEST 24: MOV Chain Test
// =====================================================================
display_test_header("A-FORMAT: MOV Chain");
clear_instruction_memory();

// LDM R0, 0xDE
uut.UnifiedMem.mem[1] = 8'hC0; uut.UnifiedMem.mem[2] = 8'hDE;  
uut.UnifiedMem.mem[3] = 8'h00; uut.UnifiedMem.mem[4] = 8'h00;
uut.UnifiedMem.mem[5] = 8'h00; uut.UnifiedMem.mem[6] = 8'h00; uut.UnifiedMem.mem[7] = 8'h00;

// MOV R1, R0 (Opcode=1, dst=1, src=0) -> 0x14
uut.UnifiedMem.mem[8] = 8'h14;
uut.UnifiedMem.mem[9] = 8'h00; uut.UnifiedMem.mem[10] = 8'h00;
uut.UnifiedMem.mem[11] = 8'h00; uut.UnifiedMem.mem[12] = 8'h00; uut.UnifiedMem.mem[13] = 8'h00;

// MOV R2, R1 (Opcode=1, dst=2, src=1) -> 0x19
uut.UnifiedMem.mem[14] = 8'h19;
uut.UnifiedMem.mem[15] = 8'h00; uut.UnifiedMem.mem[16] = 8'h00;
uut.UnifiedMem.mem[17] = 8'h00; uut.UnifiedMem.mem[18] = 8'h00; uut.UnifiedMem.mem[19] = 8'h00;

reset_processor();
wait_cycles(35);

check_register(0, 8'hDE, "R0 original value");
check_register(1, 8'hDE, "R1 copied from R0");
check_register(2, 8'hDE, "R2 copied from R1");
display_registers();

// =====================================================================
//                         FINAL SUMMARY
// =====================================================================
$display("\n");
$display("================================================================================");
$display("                          TEST SUMMARY");
$display("================================================================================");
$display("Total Tests Run:    %0d", passed_tests + failed_tests);
$display("Tests Passed:       %0d", passed_tests);
$display("Tests Failed:       %0d", failed_tests);
$display("Pass Rate:          %0.1f%%", (passed_tests * 100.0) / (passed_tests + failed_tests));
$display("================================================================================");

if (failed_tests == 0) begin
    $display("\n*** ALL TESTS PASSED! ***\n");
end else begin
    $display("\n*** SOME TESTS FAILED - REVIEW RESULTS ABOVE ***\n");
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
        $dumpfile("processor_tb_vonneumann.vcd");
        $dumpvars(0, Processor_TB);
    end

endmodule
