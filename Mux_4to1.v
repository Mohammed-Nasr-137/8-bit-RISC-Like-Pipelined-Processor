module Mux_4to1 (
    input  wire [1:0] sel,     // PCSrc
    input  wire [7:0] op1,     // pc_plus_1 
    input  wire [7:0] op2,     // R[rb]
    input  wire [7:0] op3,     // X[++sp]
    input  wire [7:0] op4,     // M[0] , or M[1]
    output reg  [7:0] mux_out 
);

always @(*)
begin
    case (sel)
        'b00: mux_out = op1;
        'b01: mux_out = op2;
        'b10: mux_out = op3;
        'b11: mux_out = op4;
        default: mux_out = op1;
    endcase
end

endmodule
