# Clean previous compilation
if {[file exists work]} {
    vdel -all
}

# Create working library
vlib work

# Compile all source files
vlog -f sourcefile.txt

# Start simulation with optimizations disabled for debugging
# vsim -voptargs=+acc work.Hazard_Unit_TB
vsim -voptargs=+acc work.Processor_TB

# Configure wave window
add wave -divider "Clock & Reset"
add wave -color "Yellow" /Processor_TB/clk
add wave -color "Red" /Processor_TB/rst
add wave -color "Orange" /Processor_TB/Interrupt

add wave -divider "Program Counter"
add wave -radix hexadecimal /Processor_TB/PC_Debug
add wave -radix hexadecimal /Processor_TB/test_num
add wave -radix hexadecimal /Processor_TB/uut/PC_Current
add wave -radix hexadecimal /Processor_TB/uut/PC_Next_Calculated
add wave -radix hexadecimal /Processor_TB/uut/ID_Stall
add wave -radix hexadecimal /Processor_TB/uut/PCSrc_sel

add wave -divider "Instruction Fetch"
add wave -radix hexadecimal /Processor_TB/uut/Instruction_Bus
add wave -radix hexadecimal /Processor_TB/uut/ID_Opcode
add wave -radix hexadecimal /Processor_TB/uut/ID_Read_Reg_1
add wave -radix hexadecimal /Processor_TB/uut/ID_Read_Reg_2

add wave -divider "Instruction Memory (First 16 Bytes)"
add wave -radix hexadecimal /Processor_TB/uut/UnifiedMem/mem(0)
add wave -radix hexadecimal /Processor_TB/uut/UnifiedMem/mem(1)
add wave -radix hexadecimal /Processor_TB/uut/UnifiedMem/mem(2)
add wave -radix hexadecimal /Processor_TB/uut/UnifiedMem/mem(3)
add wave -radix hexadecimal /Processor_TB/uut/UnifiedMem/mem(4)
add wave -radix hexadecimal /Processor_TB/uut/UnifiedMem/mem(5)
add wave -radix hexadecimal /Processor_TB/uut/UnifiedMem/mem(6)
add wave -radix hexadecimal /Processor_TB/uut/UnifiedMem/mem(7)
add wave -radix hexadecimal /Processor_TB/uut/UnifiedMem/mem(8)
add wave -radix hexadecimal /Processor_TB/uut/UnifiedMem/mem(9)
add wave -radix hexadecimal /Processor_TB/uut/UnifiedMem/mem(10)
add wave -radix hexadecimal /Processor_TB/uut/UnifiedMem/mem(11)
add wave -radix hexadecimal /Processor_TB/uut/UnifiedMem/mem(12)
add wave -radix hexadecimal /Processor_TB/uut/UnifiedMem/mem(13)
add wave -radix hexadecimal /Processor_TB/uut/UnifiedMem/mem(14)
add wave -radix hexadecimal /Processor_TB/uut/UnifiedMem/mem(15)

add wave -divider "Register File"
add wave -radix hexadecimal /Processor_TB/uut/RF/Registers(0)
add wave -radix hexadecimal /Processor_TB/uut/RF/Registers(1)
add wave -radix hexadecimal /Processor_TB/uut/RF/Registers(2)
add wave -radix hexadecimal /Processor_TB/uut/RF/Registers(3)

add wave -divider "Control Signals"
add wave /Processor_TB/uut/ID_RegWrite
add wave /Processor_TB/uut/ID_ALU_Src
add wave /Processor_TB/uut/ID_MemWrite
add wave /Processor_TB/uut/ID_MemRead
add wave /Processor_TB/uut/ID_MemToReg
add wave -radix binary /Processor_TB/uut/ID_StackOp
add wave /Processor_TB/uut/ID_Is_2Byte

add wave -divider "ALU Stage"
add wave -radix hexadecimal /Processor_TB/uut/EX_Read_Data_1
add wave -radix hexadecimal /Processor_TB/uut/EX_Read_Data_2
add wave -radix hexadecimal /Processor_TB/uut/EX_Imm
add wave -radix hexadecimal /Processor_TB/uut/EX_ALU_Operand_B
add wave -radix hexadecimal /Processor_TB/uut/EX_ALU_Result
add wave -radix hexadecimal /Processor_TB/uut/EX_CCR_Out
add wave -radix hexadecimal /Processor_TB/uut/EX_Opcode

add wave -divider "Flags (CCR)"
add wave /Processor_TB/uut/Flags_Reg/ccr_regs(3)
add wave /Processor_TB/uut/Flags_Reg/ccr_regs(2)
add wave /Processor_TB/uut/Flags_Reg/ccr_regs(1)
add wave /Processor_TB/uut/Flags_Reg/ccr_regs(0)

add wave -divider "Memory Stage"
add wave -radix hexadecimal /Processor_TB/uut/MEM_Final_Address
add wave -radix hexadecimal /Processor_TB/uut/MEM_Data_In
add wave -radix hexadecimal /Processor_TB/uut/MEM_Data_Out
add wave /Processor_TB/uut/MEM_MemWrite
add wave /Processor_TB/uut/MEM_MemRead
add wave -radix binary /Processor_TB/uut/MEM_StackOp

add wave -divider "Write Back Stage"
add wave -radix hexadecimal /Processor_TB/uut/WB_Final_Write_Data
add wave -radix hexadecimal /Processor_TB/Result_Debug
add wave -radix hexadecimal /Processor_TB/uut/WB_dist
add wave /Processor_TB/uut/WB_RegWrite

add wave -divider "Stack Pointer"
add wave -radix hexadecimal /Processor_TB/uut/ID_SP_Value
add wave -radix hexadecimal /Processor_TB/uut/MEM_SP_Value
add wave -radix hexadecimal /Processor_TB/uut/MEM_SP_Calc_Address
add wave /Processor_TB/uut/MEM_Is_Push
add wave /Processor_TB/uut/MEM_Is_Pop
add wave /Processor_TB/uut/ID_output_valid
add wave /Processor_TB/uut/Valid
add wave /Processor_TB/uut/OUT_Port

add wave -divider "Stack Memory (Top 5)"
add wave -radix hexadecimal /Processor_TB/uut/UnifiedMem/mem(255)
add wave -radix hexadecimal /Processor_TB/uut/UnifiedMem/mem(254)
add wave -radix hexadecimal /Processor_TB/uut/UnifiedMem/mem(253)
add wave -radix hexadecimal /Processor_TB/uut/UnifiedMem/mem(252)
add wave -radix hexadecimal /Processor_TB/uut/UnifiedMem/mem(251)

add wave -divider "Pipeline Registers"
add wave -radix hexadecimal /Processor_TB/uut/IF_ID/Opcode
add wave -radix hexadecimal /Processor_TB/uut/ID_EX/Opcode_out
add wave -radix hexadecimal /Processor_TB/uut/EX_MEM/alu_res_out

# Configure wave window display
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

# Run simulation
run -all

# Zoom to fit
wave zoom full