# Clean previous compilation
if {[file exists work]} {
    vdel -all
}

# Create working library
vlib work

# Compile all files
vlog -f sourcefile.txt

# Start simulation
vsim -voptargs=+acc work.Processor_TB_Interrupt

# Configure wave window
add wave -divider "Clock & Interrupt Control"
add wave -color "Yellow" /Processor_TB_Interrupt/clk
add wave -color "Red" /Processor_TB_Interrupt/rst
add wave -color "Magenta" /Processor_TB_Interrupt/Interrupt

add wave -divider "Program Counter"
add wave -radix hexadecimal /Processor_TB_Interrupt/PC_Debug
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/PC_Current
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/PC_Next_Calculated
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/PCSrc_sel

add wave -divider "Interrupt Handling Signals"
add wave /Processor_TB_Interrupt/uut/ID_copy_CCR
add wave /Processor_TB_Interrupt/uut/ID_paste_CCR
add wave /Processor_TB_Interrupt/uut/ID_Flush
add wave -radix binary /Processor_TB_Interrupt/uut/CU/current_state
add wave -radix binary /Processor_TB_Interrupt/uut/CU/next_state

add wave -divider "Instruction Flow"
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/Instruction_Bus
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/ID_Opcode
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/EX_Opcode

add wave -divider "Register File"
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/RF/Registers(0)
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/RF/Registers(1)
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/RF/Registers(2)
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/RF/Registers(3)

add wave -divider "ALU Stage"
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/EX_Read_Data_1
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/EX_Read_Data_2
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/EX_Imm
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/EX_ALU_Operand_B
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/EX_ALU_Result
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/EX_CCR_Out
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/EX_Opcode

add wave -divider "Condition Flags"
add wave -radix binary /Processor_TB_Interrupt/uut/Flags_Reg/ccr_regs(7:4)
add wave -radix binary /Processor_TB_Interrupt/uut/Flags_Reg/ccr_regs(3:0)
add wave /Processor_TB_Interrupt/uut/Flags_Reg/ccr_regs(3)
add wave /Processor_TB_Interrupt/uut/Flags_Reg/ccr_regs(2)
add wave /Processor_TB_Interrupt/uut/Flags_Reg/ccr_regs(1)
add wave /Processor_TB_Interrupt/uut/Flags_Reg/ccr_regs(0)

add wave -divider "Stack Memory (Top 8 locations)"
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/UnifiedMem/mem(0)
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/UnifiedMem/mem(1)
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/UnifiedMem/mem(2)
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/UnifiedMem/mem(3)
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/UnifiedMem/mem(4)
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/UnifiedMem/mem(5)
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/UnifiedMem/mem(6)
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/UnifiedMem/mem(7)

add wave -divider "Stack Pointer & Stack Operations"
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/ID_SP_Value
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/MEM_SP_Value
add wave -radix binary /Processor_TB_Interrupt/uut/MEM_StackOp
add wave /Processor_TB_Interrupt/uut/ID_write_SP
add wave /Processor_TB_Interrupt/uut/MEM_Is_Push
add wave /Processor_TB_Interrupt/uut/MEM_Is_Pop

add wave -divider "Stack Memory (Top 8 locations)"
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/UnifiedMem/mem(255)
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/UnifiedMem/mem(254)
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/UnifiedMem/mem(253)
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/UnifiedMem/mem(252)
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/UnifiedMem/mem(251)
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/UnifiedMem/mem(250)
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/UnifiedMem/mem(249)
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/UnifiedMem/mem(248)

add wave -divider "Interrupt Vector & ISR"
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/UnifiedMem/mem(0)
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/UnifiedMem/mem(1)

add wave -divider "Memory Operations"
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/MEM_Final_Address
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/MEM_Data_In
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/MEM_Data_Out
add wave /Processor_TB_Interrupt/uut/MEM_MemWrite
add wave /Processor_TB_Interrupt/uut/MEM_MemRead

add wave -divider "Data Path Mux Selection"
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/ID_Mem_Data_Src
add wave -radix hexadecimal /Processor_TB_Interrupt/uut/ID_Data_In_Mux_Out

add wave -divider "Test Status"
add wave -radix unsigned /Processor_TB_Interrupt/test_num
add wave -radix unsigned /Processor_TB_Interrupt/passed_tests
add wave -radix unsigned /Processor_TB_Interrupt/failed_tests

# Configure wave display
configure wave -namecolwidth 350
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