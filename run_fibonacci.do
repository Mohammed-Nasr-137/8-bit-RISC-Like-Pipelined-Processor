# 1. Compile all Verilog files
vlog *.v

# 2. Start Simulation
vsim -voptargs=+acc work.Processor_Top_TB

# 3. Clear existing waves
delete wave *

# -----------------------------------------------------------
# GROUP 1: Top Level Interface
# -----------------------------------------------------------
add wave -noupdate -group "Top Level" -radix binary      /Processor_Top_TB/clk
add wave -noupdate -group "Top Level" -radix binary      /Processor_Top_TB/rst
add wave -noupdate -group "Top Level" -radix unsigned    /Processor_Top_TB/OUT_Port
add wave -noupdate -group "Top Level" -radix binary      /Processor_Top_TB/Valid
add wave -noupdate -group "Top Level" -radix hexadecimal /Processor_Top_TB/PC_Debug

# -----------------------------------------------------------
# GROUP 2: Register File (CRITICAL FOR DEBUGGING)
# -----------------------------------------------------------
# Monitoring R0 (Counter), R1 (n-2), R2 (n-1), R3 (Result/Loop Target)
add wave -noupdate -group "Registers" -radix unsigned    /Processor_Top_TB/dut/RF/Registers(0)
add wave -noupdate -group "Registers" -radix unsigned    /Processor_Top_TB/dut/RF/Registers(1)
add wave -noupdate -group "Registers" -radix unsigned    /Processor_Top_TB/dut/RF/Registers(2)
add wave -noupdate -group "Registers" -radix unsigned    /Processor_Top_TB/dut/RF/Registers(3)
add wave -noupdate -group "Registers" -radix binary      /Processor_Top_TB/dut/RF/RegWrite
add wave -noupdate -group "Registers" -radix hexadecimal /Processor_Top_TB/dut/RF/Write_Data

# -----------------------------------------------------------
# GROUP 3: Pipeline Stages
# -----------------------------------------------------------
add wave -noupdate -group "Fetch" -radix hexadecimal /Processor_Top_TB/dut/PC/PC_Out
add wave -noupdate -group "Fetch" -radix hexadecimal /Processor_Top_TB/dut/Instruction_Bus

add wave -noupdate -group "Execute" -radix hexadecimal /Processor_Top_TB/dut/Execution_Unit/Operand_A
add wave -noupdate -group "Execute" -radix hexadecimal /Processor_Top_TB/dut/Execution_Unit/Operand_B
add wave -noupdate -group "Execute" -radix hexadecimal /Processor_Top_TB/dut/Execution_Unit/Result
add wave -noupdate -group "Execute" -radix binary      /Processor_Top_TB/dut/Execution_Unit/CCR

# -----------------------------------------------------------
# GROUP 4: Memory Access
# -----------------------------------------------------------
add wave -noupdate -group "Memory" -radix hexadecimal /Processor_Top_TB/dut/UnifiedMem/Data_Address
add wave -noupdate -group "Memory" -radix hexadecimal /Processor_Top_TB/dut/UnifiedMem/Data_In
add wave -noupdate -group "Memory" -radix hexadecimal /Processor_Top_TB/dut/UnifiedMem/Data_Out
add wave -noupdate -group "Memory" -radix binary      /Processor_Top_TB/dut/UnifiedMem/MemWrite

# 4. Configure & Run
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
run -all