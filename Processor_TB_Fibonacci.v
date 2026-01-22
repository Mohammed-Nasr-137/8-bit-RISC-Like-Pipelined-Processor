`timescale 1ns / 1ps

module Processor_Top_TB;

    // ============================================
    // 1. Signals
    // ============================================
    reg         clk;
    reg         rst;
    reg  [7:0]  IN_Port;
    reg         Interrupt;
    
    // Outputs from DUT
    wire [7:0]  Result_Debug;
    wire [7:0]  PC_Debug;
    wire        Valid;
    wire [7:0]  OUT_Port;

    // ============================================
    // 2. DUT Instantiation
    // ============================================
    Processor_Top dut (
        .clk(clk),
        .rst(rst),
        .IN_Port(IN_Port),
        .Interrupt(Interrupt),
        .Result_Debug(Result_Debug),
        .PC_Debug(PC_Debug),
        .Valid(Valid),
        .OUT_Port(OUT_Port)
    );

    // ============================================
    // 3. Clock Generation (100MHz / 10ns period)
    // ============================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ============================================
    // 4. Test Sequence
    // ============================================
    initial begin
        // Initialize Inputs
        rst = 1;
        Interrupt = 0;
        IN_Port = 8'h00; // Not used for Fibonacci

        // Hold Reset for a few cycles
        #20;
        rst = 0;
        
        $display("--- Starting Simulation ---");
        
        // Run for enough time to see the sequence (2000ns = 200 cycles)
        #2000; 
        
        $display("--- Simulation Finished ---");
        $stop;
    end

    // ============================================
    // 5. Output Monitor
    // ============================================
    // Detects changes on OUT_Port to display Fibonacci numbers
    always @(posedge clk) begin
    // Only print if Reset is off, the Data is Valid, and it's a new cycle
    if (!rst && Valid) begin
        $display("Time: %0t ns | OUT_PORT: %d (Hex: 0x%h)", $time, OUT_Port, OUT_Port);
    end
end

endmodule