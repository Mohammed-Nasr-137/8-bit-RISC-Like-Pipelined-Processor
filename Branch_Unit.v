module Branch_Unit  
 (
  input wire [3:0] ID_EX_Opcode ,
  input wire [1:0] ID_EX_Rs_Addr ,
  input wire [3:0] CCR ,
  input wire Reset ,
  input wire Branch_en,  
  input wire Interrupt ,
  output reg [1:0] PCSrc ,
  output reg [1:0] inst_mem_src,
  output reg Flush 
 );

reg [1:0] B_sel ;
reg Z ;
reg N ;
reg C ;
reg V ;

 always@ (*)
  begin
    PCSrc = 2'b00 ;
    Flush = 1'b0 ;
    inst_mem_src = 'b0;
    B_sel = ID_EX_Opcode [1:0] ;
    {V , C , N , Z} = CCR  ;
    if (Reset )  
     begin
       PCSrc = 2'b10 ;
       Flush = 1'b1 ;
       inst_mem_src = 'd1;
     end
    else if (Interrupt)
    begin
      PCSrc = 2'b10 ;
      Flush = 1'b1 ;
      inst_mem_src = 'd2;
    end
    else if (ID_EX_Opcode[3:2] == 2'b10 && Branch_en)
    begin
     case (B_sel)

      2'b01 : 
       begin
         case (ID_EX_Rs_Addr)
          
          2'b00 :  // jz
           begin
             if (Z == 1'b1)
              begin
               Flush = 1'b1 ;
               PCSrc = 2'b01 ;
              end
             else
              begin
               Flush = 1'b0 ;
               PCSrc = 2'b00 ;
              end
           end

           2'b01 :  // jn
           begin
             if (N == 1'b1)
              begin
               Flush = 1'b1 ;
               PCSrc = 2'b01 ;
              end
             else
              begin
               Flush = 1'b0 ;
               PCSrc = 2'b00 ;
              end
           end

           2'b10 :  // jc
           begin
             if (C == 1'b1)
              begin
               Flush = 1'b1 ;
               PCSrc = 2'b01 ;
              end
             else
              begin
               Flush = 1'b0 ;
               PCSrc = 2'b00 ;
              end
           end

           2'b11 :  // jv
           begin
             if (V == 1'b1)
              begin
               Flush = 1'b1 ;
               PCSrc = 2'b01 ;
              end
             else
              begin
               Flush = 1'b0 ;
               PCSrc = 2'b00 ;
              end
           end
           endcase
       end

        2'b10 : // loop
         begin 
          // {V , C , N , Z} = ALU_flags;
           if (Z == 1'b1)
            begin
              PCSrc = 2'b00 ;
              Flush = 1'b0 ;
            end
          else 
            begin 
             PCSrc = 2'b01 ;
             Flush = 1'b1 ;
            end
         end

        2'b11 :
          begin
            case (ID_EX_Rs_Addr)
             
             2'b00 : // jmp
              begin
                PCSrc = 2'b01 ;
                Flush = 1'b1 ;
              end
             
             2'b01 : // call
              begin
                PCSrc = 2'b01 ;
                Flush = 1'b1 ;
              end

              2'b10 : //RET
               begin
                 PCSrc = 2'b10 ;
                 Flush = 1'b1 ;
                 inst_mem_src = 'd3;
               end
              2'b11 : //RTI
               begin
                 PCSrc = 2'b10 ;
                 Flush = 1'b1 ;
                 inst_mem_src = 'd3;
               end
           endcase
              
          end

          default :
           begin
            PCSrc = 2'b00 ;
            Flush = 1'b0 ;
           end
     endcase
end
end
endmodule