module CCR (
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] flags_in,  // from alu to ccr
    input  wire       copy_CCR,  // back-up flags when interrupt
    input  wire       paste_CCR, // restore flags when RTI
    output reg  [3:0] flags_out // from ccr to alu
);
    
reg [7:0] ccr_regs; // {backup, current}

always @(posedge clk)
begin
    if (rst)
    begin
        ccr_regs  <= 'b0;
    end

    if (copy_CCR && !paste_CCR)
    begin
        ccr_regs[7:4] <= ccr_regs[3:0];
    end
    else if (!copy_CCR && paste_CCR)
    begin
        ccr_regs[3:0] <= ccr_regs[7:4];
    end
    else
    begin
        ccr_regs[3:0] <= flags_in;
    end
end

always@ (*)
begin
    if (rst)
    begin
        flags_out = 'b0;
    end
    else
    begin
       flags_out = ccr_regs[3:0]; 
    end
end

endmodule