module Fetch_Inc (
    input  wire [7:0] PC,
    output wire  [7:0] Next_PC
);

assign Next_PC = PC + 1;
    
endmodule
