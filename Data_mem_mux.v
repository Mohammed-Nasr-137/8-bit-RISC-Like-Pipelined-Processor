module Data_mem_mux(
 input wire       clk ,
 input wire       rst,
 input wire [1:0] sel ,
 input wire [7:0] rb  ,
 input wire [7:0] Next_PC ,
 output reg [7:0] Data_In 
);

reg [7:0] PC ;

always@(posedge clk) 
begin 
  if (rst)
  begin
    PC <= 'b0;
  end
  else
  begin
    PC <=Next_PC;
  end
end 

always@(*)
begin 
  case (sel )
   'b00 : Data_In = rb ;
   'b01 : Data_In = Next_PC ;
   'b10 : Data_In = PC ;
   default : Data_In = rb ; 
  endcase 
end 
endmodule
