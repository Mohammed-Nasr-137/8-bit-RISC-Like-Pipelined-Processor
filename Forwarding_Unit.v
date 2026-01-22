
module Forwarding_Unit(
    input  wire [1:0] ID_IF_Rs_Addr,         // source A (current instruction)
    input  wire [1:0] ID_IF_Rt_Addr,         // source B (current instruction)
    
    input  wire       EX_RegWrite,           // does EX write to a reg?
    input  wire [1:0] EX_Addr,               // destination register from EX
    input  wire       EX_Is_2Byte,           // to disable imm value from forwarding
   
    input  wire       EX_MEM_RegWrite,       // does EX/MEM write to a reg?
    input  wire [1:0] EX_MEM_Write_Reg_Addr, // destination register from EX/MEM
   
    input  wire       MEM_WB_RegWrite,       // does MEM/WB write to a reg?
    input  wire [1:0] MEM_WB_Write_Reg_Addr, // destination register from MEM/WB
   
    input wire        no_forward_one ,
    input wire        no_forward_two ,
    output reg  [1:0] Forward_A,             // select for ALU operand A mux
    output reg  [1:0] Forward_B              // select for ALU operand B mux


);

// Forward codes:

// 2'b00 -> no forwarding (use ID/EX.Read_Data)
// 2'b10 -> forward from EX (EX/MEM.ALU_Result)
// 2'b01 -> forward from MEM (MEM/WB.Write_Data)

always @(*) begin
    // default: no forwarding
    Forward_A = 2'b00;
    Forward_B = 2'b00;
    
    // ---------- Forward_A logic (operand A / Rs) ----------
    // Priority 1: EX stage (most recent)

    if (EX_RegWrite && (EX_Addr == ID_IF_Rs_Addr) && (!EX_Is_2Byte) && (!no_forward_one) ) begin
        Forward_A = 2'b01;
    end

    // Priority 2: EX/MEM  (one older)
    else if (EX_MEM_RegWrite && (EX_MEM_Write_Reg_Addr == ID_IF_Rs_Addr) && (!no_forward_one)) begin
        Forward_A = 2'b10;
    end
    // Priority 3: MEM stage (two older)
    else if (MEM_WB_RegWrite && (MEM_WB_Write_Reg_Addr == ID_IF_Rs_Addr) && (!no_forward_one) ) begin
        Forward_A = 2'b11;
    end
    // else remain 2'b00

    // ---------- Forward_B logic (operand B / Rt) ----------
    if (EX_RegWrite && (EX_Addr == ID_IF_Rt_Addr) && (!EX_Is_2Byte) && (!no_forward_two)) begin
        Forward_B = 2'b01;
    end
    
    else if (EX_MEM_RegWrite && (EX_MEM_Write_Reg_Addr == ID_IF_Rt_Addr) && (!no_forward_two)  ) begin
        Forward_B = 2'b10;
    end
    else if (MEM_WB_RegWrite && (MEM_WB_Write_Reg_Addr == ID_IF_Rt_Addr) && (!no_forward_two) ) begin
        Forward_B = 2'b11;
    end
end

endmodule

