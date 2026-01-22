# Clean previous compilation
if {[file exists work]} {
    vdel -all
}

# Create working library
vlib work

# Compile all files
vlog -f sourcefile.txt

# Start simulation
vsim -voptargs=+acc work.Processor_TB_BFormat

# Configure wave window
add wave -divider "Clock & Control"
add wave -color "Yellow" /Processor_TB_BFormat/clk
add wave -color "Red" /Processor_TB_BFormat/rst
add wave -color "Orange" /Processor_TB_BFormat/Interrupt

add wave -divider "Program Counter & Branch"
add wave -radix hexadecimal /Processor_TB_BFormat/PC_Debug
add wave -radix hexadecimal /Processor_TB_BFormat/uut/PC_Current
add wave -radix hexadecimal /Processor_TB_BFormat/uut/PC_Next_Calculated
add wave -radix hexadecimal /Processor_TB_BFormat/uut/PCSrc_sel
add wave /Processor_TB_BFormat/uut/ID_Branch
add wave /Processor_TB_BFormat/uut/ID_Flush
add wave /Processor_TB_BFormat/uut/ID_EX/Zero_Flag

add wave -divider "Instruction Decode"
add wave -radix hexadecimal /Processor_TB_BFormat/uut/EX_SP_Value
add wave -radix hexadecimal /Processor_TB_BFormat/uut/Mem_inst_src_addr
add wave -radix hexadecimal /Processor_TB_BFormat/uut/Instruction_Bus
add wave -radix hexadecimal /Processor_TB_BFormat/uut/MEM_SP_Value
add wave -radix hexadecimal /Processor_TB_BFormat/uut/MEM_Next_SP
add wave -radix hexadecimal /Processor_TB_BFormat/uut/ID_Opcode
add wave -radix hexadecimal /Processor_TB_BFormat/uut/ID_Read_Reg_1
add wave -radix hexadecimal /Processor_TB_BFormat/uut/ID_Read_Reg_2
add wave -radix hexadecimal /Processor_TB_BFormat/uut/ID_Data_In_Mux_Out
add wave -radix hexadecimal /Processor_TB_BFormat/uut/ID_Mem_Data_Src

add wave -divider "Register File"
add wave -radix hexadecimal /Processor_TB_BFormat/uut/RF/Registers(0)
add wave -radix hexadecimal /Processor_TB_BFormat/uut/RF/Registers(1)
add wave -radix hexadecimal /Processor_TB_BFormat/uut/RF/Registers(2)
add wave -radix hexadecimal /Processor_TB_BFormat/uut/RF/Registers(3)
add wave /Processor_TB_BFormat/uut/ID_SP_Value
add wave /Processor_TB_BFormat/uut/ID_StackOp

add wave -divider "Condition Flags (CCR)"
add wave /Processor_TB_BFormat/uut/Flags_Reg/ccr_regs(3)
add wave /Processor_TB_BFormat/uut/Flags_Reg/ccr_regs(2)
add wave /Processor_TB_BFormat/uut/Flags_Reg/ccr_regs(1)
add wave /Processor_TB_BFormat/uut/Flags_Reg/ccr_regs(0)

add wave -divider "Branch Control"
add wave -radix hexadecimal /Processor_TB_BFormat/uut/EX_Opcode
add wave -radix hexadecimal /Processor_TB_BFormat/uut/EX_Ra
add wave /Processor_TB_BFormat/uut/EX_Flush

add wave /Processor_TB_BFormat/uut/EX_Branch

add wave -divider "Stack Operations (for CALL/RET)"
add wave -radix hexadecimal /Processor_TB_BFormat/uut/ID_SP_Value
add wave -radix hexadecimal /Processor_TB_BFormat/uut/MEM_SP_Value
add wave -radix binary /Processor_TB_BFormat/uut/MEM_StackOp
add wave /Processor_TB_BFormat/uut/MEM_Final_Address
add wave /Processor_TB_BFormat/uut/MEM_StackOp_Active
add wave /Processor_TB_BFormat/uut/MEM_MemWrite
add wave /Processor_TB_BFormat/uut/MEM_MemRead
add wave /Processor_TB_BFormat/uut/MEM_Data_In
add wave /Processor_TB_BFormat/uut/MEM_Data_Out

add wave -divider "Stack Memory (Top 5)"
add wave -radix hexadecimal /Processor_TB_BFormat/uut/UnifiedMem/mem(255)
add wave -radix hexadecimal /Processor_TB_BFormat/uut/UnifiedMem/mem(254)
add wave -radix hexadecimal /Processor_TB_BFormat/uut/UnifiedMem/mem(253)
add wave -radix hexadecimal /Processor_TB_BFormat/uut/UnifiedMem/mem(252)
add wave -radix hexadecimal /Processor_TB_BFormat/uut/UnifiedMem/mem(251)

add wave -divider "ALU Results"
add wave -radix hexadecimal /Processor_TB_BFormat/uut/EX_ALU_Result
add wave -radix hexadecimal /Processor_TB_BFormat/uut/EX_Read_Data_1
add wave -radix hexadecimal /Processor_TB_BFormat/uut/EX_Read_Data_2
add wave -radix hexadecimal /Processor_TB_BFormat/uut/EX_CCR_Out
add wave -radix hexadecimal /Processor_TB_BFormat/uut/EX_Opcode
add wave -radix hexadecimal /Processor_TB_BFormat/uut/EX_ALU_Op

add wave -divider "Control Unit State"
add wave -radix binary /Processor_TB_BFormat/uut/CU/current_state
add wave -radix binary /Processor_TB_BFormat/uut/CU/next_state

add wave -divider "Test Status"
add wave -radix unsigned /Processor_TB_BFormat/test_num
add wave -radix unsigned /Processor_TB_BFormat/passed_tests
add wave -radix unsigned /Processor_TB_BFormat/failed_tests

# Configure wave display
configure wave -namecolwidth 300
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