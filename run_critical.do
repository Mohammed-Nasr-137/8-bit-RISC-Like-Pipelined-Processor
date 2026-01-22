# ============================================================================
# CRITICAL EDGE CASE TESTBENCH - DO FILE
# ============================================================================
# Clean previous compilation
if {[file exists work]} {
    vdel -all
}

# Create working library
vlib work

# Compile all files
vlog -f sourcefile.txt

# Start simulation
vsim -voptargs=+acc work.Processor_TB_Critical

# Configure wave window with organized hierarchy
add wave -divider "========== CLOCK & CONTROL =========="
add wave -color "Yellow" /Processor_TB_Critical/clk
add wave -color "Red" /Processor_TB_Critical/rst
add wave -color "Orange" /Processor_TB_Critical/Interrupt

add wave -divider "========== TEST STATUS =========="
add wave -radix unsigned /Processor_TB_Critical/test_num
add wave -radix unsigned /Processor_TB_Critical/passed_tests
add wave -radix unsigned /Processor_TB_Critical/failed_tests

add wave -divider "========== PROGRAM COUNTER =========="
add wave -radix hexadecimal /Processor_TB_Critical/PC_Debug
add wave -radix hexadecimal /Processor_TB_Critical/uut/PC_Current
add wave -radix hexadecimal /Processor_TB_Critical/uut/PC_Next_Calculated
add wave -radix hexadecimal /Processor_TB_Critical/uut/PC_PLUS_1
add wave -radix hexadecimal /Processor_TB_Critical/uut/PCSrc_sel
add wave -radix hexadecimal /Processor_TB_Critical/uut/inst_mem_src

add wave -divider "========== HAZARD DETECTION =========="
add wave -color "Cyan" /Processor_TB_Critical/uut/ID_Stall
add wave -radix hexadecimal /Processor_TB_Critical/uut/EX_MemRead
add wave -radix hexadecimal /Processor_TB_Critical/uut/ID_Read_Reg_1
add wave -radix hexadecimal /Processor_TB_Critical/uut/ID_Read_Reg_2
add wave -radix hexadecimal /Processor_TB_Critical/uut/EX_dist

add wave -divider "========== FORWARDING UNIT =========="
add wave -color "Magenta" -radix binary /Processor_TB_Critical/uut/Forward_A
add wave -color "Magenta" -radix binary /Processor_TB_Critical/uut/Forward_B
add wave -radix hexadecimal /Processor_TB_Critical/uut/ID_src1
add wave -radix hexadecimal /Processor_TB_Critical/uut/ID_src2
add wave /Processor_TB_Critical/uut/ID_no_forward_one
add wave /Processor_TB_Critical/uut/ID_no_forward_two
add wave -radix hexadecimal /Processor_TB_Critical/uut/Forwarded_Data_A
add wave -radix hexadecimal /Processor_TB_Critical/uut/Forwarded_Data_B
add wave -radix hexadecimal /Processor_TB_Critical/uut/MEM_Forwarding_Data

add wave -divider "========== IF STAGE =========="
add wave -radix hexadecimal /Processor_TB_Critical/uut/Instruction_Bus
add wave -radix hexadecimal /Processor_TB_Critical/uut/Mem_inst_src_addr

add wave -divider "========== ID STAGE =========="
add wave -radix hexadecimal /Processor_TB_Critical/uut/ID_Opcode
add wave -radix hexadecimal /Processor_TB_Critical/uut/ID_Read_Reg_1
add wave -radix hexadecimal /Processor_TB_Critical/uut/ID_Read_Reg_2
add wave -radix hexadecimal /Processor_TB_Critical/uut/ID_Read_Data_1
add wave -radix hexadecimal /Processor_TB_Critical/uut/ID_Read_Data_2
add wave -radix hexadecimal /Processor_TB_Critical/uut/ID_dist
add wave /Processor_TB_Critical/uut/ID_RegWrite
add wave /Processor_TB_Critical/uut/ID_Branch
add wave /Processor_TB_Critical/uut/ID_Flush
add wave /Processor_TB_Critical/uut/ID_Is_2Byte

