module Mux_3to1 (
    input  wire [1:0] sel,     // ALU_src
    input  wire [7:0] op1,     // rb 
    input  wire [7:0] op2,  // imm or in
    input  wire [7:0] op3,      // ra
    output reg  [7:0] mux_out 
);

always @(*)
begin
    case (sel)
        'b00: mux_out = op1;
        'b01: mux_out = op2;
        'b10: mux_out = op3;
        default: mux_out = op1;
    endcase
end

endmodule