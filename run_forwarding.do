# Clean previous compilation
if {[file exists work]} {
    vdel -all
}

# Create working library
vlib work

# Compile all files
vlog -f sourcefile.txt

# Start simulation
vsim -voptargs=+acc work.Processor_TB_Forwarding

# Configure wave window
add wave -divider "Clock & Control"
add wave -color "Yellow" /Processor_TB_Forwarding/clk
add wave -color "Red" /Processor_TB_Forwarding/rst
add wave -color "Orange" /Processor_TB_Forwarding/Interrupt

add wave -divider "Program Counter"
add wave -radix hexadecimal /Processor_TB_Forwarding/PC_Debug
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/PC_Current
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/PC_Next_Calculated
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/ID_Stall
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/EX_MemRead
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/CU/current_state

add wave -divider "Pipeline Stages - Opcodes"
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/ID_Opcode
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/EX_Opcode
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/IF_ID/Opcode
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/Instruction_Bus

add wave -divider "Forwarding Debug"
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/ID_src1
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/ID_src2
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/EX_RegWrite
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/EX_dist
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/EX_Is_2Byte
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/MEM_RegWrite
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/MEM_dist
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/WB_RegWrite
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/WB_dist
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/ID_no_forward_one
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/ID_no_forward_two
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/Forward_A
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/Forward_B
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/MEM_Forwarding_Data
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/Forwarded_Data_A
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/Forwarded_Data_B

add wave -divider "=== STACK MEMORY ==="
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/UnifiedMem/mem(253)
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/UnifiedMem/mem(254)
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/UnifiedMem/mem(255)

add wave -divider "Register File"
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/RF/Registers(0)
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/RF/Registers(1)
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/RF/Registers(2)
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/RF/Registers(3)

add wave -divider "ID Stage - Register Reads"
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/ID_Read_Data_1
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/ID_Read_Data_2
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/ID_Read_Reg_1
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/ID_Read_Reg_2

add wave -divider "EX Stage - ALU"
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/EX_Read_Data_1
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/EX_Read_Data_2
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/EX_ALU_Operand_B
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/EX_ALU_Src
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/EX_ALU_Result
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/EX_ALU_Op
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/EX_Ra
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/EX_Data_In

add wave -divider "MEM Stage"
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/MEM_ALU_Result
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/MEM_Data_Out
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/MEM_dist
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/MEM_Final_Address
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/MEM_Data_In
add wave /Processor_TB_Forwarding/uut/MEM_MemWrite
add wave /Processor_TB_Forwarding/uut/MEM_MemRead

add wave -divider "WB Stage"
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/WB_Final_Write_Data
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/WB_dist
add wave /Processor_TB_Forwarding/uut/WB_RegWrite
add wave -radix hexadecimal /Processor_TB_Forwarding/Result_Debug

add wave -divider "Control Signals"
add wave /Processor_TB_Forwarding/uut/ID_RegWrite
add wave /Processor_TB_Forwarding/uut/EX_RegWrite
add wave /Processor_TB_Forwarding/uut/MEM_RegWrite
add wave /Processor_TB_Forwarding/uut/WB_RegWrite

add wave -divider "Forwarding Detection Points"
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/EX_dist
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/MEM_dist
add wave -radix hexadecimal /Processor_TB_Forwarding/uut/WB_dist

add wave -divider "Test Status"
add wave -radix unsigned /Processor_TB_Forwarding/test_num
add wave -radix unsigned /Processor_TB_Forwarding/passed_tests
add wave -radix unsigned /Processor_TB_Forwarding/failed_tests

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