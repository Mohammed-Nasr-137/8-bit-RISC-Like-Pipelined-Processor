module Register_File (
    // Clock and Reset
    input wire clk,
    input wire rst,
    
    // Register File Signals
    input wire  [1:0] Push_Or_Pop,
    input wire        SP_WEN, // write_SP from CU
    input wire  [1:0] Read_Reg_1,
    input wire  [1:0] Read_Reg_2,
    input wire  [1:0] Write_Reg,
    input wire  [7:0] Write_Data,
    input wire        RegWrite,
    output wire [7:0] Read_Data_1,
    output wire [7:0] Read_Data_2,
    output wire [7:0] SP_Value
);


reg [7:0] Registers [3:0];


// COMBINATIONAL READS (Asynchronous)

assign SP_Value = Registers[3];
assign Read_Data_1 = Registers[Read_Reg_1];
assign Read_Data_2 = Registers[Read_Reg_2];


// SEQUENTIAL WRITES


always @(posedge clk) begin
    if (rst) begin
        // Reset all registers
        Registers[0] <= 8'd0;
        Registers[1] <= 8'd0;
        Registers[2] <= 8'd0;
        Registers[3] <= 8'd255;  // Stack Pointer starts at top
    end
    else begin
        
        // Handle R0, R1, R2 writes (RegWrite controls these)
        
        if (RegWrite) begin
            if (Write_Reg == 2'd0) 
                Registers[0] <= Write_Data;
            else if (Write_Reg == 2'd1)
                Registers[1] <= Write_Data;
            else if (Write_Reg == 2'd2)
                Registers[2] <= Write_Data;
            else if (Write_Reg == 2'd3)
                Registers[3] <= Write_Data;  // Allow RegWrite to R3 when SP_WEN=0
        end
        
        
        // Handle R3 (Stack Pointer) updates - OVERRIDES RegWrite to R3
             
        if (SP_WEN) begin
            if (Push_Or_Pop == 2'b01) begin
                // PUSH: Decrement SP
                Registers[3] <= Registers[3] - 8'd1;
            end
            else if (Push_Or_Pop == 2'b10) begin
                // POP: Increment SP
                Registers[3] <= Registers[3] + 8'd1;
            end
            // else: SP_WEN high but Push_Or_Pop = 00 means hold current value
        end
    end
end

endmodule