add wave -divider "========== EX STAGE =========="
add wave -radix hexadecimal /Processor_TB_Critical/uut/EX_Opcode
add wave -radix hexadecimal /Processor_TB_Critical/uut/EX_Ra
add wave -radix hexadecimal /Processor_TB_Critical/uut/EX_Rb
add wave -radix hexadecimal /Processor_TB_Critical/uut/EX_dist
add wave -radix hexadecimal /Processor_TB_Critical/uut/EX_Read_Data_1
add wave -radix hexadecimal /Processor_TB_Critical/uut/EX_Read_Data_2
add wave -radix hexadecimal /Processor_TB_Critical/uut/EX_ALU_Operand_B
add wave -radix hexadecimal /Processor_TB_Critical/uut/EX_ALU_Result
add wave -radix hexadecimal /Processor_TB_Critical/uut/EX_ALU_Op
add wave /Processor_TB_Critical/uut/EX_RegWrite
add wave /Processor_TB_Critical/uut/EX_Is_2Byte

add wave -divider "========== MEM STAGE =========="
add wave -radix hexadecimal /Processor_TB_Critical/uut/MEM_ALU_Result
add wave -radix hexadecimal /Processor_TB_Critical/uut/MEM_dist
add wave -radix hexadecimal /Processor_TB_Critical/uut/MEM_Final_Address
add wave -radix hexadecimal /Processor_TB_Critical/uut/MEM_Data_In
add wave -radix hexadecimal /Processor_TB_Critical/uut/MEM_Data_Out
add wave /Processor_TB_Critical/uut/MEM_MemWrite
add wave /Processor_TB_Critical/uut/MEM_MemRead
add wave /Processor_TB_Critical/uut/MEM_RegWrite
add wave /Processor_TB_Critical/uut/MEM_Is_2Byte
add wave -radix binary /Processor_TB_Critical/uut/MEM_StackOp
add wave /Processor_TB_Critical/uut/MEM_StackOp_Active

add wave -divider "========== WB STAGE =========="
add wave -radix hexadecimal /Processor_TB_Critical/uut/WB_dist
add wave -radix hexadecimal /Processor_TB_Critical/uut/WB_Final_Write_Data
add wave -radix hexadecimal /Processor_TB_Critical/uut/WB_ALU_Result
add wave -radix hexadecimal /Processor_TB_Critical/uut/WB_Data_Out
add wave /Processor_TB_Critical/uut/WB_MemToReg
add wave /Processor_TB_Critical/uut/WB_RegWrite
add wave /Processor_TB_Critical/uut/WB_Is_2Byte

add wave -divider "========== REGISTER FILE =========="
add wave -radix hexadecimal /Processor_TB_Critical/uut/RF/Registers(0)
add wave -radix hexadecimal /Processor_TB_Critical/uut/RF/Registers(1)
add wave -radix hexadecimal /Processor_TB_Critical/uut/RF/Registers(2)
add wave -radix hexadecimal /Processor_TB_Critical/uut/RF/Registers(3)
add wave /Processor_TB_Critical/uut/RF/RegWrite
add wave -radix hexadecimal /Processor_TB_Critical/uut/RF/Write_Reg
add wave -radix hexadecimal /Processor_TB_Critical/uut/RF/Write_Data

add wave -divider "========== CONDITION FLAGS (CCR) =========="
add wave -color "Green" /Processor_TB_Critical/uut/Flags_Reg/ccr_regs(3)
add wave -color "Green" /Processor_TB_Critical/uut/Flags_Reg/ccr_regs(2)
add wave -color "Green" /Processor_TB_Critical/uut/Flags_Reg/ccr_regs(1)
add wave -color "Green" /Processor_TB_Critical/uut/Flags_Reg/ccr_regs(0)
add wave -radix hexadecimal /Processor_TB_Critical/uut/Flags_Reg/ccr_regs
add wave /Processor_TB_Critical/uut/EX_copy_CCR
add wave /Processor_TB_Critical/uut/EX_paste_CCR

add wave -divider "========== STACK POINTER =========="
add wave -radix hexadecimal /Processor_TB_Critical/uut/ID_SP_Value
add wave -radix hexadecimal /Processor_TB_Critical/uut/EX_SP_Value
add wave -radix hexadecimal /Processor_TB_Critical/uut/MEM_SP_Value
add wave -radix hexadecimal /Processor_TB_Critical/uut/MEM_Next_SP
add wave -radix hexadecimal /Processor_TB_Critical/uut/MEM_SP_Calc_Address
add wave /Processor_TB_Critical/uut/MEM_Is_Push
add wave /Processor_TB_Critical/uut/MEM_Is_Pop
add wave /Processor_TB_Critical/uut/ID_write_SP

