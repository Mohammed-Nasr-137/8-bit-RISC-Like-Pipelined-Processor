module ALU #( parameter REG_WIDTH = 8 , SEL_WIDTH = 4 , CCR_WIDTH = 4 , Result_WIDTH = 8)
(
  input wire signed [REG_WIDTH-1:0] Operand_A , Operand_B ,
  input wire [SEL_WIDTH-1:0] ALU_SEL ,
  input wire [CCR_WIDTH-1:0] CCR_in, // current flags to be preserved if not changed
  output reg signed [Result_WIDTH-1:0] Result ,
  output reg [CCR_WIDTH-1:0] CCR 
) ;

reg V , C , N , Z ; // flags

localparam   [3:0]  NOP                = 4'b0000 ,
                    MOV_LDD_STD_LDM    = 4'b0001 ,
                    ADD                = 4'b0010 ,
                    SUB                = 4'b0011 ,
                    AND                = 4'b0100 ,
                    OR                 = 4'b0101 ,
                    RLC                = 4'b0110 ,
                    RRC                = 4'b0111 ,
                    SETC               = 4'b1000 ,
                    CLRC               = 4'b1001 ,
                    NOT                = 4'b1010 ,
                    NEG                = 4'b1011 ,
                    INC                = 4'b1100 ,
                    DEC                = 4'b1101 ,
                    STI_LDI            = 4'b1110 ;

always@ (*)
 begin
  // CCR = {V , C , N , Z}
  V = CCR_in[3] ;
  C = CCR_in[2] ;
  N = CCR_in[1] ;
  Z = CCR_in[0] ;
  Result = 'b0 ;

  case (ALU_SEL)
   
   MOV_LDD_STD_LDM  : // MOV (put B in the result)
     begin
      Result = Operand_B ;
  
     end
   ADD : // ADD
     begin
      {C , Result} = $unsigned(Operand_A) + $unsigned(Operand_B) ;
      N = Result [7] ;
      Z = ~|Result ;
      V = (Operand_A [7] == Operand_B [7]) & (Result[7] != Operand_A[7]) ;
     end

    SUB : //SUB
      begin
       {C , Result} = Operand_A - Operand_B ;
        N = Result [7] ;
        Z = ~|Result ;
        V = (Operand_A [7] != Operand_B [7]) & (Result[7] != Operand_A[7]) ;
      end
    AND : // AND
      begin
       Result = Operand_A & Operand_B;
       N = Result [7] ;
       Z = ~|Result ;
      end
    OR : // OR
      begin
        Result = Operand_A | Operand_B ;
        N = Result [7] ;
        Z = ~|Result ;
      end
      RLC : 
      begin
            Result = {Operand_B [6:0] , C} ;
            C = Operand_B [7] ;
           end
     RRC : //RRC
          begin
           Result = {C , Operand_B [7:1]} ;
           C = Operand_B [0] ;
          end
    SETC : //SETC
          begin
            C = 1'b1 ;
          end
    CLRC : //CLRC
           begin
            C = 1'b0 ;
           end
        
    NOT : 
      begin
        Result = ~Operand_B ;
        N = Result [7] ;
        Z = ~|Result ;
      end
     NEG :  // NEG
      begin
        Result = ~Operand_B + 1 ;
        N = Result [7] ;
        Z = ~|Result ;
      end
      INC : //INC
      begin
        {C , Result} = Operand_B + 1 ;
         N = Result [7] ;
         Z = ~|Result ;
         V = (Result [7] != Operand_B [7]) ;
      end
      DEC:  // DEC
      begin
        {C , Result} = Operand_B - 1 ;
         N = Result [7] ;
         Z = ~|Result ;
         V = (Result [7] != Operand_B [7]) ;
      end

    STI_LDI:
    begin
      Result = Operand_A;
    end
    
    default : // default case 
        begin
          // CCR = {V , C , N , Z}
          V = CCR_in[3] ;
          C = CCR_in[2] ;
          N = CCR_in[1] ;
          Z = CCR_in[0] ;
          Result = 'b0 ;
        end
      endcase
     
     CCR = {V , C , N , Z} ;

 end
 endmodule