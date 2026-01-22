// ============================================================================
// MERGED PROCESSOR TOP: Von Neumann + Interrupts + Data Forwarding
// ============================================================================
module Processor_Top (
    input  wire clk,
    input  wire rst,
    input  wire [7:0] IN_Port,
    input  wire Interrupt,
    output wire [7:0] Result_Debug,
    output wire [7:0] PC_Debug,
    output wire       Valid,
    output wire [7:0] OUT_Port
);

    // =========================================================================
    //                            WIRES & CONNECTIONS
    // =========================================================================

    // --- IF Stage Wires ---
    wire [7:0] PC_Current;
    wire [7:0] PC_Next_Calculated, PC_PLUS_1; 
    wire [7:0] Instruction_Bus;
    // RESET_INT_out;

    // --- IF/ID Register Outputs ---
    wire [1:0] ID_Read_Reg_1, ID_Read_Reg_2;
    wire [3:0] ID_Opcode;
    wire [7:0] ID_Next_PC, ID_Imm, ID_IN;

    // --- ID Stage Wires ---
    wire ID_RegWrite, ID_MemWrite, ID_MemRead, ID_MemToReg, ID_Branch, ID_Stall, ID_output_valid;
    wire ID_Is_2Byte, ID_Flush, ID_copy_CCR, ID_paste_CCR, ID_write_SP, ID_Imm_IN_Sel;
    wire [1:0] ID_StackOp, ID_ALU_ctrl, ID_dist, ID_Mem_Data_Src, ID_ALU_Src;
    wire [3:0] ID_ALU_Op; 
    wire [1:0] ID_src1, ID_src2;
    wire ID_no_forward_one, ID_no_forward_two;

    wire [7:0] ID_Read_Data_1, ID_Read_Data_2;
    wire [7:0] ID_SP_Value, ID_Imm_IN_mux_out;
    wire [7:0] ID_Data_In_Mux_Out; 

    // --- Forwarding Stage Wires (before ID/EX) ---
    wire [1:0] Forward_A, Forward_B;
    wire [7:0] Forwarded_Data_A, Forwarded_Data_B;
    wire [7:0] MEM_Forwarding_Data;

    // --- ID/EX Register Outputs ---
    wire [1:0] EX_Ra, EX_Rb, EX_dist, EX_StackOp, EX_ALU_Src;
    wire [7:0] EX_Read_Data_1, EX_Read_Data_2, EX_Imm, EX_Next_PC, EX_Data_In, EX_SP_Value;
    wire [3:0] EX_Opcode, EX_ALU_Op;
    wire EX_RegWrite, EX_MemWrite, EX_MemRead, EX_MemToReg, EX_Branch;
    wire EX_copy_CCR, EX_paste_CCR, EX_Is_2Byte, EX_output_valid;

    // --- EX Stage Wires ---
    wire [7:0] EX_ALU_Operand_B; 
    wire [7:0] EX_ALU_Result;
    wire [3:0] EX_CCR_Out, CCR_Flags_To_ALU;
    wire [1:0] PCSrc_sel, inst_mem_src;
    wire EX_Flush;

    // --- EX/M Register Outputs ---
    wire [7:0] MEM_ALU_Result, MEM_Data_In, MEM_SP_Value;
    wire [1:0] MEM_dist, MEM_StackOp;
    wire MEM_RegWrite, MEM_MemWrite, MEM_MemRead, MEM_MemToReg, MEM_Is_2Byte, MEM_output_valid;

    // --- MEM Stage Wires ---
    wire [7:0] MEM_Final_Address, Mem_inst_src_addr; 
    wire [7:0] MEM_Data_Out, Stack_Top;
    wire [7:0] MEM_SP_Calc_Address;
    wire [7:0] MEM_Next_SP;
    wire MEM_Is_Push, MEM_Is_Pop, MEM_StackOp_Active;

    // --- M/WB Register Outputs ---
    wire [7:0] WB_ALU_Result, WB_Data_Out;
    wire [1:0] WB_dist;
    wire WB_MemToReg, WB_RegWrite, WB_Is_2Byte, WB_output_valid;

    // --- WB Stage Wires ---
    wire [7:0] WB_Final_Write_Data; 

    // =========================================================================
    //                           STAGE 1: FETCH (IF)
    // =========================================================================

    Mux_3to1 PC_Mux (
        .sel(PCSrc_sel),
        .op1(PC_PLUS_1),
        .op2(EX_Read_Data_2),
        .op3(Instruction_Bus),
        // .op4(RESET_INT_out),
        .mux_out(PC_Next_Calculated)
    );

    Program_Counter PC (
        .clk(clk),
        .rst(rst),
        // .interrupt(Interrupt),
        // .instruction(Instruction_Bus), // loads M[0] if rst
        .PC_Write(!ID_Stall),
        .Next_PC(PC_Next_Calculated),
        .PC_Out(PC_Current)
    );

    Fetch_Inc PC_Adder (
        .PC(PC_Current),
        .Next_PC(PC_PLUS_1)
    );

    // =========================================================================
    //                    VON NEUMANN UNIFIED MEMORY
    // =========================================================================
    
    Mux_4to1 inst_addr_mux ( 
        // mux to choose between normal instructions source (pc) or from stack if RET/RTI  
        .sel(inst_mem_src),
        .op1(PC_Current),
        .op2(8'b0),
        .op3(8'b1),
        .op4(ID_SP_Value),
        .mux_out(Mem_inst_src_addr)
    );
    
    Unified_Memory_DualPort UnifiedMem (
        .clk(clk),
        .rst(rst),
        // .interrupt(Interrupt),
        
        // PORT A: Instruction Fetch
        .PC_Address(Mem_inst_src_addr),
        .Instruction(Instruction_Bus),
        // .RESET_INT_out(RESET_INT_out),
        
        // PORT B: Data Memory
        .Data_Address(MEM_Final_Address),
        .Data_In(MEM_Data_In),
        .MemWrite(MEM_MemWrite),
        .MemRead(MEM_MemRead),
        // .SP(ID_SP_Value),
        .Data_Out(MEM_Data_Out)
        // .Stack_Top(Stack_Top)
    );

    IF_ID_Reg IF_ID (
        .clk(clk),
        .rst(rst),
        .Flush(EX_Flush),
        .load_en(!ID_Stall),
        .Next_PC(PC_Next_Calculated),
        .Instruction(Instruction_Bus),
        .IN_Port(IN_Port),

        // outputs
        .Read_Reg_1(ID_Read_Reg_1),
        .Read_Reg_2(ID_Read_Reg_2),
        .Opcode(ID_Opcode),
        .Next_PC_out(ID_Next_PC),
        .Imm(ID_Imm),
        .IN_Port_out(ID_IN)
    );

    // =========================================================================
    //                           STAGE 2: DECODE (ID)
    // =========================================================================

    Control_Unit CU (
        .clk(clk),
        .rst(rst),
        .Stall(ID_Stall),
        .Opcode(ID_Opcode),
        .ra(ID_Read_Reg_1),
        .rb(ID_Read_Reg_2),
        .Interrupt(Interrupt),
        .SP(ID_SP_Value),
        .RegWrite(ID_RegWrite),
        .ALU_Src(ID_ALU_Src),
        .MemWrite(ID_MemWrite),
        .MemRead(ID_MemRead),
        .MemToReg(ID_MemToReg),
        .StackOp(ID_StackOp),
        .Branch(ID_Branch),
        .Is_2Byte(ID_Is_2Byte),
        .Flush(ID_Flush),
        .ALU_ctrl(ID_ALU_ctrl),
        .copy_CCR(ID_copy_CCR),
        .paste_CCR(ID_paste_CCR),
        .write_SP(ID_write_SP),
        .push_or_pop(),
        .dist(ID_dist),
        .Mem_Data_Src(ID_Mem_Data_Src),
        .ALU_Op(ID_ALU_Op),
        .Imm_In_sel(ID_Imm_IN_Sel),
        // .Interrupt_Active(),
        .output_valid(ID_output_valid),
        .src1(ID_src1),
        .src2(ID_src2),
        .no_forward_one(ID_no_forward_one),
        .no_forward_two(ID_no_forward_two)
    );

    Hazard_Detection_Unit HDU (
        .ID_EX_MemRead(EX_MemRead),
        .ID_EX_Write_Reg_Addr(EX_dist),
        .IF_ID_Rs_Addr(ID_Read_Reg_1),
        .IF_ID_Rt_Addr(ID_Read_Reg_2),
        // .IF_ID_Rs_Addr(Instruction_Bus[3:2]),
        // .IF_ID_Rt_Addr(Instruction_Bus[1:0]),
        .Stall(ID_Stall)
    );

    Mux_2to1 Imm_IN_Mux (
        .sel(ID_Imm_IN_Sel),
        .op1(Instruction_Bus),
        .op2(ID_IN),
        .out(ID_Imm_IN_mux_out)
    );

    Register_File RF (
        .clk(clk),
        .rst(rst),
        .Push_Or_Pop(ID_StackOp),
        .SP_WEN(ID_write_SP),
        .Read_Reg_1(ID_Read_Reg_1),
        .Read_Reg_2(ID_Read_Reg_2),
        .Write_Reg(WB_dist),
        .Write_Data(WB_Final_Write_Data), 
        .RegWrite(WB_RegWrite),
        .Read_Data_1(ID_Read_Data_1),
        .Read_Data_2(ID_Read_Data_2),
        .SP_Value(ID_SP_Value)
    );

    Data_mem_mux Store_Data_Mux (
        .clk(clk),
        .rst(rst),
        .sel(ID_Mem_Data_Src),
        .rb(Forwarded_Data_B),
        // .rb(ID_Read_Data_2),
        .Next_PC(ID_Next_PC),
        .Data_In(ID_Data_In_Mux_Out)
    );

    // =========================================================================
    //                    DATA FORWARDING LOGIC
    // =========================================================================

    Forwarding_Unit FU (
        .ID_IF_Rs_Addr(ID_src1),
        .ID_IF_Rt_Addr(ID_src2),
        .EX_RegWrite(EX_RegWrite),
        .EX_Addr(EX_dist),
        .EX_Is_2Byte(EX_Is_2Byte),
        .EX_MEM_RegWrite(MEM_RegWrite),
        .EX_MEM_Write_Reg_Addr(MEM_dist),
        .MEM_WB_RegWrite(WB_RegWrite),
        .MEM_WB_Write_Reg_Addr(WB_dist),
        .no_forward_one(ID_no_forward_one),
        .no_forward_two(ID_no_forward_two),
        .Forward_A(Forward_A),
        .Forward_B(Forward_B)
    );

    // MUX to select forwarded data from MEM stage (ALU result or memory data)
    Mux_2to1 MEM_Forward_Mux (
        .sel(MEM_MemToReg),
        .op1(MEM_ALU_Result),
        .op2(MEM_Data_Out),
        .out(MEM_Forwarding_Data)
    );

    // Forwarding MUX A (for operand A)
    Mux_4to1 Forwarding_Mux_A (
        .sel(Forward_A),
        .op1(ID_Read_Data_1),
        .op2(EX_ALU_Result),
        .op3(MEM_Forwarding_Data),
        .op4(WB_Final_Write_Data),
        .mux_out(Forwarded_Data_A)
    );

    // Forwarding MUX B (for operand B)
    Mux_4to1 Forwarding_Mux_B (
        .sel(Forward_B),
        .op1(ID_Read_Data_2),
        .op2(EX_ALU_Result),
        .op3(MEM_Forwarding_Data),
        .op4(WB_Final_Write_Data),
        .mux_out(Forwarded_Data_B)
    );

    ID_EX_Reg ID_EX (
        .clk(clk),
        .rst(rst),
        .Flush(EX_Flush || ID_Stall), // flush if stall so the depenedent inst doesn't get loaded in ex while waiting in dec
        .Ra_addr(ID_Read_Reg_1),
        // .Rb_addr(ID_Read_Reg_2),
        .dist(ID_dist),
        .Read_Data_1(Forwarded_Data_A),       // FORWARDED
        .Read_Data_2(Forwarded_Data_B),       // FORWARDED
        .Imm(ID_Imm_IN_mux_out),
        // .Next_PC(ID_Next_PC),
        .Opcode(ID_Opcode),
        .Data_In(ID_Data_In_Mux_Out),
        .RegWrite(ID_RegWrite),
        .ALU_Src(ID_ALU_Src),
        .MemWrite(ID_MemWrite),
        .MemRead(ID_MemRead),
        .MemToReg(ID_MemToReg),
        .StackOp(ID_StackOp),
        .Branch(ID_Branch),
        .copy_CCR(ID_copy_CCR),
        .paste_CCR(ID_paste_CCR),
        // .push_or_pop(1'b0),
        .SP_Value(ID_SP_Value),
        .ALU_Op(ID_ALU_Op),
        .Is_2Byte(ID_Is_2Byte),
        .Zero_Flag(EX_CCR_Out[0]),
        .output_valid(ID_output_valid),

        // outputs
        .Ra_addr_out(EX_Ra),
        // .Rb_addr_out(EX_Rb),
        .dist_out(EX_dist),
        .Read_Data_1_out(EX_Read_Data_1),
        .Read_Data_2_out(EX_Read_Data_2),
        .Imm_out(EX_Imm),
        // .Next_PC_out(EX_Next_PC),
        .Opcode_out(EX_Opcode),
        .Data_In_out(EX_Data_In),
        .RegWrite_out(EX_RegWrite),
        .ALU_Src_out(EX_ALU_Src),
        .MemWrite_out(EX_MemWrite),
        .MemRead_out(EX_MemRead),
        .MemToReg_out(EX_MemToReg),
        .StackOp_out(EX_StackOp),
        .Branch_out(EX_Branch),
        .copy_CCR_out(EX_copy_CCR),
        .paste_CCR_out(EX_paste_CCR),
        // .push_or_pop_out(),
        .SP_Value_out(EX_SP_Value),
        .ALU_Op_out(EX_ALU_Op),
        .output_valid_out(EX_output_valid),
        .Is_2Byte_out(EX_Is_2Byte)
    );

    // =========================================================================
    //                           STAGE 3: EXECUTE (EX)
    // =========================================================================

    Mux_3to1 ALU_B_Mux (
        .sel(EX_ALU_Src),
        .op1(EX_Read_Data_2),
        .op2(EX_Imm),
        .op3(EX_Read_Data_1),
        .mux_out(EX_ALU_Operand_B)
    );

    Branch_Unit BU (
        .ID_EX_Opcode(EX_Opcode),
        .ID_EX_Rs_Addr(EX_Ra),
        .CCR(EX_CCR_Out),
        .Reset(rst),
        .Branch_en(EX_Branch),
        .Interrupt(Interrupt),
        .PCSrc(PCSrc_sel),
        .inst_mem_src(inst_mem_src),
        .Flush(EX_Flush)
    );

    CCR Flags_Reg (
        .clk(clk),
        .rst(rst),
        .flags_in(EX_CCR_Out), 
        .copy_CCR(EX_copy_CCR),
        .paste_CCR(EX_paste_CCR),
        .flags_out(CCR_Flags_To_ALU) 
    );

    ALU Execution_Unit (
        .Operand_A(EX_Read_Data_1),
        .Operand_B(EX_ALU_Operand_B),
        .CCR_in(CCR_Flags_To_ALU), 
        .Result(EX_ALU_Result),
        .CCR(EX_CCR_Out),
        .ALU_SEL(EX_ALU_Op)
    );

    EX_M_Reg EX_MEM (
        .clk(clk),
        .rst(rst),
        .alu_res(EX_ALU_Result),
        .MemToReg(EX_MemToReg),
        .Data_In(EX_Data_In),
        .dist(EX_dist),
        .RegWrite(EX_RegWrite),
        .MemWrite(EX_MemWrite),
        .MemRead(EX_MemRead),
        .StackOp(EX_StackOp),
        .SP_Value(EX_SP_Value),
        .output_valid(EX_output_valid),
        // .Is_2Byte(EX_Is_2Byte),

        // outputs
        .alu_res_out(MEM_ALU_Result),
        .MemToReg_out(MEM_MemToReg),
        .Data_In_out(MEM_Data_In),
        .dist_out(MEM_dist),
        .RegWrite_out(MEM_RegWrite),
        .MemWrite_out(MEM_MemWrite),
        .MemRead_out(MEM_MemRead),
        .StackOp_out(MEM_StackOp),
        .output_valid_out(MEM_output_valid),
        .SP_Value_out(MEM_SP_Value)
        // .Is_2Byte_out(MEM_Is_2Byte)
    );

    // =========================================================================
    //                           STAGE 4: MEMORY (MEM)
    // =========================================================================

    assign MEM_Is_Push = (MEM_StackOp == 2'b01);
    assign MEM_Is_Pop  = (MEM_StackOp == 2'b10);
    assign MEM_StackOp_Active = |MEM_StackOp;

    Stack_Pointer_Logic SP_Unit (
        .Current_SP(MEM_SP_Value),
        .Is_Push(MEM_Is_Push),
        .Is_Pop(MEM_Is_Pop),
        .Mem_Addr_Sel(MEM_SP_Calc_Address),
        .Next_SP(MEM_Next_SP)
    );

    Mux_2to1 Mem_Addr_Mux (
        .sel(MEM_StackOp_Active),
        .op1(MEM_ALU_Result),
        .op2(MEM_SP_Calc_Address),
        .out(MEM_Final_Address)
    );

    M_WB_Reg MEM_WB (
        .clk(clk),
        .rst(rst),
        .alu_res(MEM_ALU_Result),
        .Data_Out(MEM_Data_Out),
        .dist(MEM_dist),
        .MemToReg(MEM_MemToReg),
        .RegWrite(MEM_RegWrite),
        .output_valid(MEM_output_valid),
        // .Is_2Byte(MEM_Is_2Byte),

        // outputs
        .alu_res_out(WB_ALU_Result),
        .Data_Out_out(WB_Data_Out),
        .dist_out(WB_dist),
        .MemToReg_out(WB_MemToReg),
        .output_valid_out(WB_output_valid),
        .RegWrite_out(WB_RegWrite)
        // .Is_2Byte_out(WB_Is_2Byte)
    );

    // =========================================================================
    //                           STAGE 5: WRITE BACK (WB)
    // =========================================================================

    Mux_2to1 WB_Mux (
        .sel(WB_MemToReg),
        .op1(WB_ALU_Result),
        .op2(WB_Data_Out),
        .out(WB_Final_Write_Data)
    );

    assign Result_Debug = WB_Final_Write_Data;
    assign PC_Debug = PC_Current;
    assign Valid = WB_output_valid;
    assign OUT_Port = WB_Final_Write_Data;

endmodule