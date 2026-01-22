// ============================================================================
// MERGED M/WB PIPELINE REGISTER: Includes Is_2Byte for Forwarding
// ============================================================================
module M_WB_Reg (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] alu_res,
    input  wire [7:0] Data_Out,
    input  wire [1:0] dist,
    input  wire       MemToReg,
    input  wire       RegWrite,
    input  wire       output_valid,
    // input  wire       Is_2Byte,        // NEW: for forwarding logic

    output reg  [7:0] alu_res_out,
    output reg  [7:0] Data_Out_out,
    output reg  [1:0] dist_out,
    output reg        MemToReg_out,
    output reg        output_valid_out,
    output reg        RegWrite_out
    // output reg        Is_2Byte_out     // NEW: for forwarding logic
);
    
always @(posedge clk)
begin
    if (rst)
    begin
        alu_res_out <= 8'b0;
        Data_Out_out <= 8'b0;
        dist_out <= 2'b0;
        MemToReg_out <= 1'b0;
        RegWrite_out <= 1'b0;
        output_valid_out <= 'b0;
        // Is_2Byte_out <= 1'b0;
    end 
    else
    begin
        alu_res_out <= alu_res;
        Data_Out_out <= Data_Out;
        dist_out <= dist;
        MemToReg_out <= MemToReg;
        RegWrite_out <= RegWrite;
        output_valid_out <= output_valid;
        // Is_2Byte_out <= Is_2Byte;
    end
end

endmodule