add wave -divider "========== CONTROL UNIT STATE =========="
add wave -radix binary /Processor_TB_Critical/uut/CU/current_state
add wave -radix binary /Processor_TB_Critical/uut/CU/next_state
add wave -radix hexadecimal /Processor_TB_Critical/uut/CU/Opcode
add wave /Processor_TB_Critical/uut/CU/Stall
add wave /Processor_TB_Critical/uut/CU/Interrupt

add wave -divider "========== BRANCH CONTROL =========="
add wave /Processor_TB_Critical/uut/EX_Branch
add wave /Processor_TB_Critical/uut/EX_Flush
add wave -radix hexadecimal /Processor_TB_Critical/uut/BU/ID_EX_Opcode
add wave -radix hexadecimal /Processor_TB_Critical/uut/BU/ID_EX_Rs_Addr
add wave -radix binary /Processor_TB_Critical/uut/BU/CCR
add wave -radix binary /Processor_TB_Critical/uut/BU/PCSrc
add wave /Processor_TB_Critical/uut/BU/Branch_en

add wave -divider "========== INSTRUCTION MEMORY (Sample) =========="
add wave -radix hexadecimal /Processor_TB_Critical/uut/UnifiedMem/mem(0)
add wave -radix hexadecimal /Processor_TB_Critical/uut/UnifiedMem/mem(1)
add wave -radix hexadecimal /Processor_TB_Critical/uut/UnifiedMem/mem(2)
add wave -radix hexadecimal /Processor_TB_Critical/uut/UnifiedMem/mem(3)
add wave -radix hexadecimal /Processor_TB_Critical/uut/UnifiedMem/mem(4)
add wave -radix hexadecimal /Processor_TB_Critical/uut/UnifiedMem/mem(5)
add wave -radix hexadecimal /Processor_TB_Critical/uut/UnifiedMem/mem(6)
add wave -radix hexadecimal /Processor_TB_Critical/uut/UnifiedMem/mem(7)

add wave -divider "========== STACK MEMORY (Top 8) =========="
add wave -radix hexadecimal /Processor_TB_Critical/uut/UnifiedMem/mem(255)
add wave -radix hexadecimal /Processor_TB_Critical/uut/UnifiedMem/mem(254)
add wave -radix hexadecimal /Processor_TB_Critical/uut/UnifiedMem/mem(253)
add wave -radix hexadecimal /Processor_TB_Critical/uut/UnifiedMem/mem(252)
add wave -radix hexadecimal /Processor_TB_Critical/uut/UnifiedMem/mem(251)
add wave -radix hexadecimal /Processor_TB_Critical/uut/UnifiedMem/mem(250)
add wave -radix hexadecimal /Processor_TB_Critical/uut/UnifiedMem/mem(249)
add wave -radix hexadecimal /Processor_TB_Critical/uut/UnifiedMem/mem(248)

add wave -divider "========== DATA MEMORY (Sample) =========="
add wave -radix hexadecimal /Processor_TB_Critical/uut/UnifiedMem/mem(192)
add wave -radix hexadecimal /Processor_TB_Critical/uut/UnifiedMem/mem(200)
add wave -radix hexadecimal /Processor_TB_Critical/uut/UnifiedMem/mem(210)

add wave -divider "========== PIPELINE CONTROL =========="
add wave /Processor_TB_Critical/uut/IF_ID/Flush
add wave /Processor_TB_Critical/uut/IF_ID/load_en
add wave /Processor_TB_Critical/uut/ID_EX/Flush
add wave -radix hexadecimal /Processor_TB_Critical/uut/ID_EX/Opcode_out

add wave -divider "========== DEBUG OUTPUTS =========="
add wave -radix hexadecimal /Processor_TB_Critical/Result_Debug
add wave -radix hexadecimal /Processor_TB_Critical/OUT_Port

# Configure wave display settings
configure wave -namecolwidth 350
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns

# Run simulation
run -all

# Zoom to fit all waveforms
wave zoom full

# Print summary message
puts ""
puts "========================================================================"
puts "                CRITICAL TESTBENCH SIMULATION COMPLETE"
puts "========================================================================"
puts "Check the transcript for detailed test results."
puts "Use wave zoom and wave cursor to analyze specific sections."
puts "========================================================================"
puts ""