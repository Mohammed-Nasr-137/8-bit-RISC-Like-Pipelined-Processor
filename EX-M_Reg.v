// ============================================================================
// MERGED EX/M PIPELINE REGISTER: Includes Is_2Byte for Forwarding
// ============================================================================
module EX_M_Reg (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] alu_res,
    input  wire       MemToReg,
    input  wire [7:0] Data_In,
    input  wire [1:0] dist,
    input  wire       RegWrite,
    input  wire       MemWrite,
    input  wire       MemRead,
    input  wire [1:0] StackOp,
    input  wire [7:0] SP_Value,
    input  wire       output_valid,
    // input  wire       Is_2Byte,        // NEW: for forwarding logic
    
    output reg  [7:0] alu_res_out,
    output reg        MemToReg_out,
    output reg  [7:0] Data_In_out,
    output reg  [1:0] dist_out,
    output reg        RegWrite_out,
    output reg        MemWrite_out,
    output reg        MemRead_out,
    output reg  [1:0] StackOp_out,
    output reg        output_valid_out,
    output reg  [7:0] SP_Value_out
    // output reg        Is_2Byte_out     // NEW: for forwarding logic
);

always @(posedge clk)
begin
    if (rst)
    begin
        alu_res_out <= 8'b0;
        MemToReg_out <= 1'b0;
        Data_In_out <= 8'b0;
        dist_out <= 2'b0;
        RegWrite_out <= 1'b0;
        MemWrite_out <= 1'b0;
        MemRead_out <= 1'b0;
        StackOp_out <= 2'b0;
        SP_Value_out <= 8'd255;
        output_valid_out <= 'b0;
        // Is_2Byte_out <= 1'b0;
    end 
    else
    begin
        alu_res_out <= alu_res;
        MemToReg_out <= MemToReg;
        Data_In_out <= Data_In;
        dist_out <= dist;
        RegWrite_out <= RegWrite;
        MemWrite_out <= MemWrite;
        MemRead_out <= MemRead;
        StackOp_out <= StackOp;
        SP_Value_out <= SP_Value;
        output_valid_out <= output_valid;
        // Is_2Byte_out <= Is_2Byte;
    end
end

endmodule