module Unified_Memory_DualPort(
    input  wire       clk,              // Clock signal
    input  wire       rst,              // Reset signal
    // input  wire       interrupt,
    
    // ============================================
    // PORT A: Instruction Fetch (Read-Only)
    // ============================================
    input  wire [7:0] PC_Address,       // Program Counter (0-127 for instructions)
    output reg  [7:0] Instruction,      // Fetched instruction
    // output reg  [7:0] RESET_INT_out,    // M[0] or M[1] for reset/interrupt
    
    // ============================================
    // PORT B: Data Memory (Read/Write)
    // ============================================
    input  wire [7:0] Data_Address,     // Data address (0-127 for data, 128-255 for stack)
    input  wire [7:0] Data_In,          // Data to write
    input  wire       MemWrite,         // Write enable
    input  wire       MemRead,          // Read enable
    // input  wire [7:0] SP,               // Stack Pointer (128-255 range)
    output reg  [7:0] Data_Out         // Data read output
    // output wire [7:0] Stack_Top         // Top of stack
);

    // ============================================
    // UNIFIED MEMORY ARRAY (256 bytes)
    // ============================================
    // Addresses 0-127:   Instructions (READ ONLY via Port A)
    // Addresses 128-255: Data (READ/WRITE via Port B)
    reg [7:0] mem [0:255];

    // ============================================
    // INITIALIZATION
    // ============================================
    integer i;
    initial begin
        // Initialize entire memory to 0
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 8'h00;
        
        // Load program into instruction section (0-127)
        $readmemh("fibonacci.mem", mem, 0, 127);
    end

    // ============================================
    // ADDRESS MAPPING FOR DATA - FIXED!
    // ============================================
    wire [7:0] mapped_data_addr;
    
    // add offset if not sp operation
    assign mapped_data_addr = (Data_Address >= 8'd128) ? Data_Address : (Data_Address + 8'd128);

    // ============================================
    // PORT A: INSTRUCTION FETCH (Combinational Read)
    // ============================================
    // This port reads instructions from addresses 0-127
    // Can operate simultaneously with Port B
    always @(*) begin
        // Fetch instruction from instruction section
        Instruction = mem[PC_Address];
    end

    // ============================================
    // PORT B: DATA WRITE (Synchronous)
    // ============================================
    // This port writes to data section (addresses 128-255)
    // Operates independently from Port A
    always @(posedge clk) begin
        if (rst) begin
            // CLEAR DATA SEGMENT ONLY (128 to 255)
            for (i = 128; i < 256; i = i + 1) begin
                mem[i] <= 8'h00;
            end
        end
        else if (MemWrite) begin
            // Write to data/stack section (128-255)
            mem[mapped_data_addr] <= Data_In;
        end
    end

    // ============================================
    // PORT B: DATA READ (Combinational)
    // ============================================
    // This port reads from data section (addresses 128-255)
    always @(*) begin
        if (MemRead) begin
            // Read from data/stack section only
            Data_Out = mem[mapped_data_addr];
        end
        else
            Data_Out = 8'h00;
    end
endmodule