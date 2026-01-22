// ============================================================================
// MERGED CONTROL UNIT: Forwarding + Interrupts + Von Neumann
// ============================================================================
module Control_Unit
(
  input wire        clk ,
  input wire        rst ,
  input wire        Stall ,
  input wire [3:0]  Opcode ,
  input wire [1:0]  ra , //first operand and branch index 
  input wire [1:0]  rb ,
  input wire        Interrupt ,
  input wire [7:0]  SP ,
 
  output reg        RegWrite ,
  output reg [3:0]  ALU_Op,
  output reg [1:0]  ALU_Src ,
  output reg        MemWrite ,
  output reg        MemRead ,
  output reg        MemToReg ,
  output reg [1:0]  StackOp ,
  output reg        Branch ,
  output reg        Is_2Byte ,
  output reg        Flush ,
  output reg [1:0]  ALU_ctrl ,
  output reg        copy_CCR ,  // back-up flags when interrupt
  output reg        paste_CCR , // restore flags when RTI
  output reg        write_SP ,
  output reg [1:0]  push_or_pop ,
  output reg [1:0]  dist,
  output reg [1:0]  src1,        // NEW: for forwarding unit
  output reg [1:0]  src2,        // NEW: for forwarding unit
  output reg        no_forward_one, // NEW: disable forwarding for src1
  output reg        no_forward_two, // NEW: disable forwarding for src2
  output reg [1:0]  Mem_Data_Src,
  output reg        Imm_In_sel ,
  // output reg        Interrupt_Active,
  output reg        output_valid
);

reg [1:0] current_state , next_state ;

localparam [1:0] IDLE = 2'b00 , two_byte_handle = 2'b01  , INT_handle = 2'b10 , RET = 2'b11 ;

localparam   [3:0]  NOP                  = 4'b0000 ,
                    MOV                  = 4'b0001 ,
                    ADD                  = 4'b0010 ,
                    SUB                  = 4'b0011 ,
                    AND                  = 4'b0100 ,
                    OR                   = 4'b0101 ,
                    R_C                  = 4'b0110 ,
                    PUSH_POP_INOUT       = 4'b0111 ,
                    NOT                  = 4'b1000 ,
                    JUMP_flag            = 4'b1001 ,
                    LOOP                 = 4'b1010 ,
                    CALL_Or_RET_Or_RTI   = 4'b1011 ,
                    LDM_Or_LDD_Or_STD    = 4'b1100 ,
                    LDI                  = 4'b1101 ,
                    STI                  = 4'b1110 ;

always@(posedge clk)
 begin
   if(rst)
    current_state <= IDLE ;
   else if(Stall)
    current_state <= current_state ;
   else 
    current_state <= next_state ;
 end 

