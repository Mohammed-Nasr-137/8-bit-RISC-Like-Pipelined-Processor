module Stack_Pointer_Logic(
    input  wire [7:0] Current_SP,  // The current value of R3 (SP)
    input  wire       Is_Push,     // Control signal: Are we Pushing?
    input  wire       Is_Pop,      // Control signal: Are we Popping?
    output reg  [7:0] Mem_Addr_Sel, // The address to send to Memory (for PUSH/POP)
    output reg  [7:0] Next_SP       // The new value for R3 (SP-1 or SP+1)
                                    // should be deleted, R3 is updated
                                    // by CU now
);

    // Combinational logic for stack operations (acts as "Side-ALU" per PDF)
    always @(*) begin
        if (Is_Push) begin
            Mem_Addr_Sel = Current_SP;       // Write at current SP (post-decrement logic)
            Next_SP      = Current_SP - 8'd1; // Then decrement SP
        end
        else if (Is_Pop) begin
            Mem_Addr_Sel = Current_SP + 8'd1; // Read at SP+1 (pre-increment logic)
            Next_SP      = Current_SP + 8'd1; // Then increment SP
        end
        else begin
            Mem_Addr_Sel = 8'd0;        // Default (ignored by address MUX in integrator)
            Next_SP      = Current_SP;  // No change
        end
    end

endmodule