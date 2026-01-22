module Program_Counter (
    // Clock and Reset
    input wire clk,
    input wire rst,
   // Program Counter Signals
    input wire PC_Write,
    input wire  [7:0] Next_PC,
    output reg [7:0] PC_Out
);

always @ (posedge clk)
    begin
      if (rst==1)
        PC_Out<=8'd0;
      else if (PC_Write==1)
        PC_Out <= Next_PC ;
    end
endmodule


