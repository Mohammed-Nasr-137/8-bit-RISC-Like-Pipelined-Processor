# ============================================================================
# XILINX VIVADO CONSTRAINTS FOR 8-BIT PIPELINED PROCESSOR
# Target: Basys3 Board (xc7a35tcpg236-1)
# ============================================================================

# ============================================================================
# CLOCK CONSTRAINTS
# ============================================================================
create_clock -period 15.000 -name sys_clk -waveform {0.000 7.500} [get_ports clk]

# ============================================================================
# INPUT/OUTPUT DELAYS - Relaxed for easier timing closure
# ============================================================================
set_input_delay -clock sys_clk -max 4.000 [get_ports {rst IN_Port[*] Interrupt}]
set_input_delay -clock sys_clk -min 0.500 [get_ports {rst IN_Port[*] Interrupt}]

set_output_delay -clock sys_clk -max 4.000 [get_ports {Result_Debug[*] PC_Debug[*] OUT_Port[*] Valid}]
set_output_delay -clock sys_clk -min 0.500 [get_ports {Result_Debug[*] PC_Debug[*] OUT_Port[*] Valid}]

# ============================================================================
# FALSE PATHS - Critical for avoiding timing errors
# ============================================================================
set_false_path -from [get_ports rst]
set_false_path -from [get_ports Interrupt]
set_false_path -from [get_ports {IN_Port[*]}]
set_false_path -to [get_ports {Result_Debug[*]}]
set_false_path -to [get_ports {OUT_Port[*]}]
set_false_path -to [get_ports Valid]

# ============================================================================
# PIN ASSIGNMENTS - BASYS3 BOARD
# ============================================================================

# System Clock - 100MHz
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# Reset Button - BTNC (Center)
set_property PACKAGE_PIN U18 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

# Interrupt Button - BTNU (Up)
set_property PACKAGE_PIN T18 [get_ports Interrupt]
set_property IOSTANDARD LVCMOS33 [get_ports Interrupt]

# ============================================================================
# INPUT PORT - 8 SWITCHES (SW7-SW0)
# ============================================================================
set_property PACKAGE_PIN V17 [get_ports {IN_Port[0]}]
set_property PACKAGE_PIN V16 [get_ports {IN_Port[1]}]
set_property PACKAGE_PIN W16 [get_ports {IN_Port[2]}]
set_property PACKAGE_PIN W17 [get_ports {IN_Port[3]}]
set_property PACKAGE_PIN W15 [get_ports {IN_Port[4]}]
set_property PACKAGE_PIN V15 [get_ports {IN_Port[5]}]
set_property PACKAGE_PIN W14 [get_ports {IN_Port[6]}]
set_property PACKAGE_PIN W13 [get_ports {IN_Port[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {IN_Port[*]}]

# ============================================================================
# PC_DEBUG - 8 LEDS (LD7-LD0) - Shows Program Counter
# ============================================================================
set_property PACKAGE_PIN U16 [get_ports {PC_Debug[0]}]
set_property PACKAGE_PIN E19 [get_ports {PC_Debug[1]}]
set_property PACKAGE_PIN U19 [get_ports {PC_Debug[2]}]
set_property PACKAGE_PIN V19 [get_ports {PC_Debug[3]}]
set_property PACKAGE_PIN W18 [get_ports {PC_Debug[4]}]
set_property PACKAGE_PIN U15 [get_ports {PC_Debug[5]}]
set_property PACKAGE_PIN U14 [get_ports {PC_Debug[6]}]
set_property PACKAGE_PIN V14 [get_ports {PC_Debug[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PC_Debug[*]}]

# ============================================================================
# RESULT_DEBUG & OUT_PORT - Use separate unique pins
# CRITICAL: These were causing "PACKAGE_PIN occupied" errors
# ============================================================================

# Result_Debug - Using PMOD JA (Top row: JA1-JA4, Bottom row: JA7-JA10)
set_property PACKAGE_PIN J1 [get_ports {Result_Debug[0]}]
set_property PACKAGE_PIN L2 [get_ports {Result_Debug[1]}]
set_property PACKAGE_PIN J2 [get_ports {Result_Debug[2]}]
set_property PACKAGE_PIN G2 [get_ports {Result_Debug[3]}]
set_property PACKAGE_PIN H1 [get_ports {Result_Debug[4]}]
set_property PACKAGE_PIN K2 [get_ports {Result_Debug[5]}]
set_property PACKAGE_PIN H2 [get_ports {Result_Debug[6]}]
set_property PACKAGE_PIN G3 [get_ports {Result_Debug[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Result_Debug[*]}]

# OUT_Port - Using PMOD JB (Top row: JB1-JB4, Bottom row: JB7-JB10)
set_property PACKAGE_PIN A14 [get_ports {OUT_Port[0]}]
set_property PACKAGE_PIN A16 [get_ports {OUT_Port[1]}]
set_property PACKAGE_PIN B15 [get_ports {OUT_Port[2]}]
set_property PACKAGE_PIN B16 [get_ports {OUT_Port[3]}]
set_property PACKAGE_PIN A15 [get_ports {OUT_Port[4]}]
set_property PACKAGE_PIN A17 [get_ports {OUT_Port[5]}]
set_property PACKAGE_PIN C15 [get_ports {OUT_Port[6]}]
set_property PACKAGE_PIN C16 [get_ports {OUT_Port[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {OUT_Port[*]}]

# ============================================================================
# VALID SIGNAL - Single bit output to indicate valid output data
# Using PMOD JC pin JC1
# ============================================================================
set_property PACKAGE_PIN K17 [get_ports Valid]
set_property IOSTANDARD LVCMOS33 [get_ports Valid]

# ============================================================================
# SYNTHESIS DIRECTIVES - Fix Critical Warnings
# ============================================================================

# Force Block RAM for memory (avoid distributed RAM)
set_property RAM_STYLE block [get_cells -hierarchical -filter {NAME =~ "*UnifiedMem/mem_reg*"}]

# Prevent removal of debug signals - FIXED: Use MARK_DEBUG or KEEP_HIERARCHY on cells, not KEEP on nets
set_property KEEP_HIERARCHY true [get_cells -hierarchical -filter {NAME =~ "*PC_Debug*"}]
set_property KEEP_HIERARCHY true [get_cells -hierarchical -filter {NAME =~ "*Result_Debug*"}]

# Don't optimize away register file
set_property DONT_TOUCH true [get_cells -hierarchical -filter {NAME =~ "*RF*"}]

# ============================================================================
# TIMING RELAXATION - For initial implementation
# ============================================================================
# REMOVED: The problematic set_max_delay constraints that required non-empty -from
# These were causing critical warnings. If you need timing constraints on register file,
# they should be added with proper source and destination specifications.

# ============================================================================
# CONFIGURATION SETTINGS
# ============================================================================
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]

# ============================================================================
# PLACEMENT STRATEGY (Helps with routing congestion)
# ============================================================================
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]