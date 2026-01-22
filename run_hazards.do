# Clean previous compilation
if {[file exists work]} {
    vdel -all
}

# Create working library
vlib work

# Compile all files
vlog -f sourcefile.txt

# Start simulation
vsim -voptargs=+acc work.Processor_TB_Hazards

# Configure wave window
add wave -divider "=== CLOCK & CONTROL ==="
add wave -color "Yellow" /Processor_TB_Hazards/clk
add wave -color "Red" /Processor_TB_Hazards/rst
add wave -radix unsigned /Processor_TB_Hazards/cycle_count

add wave -divider "=== PROGRAM COUNTER ==="
add wave -radix hexadecimal /Processor_TB_Hazards/PC_Debug
add wave -radix hexadecimal /Processor_TB_Hazards/uut/PC_Current
add wave -radix hexadecimal /Processor_TB_Hazards/uut/PC_Next_Calculated
add wave -radix hexadecimal /Processor_TB_Hazards/uut/ID_Stall

add wave -divider "=== IF STAGE - INSTRUCTION FETCH ==="
add wave -radix hexadecimal /Processor_TB_Hazards/uut/Instruction_Bus
add wave -radix hexadecimal /Processor_TB_Hazards/uut/UnifiedMem/mem(0)
add wave -radix hexadecimal /Processor_TB_Hazards/uut/UnifiedMem/mem(1)
add wave -radix hexadecimal /Processor_TB_Hazards/uut/UnifiedMem/mem(2)
add wave -radix hexadecimal /Processor_TB_Hazards/uut/UnifiedMem/mem(3)

add wave -divider "=== ID STAGE - DECODE & READ ==="
add wave -radix hexadecimal /Processor_TB_Hazards/uut/ID_Opcode
add wave -radix hexadecimal /Processor_TB_Hazards/uut/ID_Read_Reg_1
add wave -radix hexadecimal /Processor_TB_Hazards/uut/ID_Read_Reg_2
add wave -radix hexadecimal /Processor_TB_Hazards/uut/ID_Read_Data_1
add wave -radix hexadecimal /Processor_TB_Hazards/uut/ID_Read_Data_2

add wave -divider "=== EX STAGE - EXECUTE ==="
add wave -radix hexadecimal /Processor_TB_Hazards/uut/EX_Opcode
add wave -radix hexadecimal /Processor_TB_Hazards/uut/EX_Ra
add wave -radix hexadecimal /Processor_TB_Hazards/uut/EX_dist
add wave -radix hexadecimal /Processor_TB_Hazards/uut/EX_Read_Data_1
add wave -radix hexadecimal /Processor_TB_Hazards/uut/EX_Read_Data_2
add wave -radix hexadecimal /Processor_TB_Hazards/uut/EX_ALU_Result
add wave /Processor_TB_Hazards/uut/EX_RegWrite

add wave -divider "=== MEM STAGE - MEMORY ACCESS ==="
add wave -radix hexadecimal /Processor_TB_Hazards/uut/MEM_ALU_Result
add wave -radix hexadecimal /Processor_TB_Hazards/uut/MEM_dist
add wave -radix hexadecimal /Processor_TB_Hazards/uut/MEM_Final_Address
add wave -radix hexadecimal /Processor_TB_Hazards/uut/MEM_Data_In
add wave -radix hexadecimal /Processor_TB_Hazards/uut/MEM_Data_Out
add wave /Processor_TB_Hazards/uut/MEM_MemWrite
add wave /Processor_TB_Hazards/uut/MEM_MemRead
add wave /Processor_TB_Hazards/uut/MEM_RegWrite

add wave -divider "=== WB STAGE - WRITE BACK ==="
add wave -radix hexadecimal /Processor_TB_Hazards/uut/WB_dist
add wave -radix hexadecimal /Processor_TB_Hazards/uut/WB_Final_Write_Data
add wave -radix hexadecimal /Processor_TB_Hazards/uut/WB_ALU_Result
add wave -radix hexadecimal /Processor_TB_Hazards/uut/WB_Data_Out
add wave /Processor_TB_Hazards/uut/WB_MemToReg
add wave /Processor_TB_Hazards/uut/WB_RegWrite