always@(*)
 begin
  // Default values for forwarding signals
  Imm_In_sel = 'b0;
  Mem_Data_Src = 'b0;
  src1 = 2'b0;
  src2 = 2'b0;
  no_forward_one = 1'b0;
  no_forward_two = 1'b0;
  ALU_Op    = 4'b0000;
  output_valid = 'b0;

  case(current_state)
 IDLE : begin
   case(Opcode)
         NOP  : begin
                    RegWrite  = 1'b0 ;
                    ALU_Op    = 4'b0000;
                    ALU_Src   = 2'b0 ;
                    ALU_ctrl  = ra   ;
                    Flush     = 1'b0 ;
                    MemWrite  = 1'b0 ;
                    MemRead   = 1'b0 ;
                    MemToReg  = 1'b0 ;
                    StackOp   = 2'd0 ;
                    Branch    = 1'b0 ;
                    Is_2Byte  = 1'b0 ;
                    copy_CCR   = 1'b0 ;
                    paste_CCR  = 1'b0 ;
                    write_SP   = 1'b0 ; 
                    push_or_pop= 2'd0 ;
                    dist       = 2'd0 ;
                    // Interrupt_Active = 1'b0 ;
                end

         MOV  : begin
                    RegWrite  = 1'b1 ;
                    ALU_Op    = 4'b0001;
                    ALU_Src   = 2'b0 ;
                    ALU_ctrl  = ra   ;
                    Flush     = 1'b0 ;
                    MemWrite  = 1'b0 ;
                    MemRead   = 1'b0 ;
                    MemToReg  = 1'b0 ;
                    StackOp   = 2'd0 ;
                    Branch    = 1'b0 ;
                    Is_2Byte  = 1'b0 ;
                    copy_CCR   = 1'b0 ;
                    paste_CCR  = 1'b0 ;
                    write_SP   = 1'b0 ; 
                    push_or_pop= 2'd0 ;
                    dist       = ra   ;
                    src2       = rb   ;
                    no_forward_one = 1'b1 ;
                    // Interrupt_Active = 1'b0 ;
                end 

         ADD  : begin
                    RegWrite  = 1'b1 ;
                    ALU_Op    = 4'b0010 ;
                    ALU_Src   = 2'b0 ;
                    ALU_ctrl  = ra   ;
                    Flush     = 1'b0 ;
                    MemWrite  = 1'b0 ;
                    MemRead   = 1'b0 ;
                    MemToReg  = 1'b0 ;
                    StackOp   = 2'd0 ;
                    Branch    = 1'b0 ;
                    Is_2Byte  = 1'b0 ;
                    copy_CCR   = 1'b0 ;
                    paste_CCR  = 1'b0 ;
                    write_SP   = 1'b0 ; 
                    push_or_pop= 2'd0 ;
                    dist       = ra   ;
                    src1 = ra ;
                    src2 = rb ;
                    // Interrupt_Active = 1'b0 ;
                end

         SUB  : begin
                    RegWrite  = 1'b1 ;
                    ALU_Op    = 4'b0011  ;
                    ALU_Src   = 2'b0 ;
                    ALU_ctrl  = ra   ;
                    Flush     = 1'b0 ;
                    MemWrite  = 1'b0 ;
                    MemRead   = 1'b0 ;
                    MemToReg  = 1'b0 ;
                    StackOp   = 2'd0 ;
                    Branch    = 1'b0 ;
                    Is_2Byte  = 1'b0 ;
                    copy_CCR   = 1'b0 ;
                    paste_CCR  = 1'b0 ;
                    write_SP   = 1'b0 ; 
                    push_or_pop= 2'd0 ;
                    dist       = ra   ;
                    src1 = ra ;
                    src2 = rb ;
                    // Interrupt_Active = 1'b0 ;
                end

         AND   : begin
                    RegWrite  = 1'b1 ;
                    ALU_Op    = 4'b0100;
                    ALU_Src   = 2'b0 ;
                    ALU_ctrl  = ra   ;
                    Flush     = 1'b0 ;
                    MemWrite  = 1'b0 ;
                    MemRead   = 1'b0 ;
                    MemToReg  = 1'b0 ;
                    StackOp   = 2'd0 ;
                    Branch    = 1'b0 ;
                    Is_2Byte  = 1'b0 ;
                    copy_CCR   = 1'b0 ;
                    paste_CCR  = 1'b0 ;
                    write_SP   = 1'b0 ; 
                    push_or_pop= 2'd0 ;
                    dist       = ra   ;
                    src1  = ra ;
                    src2  = rb ;
                    // Interrupt_Active = 1'b0 ;
                end

         OR    : begin
                    RegWrite  = 1'b1 ;
                    ALU_Op    = 4'b0101;
                    ALU_Src   = 2'b0 ;
                    ALU_ctrl  = ra   ;
                    Flush     = 1'b0 ;
                    MemWrite  = 1'b0 ;
                    MemRead   = 1'b0 ;
                    MemToReg  = 1'b0 ;
                    StackOp   = 2'd0 ;
                    Branch    = 1'b0 ;
                    Is_2Byte  = 1'b0 ;
                    copy_CCR   = 1'b0 ;
                    paste_CCR  = 1'b0 ;
                    write_SP   = 1'b0 ; 
                    push_or_pop= 2'd0 ;
                    dist       = ra   ;
                    src1 = ra ;
                    src2 = rb ;
                    // Interrupt_Active = 1'b0 ;
                end

         R_C  : begin
                    RegWrite  = 1'b1 ;  
                    ALU_Op    = Opcode + ra ;
                    ALU_Src   = 2'b0 ;
                    ALU_ctrl  = ra   ;
                    Flush     = 1'b0 ;
                    MemWrite  = 1'b0 ;
                    MemRead   = 1'b0 ;
                    MemToReg  = 1'b0 ;
                    StackOp   = 2'd0 ;
                    Branch    = 1'b0 ;
                    Is_2Byte  = 1'b0 ;
                    copy_CCR   = 1'b0 ;
                    paste_CCR  = 1'b0 ;
                    write_SP   = 1'b0 ; 
                    push_or_pop= 2'd0 ;
                    dist       = rb   ;
                    src2 = ((ra == 2'b00) || (ra == 2'b01)) ? rb : 2'b0 ;
                    no_forward_one = 1'b1 ;
                    no_forward_two = ((ra == 2'b00) || (ra == 2'b01)) ? 1'b0 : 1'b1 ;
                    // Interrupt_Active = 1'b0 ;
                end

  PUSH_POP_INOUT   : begin
                    RegWrite  = (ra == 2'b00 || ra == 2'b10)? 0 : 1 ;
                    ALU_Op    = (ra == 'd2 || ra == 'd3) ? 4'b0001 : 4'b0000 ;
                    ALU_Src   = (ra == 'd3) ? 2'b1 : 2'b0 ;
                    ALU_ctrl  = ra   ;
                    Flush     = 1'b0 ;
                    MemWrite  = (ra == 2'b00)? 1 : 0 ;
                    MemRead   = (ra == 2'b01)? 1 : 0 ;
                    MemToReg  = (ra == 2'b01)? 1 : 0 ;
                    Imm_In_sel = (ra == 'd3) ? 'b1 : 'b0;
                    Branch    = 1'b0 ;
                    Is_2Byte  = 1'b0 ;
                    copy_CCR   = 1'b0 ;
                    paste_CCR  = 1'b0 ;
                    push_or_pop=  (ra == 2'b00)? 2'b01 : 2'b10 ;
                    dist       = rb   ;
                    Mem_Data_Src = 2'b00;
                    StackOp = (ra == 2'b00 && SP!=8'd0 ) ? 2'b01 : (ra == 2'b01 && SP!=8'hFF) ? 2'b10 : 2'b00; 
                    write_SP = ((ra == 2'b00 && SP!=8'd0 ) || (ra == 2'b01 && SP!=8'hFF) ) ? 1'b1 : 1'b0;
                    src2 = ((ra == 2'b00) || (ra == 2'b10)) ? rb : 2'b0 ;
                    no_forward_two = ((ra == 2'b00) || (ra == 2'b10)) ? 1'b0 : 1'b1 ;
                    no_forward_one = 1'b1 ;
                    // Interrupt_Active = 1'b0 ;
                    output_valid = (ra == 2'b10)? 'b1 : 'b0 ;
                end

         NOT   : begin
                    RegWrite  = 1'b1 ;
                    ALU_Op    = Opcode + ra + 4'd2 ;
                    ALU_Src   = 2'b0 ;
                    ALU_ctrl  = ra   ;
                    Flush     = 1'b0 ;
                    MemWrite  = 1'b0 ;
                    MemRead   = 1'b0 ;
                    MemToReg  = 1'b0 ;
                    StackOp   = 2'd0 ;
                    Branch    = 1'b0 ;
                    Is_2Byte  = 1'b0 ;
                    copy_CCR   = 1'b0 ;
                    paste_CCR  = 1'b0 ;
                    write_SP   = 1'b0 ; 
                    push_or_pop= 2'd0 ;
                    dist       = rb   ;
                    src2 = rb ;
                    no_forward_one = 1'b1 ;
                    // Interrupt_Active = 1'b0 ;
                end

         JUMP_flag  : begin
                    RegWrite  = 1'b0 ;
                    ALU_Op    = 4'b0000 ;
                    ALU_Src   = 2'b0 ;
                    ALU_ctrl  = ra   ;
                    Flush     = 1'b0 ;
                    MemWrite  = 1'b0 ;
                    MemRead   = 1'b0 ;
                    MemToReg  = 1'b0 ;
                    StackOp   = 2'd0 ;
                    Branch    = 1'b1 ;
                    Is_2Byte  = 1'b0 ;
                    copy_CCR   = 1'b0 ;
                    paste_CCR  = 1'b0 ;
                    write_SP   = 1'b0 ; 
                    push_or_pop= 2'd0 ;
                    dist       = 2'd0 ;
                    no_forward_one = 1'b1 ;
                    no_forward_two = 1'b1 ;
                    // Interrupt_Active = 1'b0 ;
                end

         LOOP  : begin
                    RegWrite  = 1'b1 ;
                    ALU_Op    = 4'b1101;
                    ALU_Src   = 2'b10 ;
                    ALU_ctrl  = ra   ;
                    Flush     = 1'b0 ;
                    MemWrite  = 1'b0 ;
                    MemRead   = 1'b0 ;
                    MemToReg  = 1'b0 ;
                    StackOp   = 2'd0 ;
                    Branch    = 1'b1 ;
                    Is_2Byte  = 1'b0 ;
                    copy_CCR   = 1'b0 ;
                    paste_CCR  = 1'b0 ;
                    write_SP   = 1'b0 ; 
                    push_or_pop= 2'd0 ;
                    dist       = ra   ;
                    src1 = ra ;
                    src2 = rb ;
                    // Interrupt_Active = 1'b0 ;
                end

   CALL_Or_RET_Or_RTI  : begin
                    RegWrite  = 1'b0;
                    ALU_Op    = 4'b0000;
                    ALU_Src   = 2'b0;
                    ALU_ctrl  = ra  ;
                    Flush     = 1'b0;
                    MemRead   = 1'b0;
                    MemToReg  = 1'b0;
                    MemWrite = (ra == 2'b01) ? 1'b1 : 1'b0;
                    StackOp  = (ra == 2'b01 && SP != 8'h0) ? 2'b01 : ((ra == 2'b10 || ra == 2'b11) && SP != 8'hFF) ? 'b10 : 2'b00;
                    Branch    = 1'b1 ;
                    Is_2Byte  = 1'b0 ;
                    copy_CCR   = 1'b0 ;
                    paste_CCR  = (ra==2'b11)? 1'b1 : 1'b0 ;
                    write_SP   = 1'b1 ; 
                    push_or_pop= 2'b01 ;
                    dist       = 2'd0 ;
                    Mem_Data_Src = (ra == 2'b01) ? 2'b01 : 2'b00;
                    src2 = ((ra == 2'b00) || (ra == 2'b01)) ? rb : 2'b0 ;
                    no_forward_two = ((ra == 2'b00) || (ra == 2'b01)) ? 1'b0 : 1'b1 ;
                    no_forward_one = 1'b1 ;
                    // Interrupt_Active = 1'b0 ;
                end

LDM_Or_LDD_Or_STD   : begin
                    RegWrite  = (ra != 2)? 1 : 0 ;
                    ALU_Op    = 4'b0001  ;
                    ALU_Src   = 2'b1 ;
                    ALU_ctrl  = ra   ;
                    Flush     = 1'b0 ;
                    MemWrite  = (ra == 2)? 1 : 0 ;
                    MemRead   = (ra == 1)? 1 : 0 ;
                    MemToReg  = (ra == 1)? 1 : 0 ;
                    StackOp   = 2'd0 ;
                    Branch    = 1'b0 ;
                    Is_2Byte  = 1'b1 ;
                    copy_CCR   = 1'b0 ;
                    paste_CCR  = 1'b0 ;
                    write_SP   = 1'b0 ; 
                    push_or_pop= 2'b00 ;  
                    dist       = (ra == 2)? ra : rb ;
                    Mem_Data_Src = 2'b00;
                    src2 = (ra == 2'b10) ? rb : 2'b0 ;
                    no_forward_two = (ra == 2'b10) ? 1'b0 : 1'b1 ;
                    no_forward_one = 1'b1 ;
                    // Interrupt_Active = 1'b0 ;
                end
           LDI      : begin
                    RegWrite  = 1'b1 ;
                    ALU_Op    = 4'b1110;
                    ALU_Src   = 2'b0;
                    ALU_ctrl  = ra   ;
                    Flush     = 1'b0 ;
                    MemWrite  = 1'b0 ;
                    MemRead   = 1'b1 ;
                    MemToReg  = 1'b1 ;
                    StackOp   = 2'd0 ;
                    Branch    = 1'b0 ;
                    Is_2Byte  = 1'b0 ;
                    copy_CCR   = 1'b0 ;
                    paste_CCR  = 1'b0 ;
                    write_SP   = 1'b0 ; 
                    push_or_pop= 2'b00 ; 
                    dist       = rb ;
                    src1 = ra ;
                    no_forward_two = 1'b1 ;
                    // Interrupt_Active = 1'b0 ;
                end
             STI   : begin
                    RegWrite  = 1'b0 ;
                    ALU_Op    = 4'b1110;
                    ALU_Src   = 2'b0;
                    ALU_ctrl  = ra   ;
                    Flush     = 1'b0 ;
                    MemWrite  = 1'b1 ;
                    MemRead   = 1'b0 ;
                    MemToReg  = 1'b0 ;
                    StackOp   = 2'd0 ;
                    Branch    = 1'b0 ;
                    Is_2Byte  = 1'b0 ;
                    copy_CCR   = 1'b0 ;
                    paste_CCR  = 1'b0 ;
                    write_SP   = 1'b0 ; 
                    push_or_pop= 2'b00 ; 
                    dist       = rb ;
                    Mem_Data_Src = 2'b00;
                    src1 = ra ;
                    src2 = rb ;
                    // Interrupt_Active = 1'b0 ;
                end

      default  : begin
                    RegWrite  = 1'b0 ;
                    ALU_Op    = 4'd0 ;
                    ALU_Src   = 2'b0 ;
                    ALU_ctrl  = ra   ;
                    Flush     = 1'b0 ;
                    MemWrite  = 1'b0 ;
                    MemRead   = 1'b0 ;
                    MemToReg  = 1'b0 ;
                    StackOp   = 2'd0 ;
                    Branch    = 1'b0 ;
                    Is_2Byte  = 1'b0 ;
                    copy_CCR   = 1'b0 ;
                    paste_CCR  = 1'b0 ;
                    write_SP   = 1'b0 ; 
                    push_or_pop= 2'd0 ; 
                    dist       = 2'd0 ;
                    Mem_Data_Src = 2'b00;
                    // Interrupt_Active = 1'b0 ;
                end
endcase 
        end 

 two_byte_handle : begin
                    RegWrite  = 1'b0 ;
                    ALU_Src   = 2'b0 ;
                    ALU_ctrl  = ra   ;
                    Flush     = 1'b0 ;
                    MemWrite  = 1'b0 ;
                    MemRead   = 1'b0 ;
                    MemToReg  = 1'b0 ;
                    StackOp   = 2'd0 ;
                    Branch    = 1'b0 ;
                    Is_2Byte  = 1'b0 ;
                    copy_CCR   = 1'b0 ;
                    paste_CCR  = 1'b0 ;
                    write_SP   = 1'b0 ; 
                    push_or_pop= 2'd0 ; 
                    dist       = 2'd0 ;
                    // Interrupt_Active = 1'b0 ;
                   end 

   INT_handle    : begin
                    RegWrite   = 1'b0 ;
                    ALU_Src    = 2'b0 ;
                    ALU_ctrl   = ra   ;
                    Flush      = 1'b1 ;
                    MemWrite   = 1'b1 ;
                    MemRead    = 1'b0 ;
                    MemToReg   = 1'b0 ;
                    StackOp    = (SP != 8'd0)? 2'b01 : 2'b00 ;
                    Branch     = 1'b0 ;
                    Is_2Byte   = 1'b0 ;
                    copy_CCR   = 1'b1 ;
                    paste_CCR  = 1'b0 ;
                    write_SP   = (SP != 8'd0)? 1 : 0  ; 
                    push_or_pop= 2'b01 ;
                    dist       = 2'd0 ;
                    Mem_Data_Src = 2'b10;
                    // Interrupt_Active = 1'b1 ;
                    no_forward_one = 'b1;
                    no_forward_two = 'b1;
                   end 
 
   RET           : begin
                    RegWrite   = 1'b0 ;
                    ALU_Src    = 2'b0 ;
                    ALU_ctrl   = ra   ;
                    Flush      = 1'b1 ;
                    MemWrite   = 1'b0 ;
                    MemRead    = 1'b0 ;
                    MemToReg   = 1'b0 ;
                    StackOp    = (SP != 8'hFF)? 2'b10 : 2'b00 ;
                    Branch     = 1'b0 ;
                    Is_2Byte   = 1'b0 ;
                    copy_CCR   = 1'b0 ;
                    paste_CCR  = (ra == 2'b11) ? 1'b1 : 1'b0;
                    write_SP   = 1'b1 ; 
                    push_or_pop= 2'b10 ;
                    dist       = 2'd0 ;
                    // Interrupt_Active = 1'b0 ;
                   end 
  endcase 
end 

always@(*)
 begin
  case(current_state)
   IDLE            :  begin 
                        if(Interrupt)
                         next_state = INT_handle ;
                       else if (Stall) 
                         next_state = current_state ; 
                        else if(Opcode == 11 && ( ra==2 || ra==3 ) )
                         next_state = RET ;
                        else if(Is_2Byte)
                         next_state = two_byte_handle ; 
                        else 
                         next_state = IDLE ;
                      end

   two_byte_handle :  begin 
                        if(Interrupt)
                         next_state = INT_handle ;
                       else if(Stall)
                         next_state = current_state ;      
                       else 
                         next_state = IDLE ;  
                      end
   INT_handle      :  begin 
                       if(Interrupt)
                         next_state = INT_handle ;
                       else if (Stall) 
                       next_state = current_state ; 
                      else 
                       next_state = IDLE ;
                      end

   RET             :  begin 
                      if(Interrupt)
                         next_state = INT_handle ;
                      else if (Stall) 
                         next_state = current_state ; 
                      else 
                         next_state = IDLE ;
                      end

    default         : 
                         next_state = IDLE ;  
endcase 
 end 
endmodule