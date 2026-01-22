vlib work
vlog -f sourcefile.txt
vsim -voptargs=+accs work.Processor_TB -novopt
add wave *
run -all