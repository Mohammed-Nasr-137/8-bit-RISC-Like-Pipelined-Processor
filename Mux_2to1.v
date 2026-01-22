module Mux_2to1 (
    input  wire       sel,
    input  wire [7:0] op1,
    input  wire [7:0] op2,
    output reg  [7:0] out
);

// to be instantiated:
// before alu operand B -> sel = alu_src, op1 = rb, op2 = if/id_reg.imm
// before addr pin in data memory -> sel = |(stackop), op1 = alu_res, op2 = sp_out (from sp logic)
// wb mux -> sel = memtoreg, op1 = alu_res, op2 = dataout

always @(*)
begin
    case (sel)
        'b0: out = op1;
        'b1: out = op2; 
    endcase
end
    
endmodule
