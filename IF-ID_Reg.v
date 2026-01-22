module IF_ID_Reg (
    input  wire       clk,
    input  wire       rst,
    input  wire       Flush,
    input  wire       load_en, // enable to load reg if not stall
    // input  wire [7:0] PC, // routed to data_in
    input  wire [7:0] Next_PC,
    input  wire [7:0] Instruction,
    input  wire [7:0] IN_Port, // to be used for IN instruction

    output reg  [1:0] Read_Reg_1, // ra address
    output reg  [1:0] Read_Reg_2, // rb address
    output reg  [3:0] Opcode,
    // output reg  [7:0] PC_out, 
    output reg  [7:0] Next_PC_out,
    output reg  [7:0] Imm,
    output reg  [7:0] IN_Port_out
);

always @(posedge clk)
begin
    if (rst || Flush)
    begin
        Read_Reg_1  <= 'b0;
        Read_Reg_2  <= 'b0;
        Opcode      <= 'b0;
        // PC_out      <= 'b0;
        Next_PC_out <= 'b0;
        Imm         <= 'b0;
        IN_Port_out <= 'd0;
    end
    else if (load_en)
    begin
        Read_Reg_1  <= Instruction[3:2];
        Read_Reg_2  <= Instruction[1:0];
        Opcode      <= Instruction[7:4];
        // PC_out      <= PC;
        Next_PC_out <= Next_PC;
        Imm         <= Instruction;
        IN_Port_out <= IN_Port;
    end
end
    
endmodule
