module ID_EX_Reg (
    input  wire       clk,
    input  wire       rst,
    input  wire       Flush,
    input  wire [1:0] Ra_addr, // rs
    // input  wire [1:0] Rb_addr, // rt
    input  wire [1:0] dist,
    input  wire [7:0] Read_Data_1,
    input  wire [7:0] Read_Data_2,
    input  wire [7:0] Imm, // immediate value for 2 byte inst, or 
                           // input passing through pipeline to be written back
    // input  wire [7:0] Next_PC, // is this really needed?
    input  wire [3:0] Opcode,
    input  wire [7:0] Data_In,
    input  wire       RegWrite,
    input  wire [1:0] ALU_Src,
    input  wire       MemWrite,
    input  wire       MemRead,
    input  wire       MemToReg,
    input  wire [1:0] StackOp,
    input  wire       Branch, // is this really needed?
    input  wire       copy_CCR,
    input  wire       paste_CCR,
    // input  wire       push_or_pop,
    input  wire [7:0] SP_Value,   // output of R3
    input  wire [3:0] ALU_Op,
    input  wire       Is_2Byte, // used to enable Branch Unit
    // input  wire [7:0] IN_OUT_Port, // to be used for IN-Out instruction
    input  wire       Zero_Flag,
    input  wire       output_valid,

    output reg  [1:0] Ra_addr_out,
    // output reg  [1:0] Rb_addr_out,
    output reg  [1:0] dist_out,
    output reg  [7:0] Read_Data_1_out,
    output reg  [7:0] Read_Data_2_out,
    output reg  [7:0] Imm_out,
    // output reg  [7:0] Next_PC_out,
    output reg  [3:0] Opcode_out,
    output reg  [7:0] Data_In_out,
    output reg        RegWrite_out,
    output reg  [1:0] ALU_Src_out,
    output reg        MemWrite_out,
    output reg        MemRead_out,
    output reg        MemToReg_out,
    output reg  [1:0] StackOp_out,
    output reg        Branch_out,
    output reg        copy_CCR_out,
    output reg        paste_CCR_out,
    // output reg        push_or_pop_out,
    output reg  [7:0] SP_Value_out,
    output reg  [3:0] ALU_Op_out,
    output reg        output_valid_out,
    output reg        Is_2Byte_out
    // output reg  [7:0] IN_OUT_Port_out
);
    
always @(posedge clk)
begin
    if (rst || Flush)
    begin
        Ra_addr_out <= 2'b0;
        // Rb_addr_out <= 2'b0;
        dist_out <= 2'b0;
        Read_Data_1_out <= 8'b0;
        Read_Data_2_out <= 8'b0;
        Imm_out <= 8'b0;
        // Next_PC_out <= 8'b0;
        Opcode_out <= 4'b0;
        Data_In_out <= 8'b0;
        RegWrite_out <= 1'b0;
        ALU_Src_out <= 1'b0;
        MemWrite_out <= 1'b0;
        MemRead_out <= 1'b0;
        MemToReg_out <= 1'b0;
        StackOp_out <= 2'b0;
        Branch_out <= 1'b0;
        copy_CCR_out <= 1'b0;
        paste_CCR_out <= 1'b0;
        // push_or_pop_out <= 1'b0;
        SP_Value_out <= 'd255;
        ALU_Op_out <= 'd0;
        // IN_OUT_Port_out <= 'd0;
        Is_2Byte_out <= 'b0;
        output_valid_out <= 'b0;
    end
    else
    begin
        Ra_addr_out <= Ra_addr;
        // Rb_addr_out <= Rb_addr;
        dist_out <= dist;
        Read_Data_1_out <= Read_Data_1;
        Read_Data_2_out <= Read_Data_2;
        Imm_out <= Imm;
        // Next_PC_out <= Next_PC;
        Opcode_out <= Opcode;
        Data_In_out <= Data_In;

        RegWrite_out <= (Zero_Flag && (Opcode == 'b1010)) ? 'b0 : RegWrite;
        ALU_Src_out <= ALU_Src;
        MemWrite_out <= MemWrite;
        MemRead_out <= MemRead;
        MemToReg_out <= MemToReg;
        StackOp_out <= StackOp;
        Branch_out <= Branch;
        copy_CCR_out <= copy_CCR;
        paste_CCR_out <= paste_CCR;
        // push_or_pop_out <= push_or_pop;
        SP_Value_out <= SP_Value;
        // ALU_Op_out <= ALU_Op;
        ALU_Op_out <= (Zero_Flag && (Opcode == 'b1010)) ? 4'b0000 : ALU_Op;
        // IN_OUT_Port_out <= IN_OUT_Port;
        Is_2Byte_out <= Is_2Byte;
        output_valid_out <= output_valid;
    end
end

endmodule