add wave -divider "=== REGISTER FILE - HAZARD DETECTION ==="
add wave -radix hexadecimal /Processor_TB_Hazards/uut/RF/Registers(0)
add wave -radix hexadecimal /Processor_TB_Hazards/uut/RF/Registers(1)
add wave -radix hexadecimal /Processor_TB_Hazards/uut/RF/Registers(2)
add wave -radix hexadecimal /Processor_TB_Hazards/uut/RF/Registers(3)
add wave -radix hexadecimal /Processor_TB_Hazards/uut/RF/Read_Reg_1
add wave -radix hexadecimal /Processor_TB_Hazards/uut/RF/Read_Reg_2
add wave -radix hexadecimal /Processor_TB_Hazards/uut/RF/Write_Reg
add wave /Processor_TB_Hazards/uut/RF/RegWrite

add wave -divider "=== HAZARD DETECTION SIGNALS ==="
# Note: These signals would be in your Hazard Detection Unit if implemented
# For now, we monitor the destination registers to detect conflicts
add wave -label "ID_Ra (Source1)" -radix hexadecimal /Processor_TB_Hazards/uut/ID_Read_Reg_1
add wave -label "ID_Rb (Source2)" -radix hexadecimal /Processor_TB_Hazards/uut/ID_Read_Reg_2
add wave -label "EX_Dest" -radix hexadecimal /Processor_TB_Hazards/uut/EX_dist
add wave -label "MEM_Dest" -radix hexadecimal /Processor_TB_Hazards/uut/MEM_dist
add wave -label "WB_Dest" -radix hexadecimal /Processor_TB_Hazards/uut/WB_dist
add wave -label "EX_Write?" /Processor_TB_Hazards/uut/EX_RegWrite
add wave -label "MEM_Write?" /Processor_TB_Hazards/uut/MEM_RegWrite
add wave -label "WB_Write?" /Processor_TB_Hazards/uut/WB_RegWrite


add wave -divider "=== CONTROL HAZARD DETECTION ==="
add wave /Processor_TB_Hazards/uut/ID_Branch
add wave /Processor_TB_Hazards/uut/EX_Branch
add wave /Processor_TB_Hazards/uut/ID_Flush

add wave -divider "=== FLAGS (CCR) ==="
add wave /Processor_TB_Hazards/uut/Flags_Reg/ccr_regs(3)
add wave /Processor_TB_Hazards/uut/Flags_Reg/ccr_regs(2)
add wave /Processor_TB_Hazards/uut/Flags_Reg/ccr_regs(1)
add wave /Processor_TB_Hazards/uut/Flags_Reg/ccr_regs(0)

add wave -divider "=== DATA MEMORY SAMPLE ==="
add wave -radix hexadecimal /Processor_TB_Hazards/uut/UnifiedMem/mem(80)
add wave -radix hexadecimal /Processor_TB_Hazards/uut/UnifiedMem/mem(96)
add wave -radix hexadecimal /Processor_TB_Hazards/uut/UnifiedMem/mem(112)
add wave -radix hexadecimal /Processor_TB_Hazards/uut/UnifiedMem/mem(160)
add wave -radix hexadecimal /Processor_TB_Hazards/uut/UnifiedMem/mem(176)

add wave -divider "=== STACK MEMORY ==="
add wave -radix hexadecimal /Processor_TB_Hazards/uut/UnifiedMem/mem(255)
add wave -radix hexadecimal /Processor_TB_Hazards/uut/UnifiedMem/mem(254)
add wave -radix hexadecimal /Processor_TB_Hazards/uut/UnifiedMem/mem(253)

add wave -divider "=== TEST STATUS ==="
add wave -radix unsigned /Processor_TB_Hazards/test_num
add wave -radix unsigned /Processor_TB_Hazards/passed_tests
add wave -radix unsigned /Processor_TB_Hazards/failed_tests



# Add color coding for hazard signals
configure wave -timeline 0
configure wave -timelineunits ns

# Run simulation
run -all

# Zoom to fit
wave zoom full

# Add markers for key hazard detection points
# (You can manually add these during simulation review)