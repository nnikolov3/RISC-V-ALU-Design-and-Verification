if [file exists "work"] {vdel -all}
# Create work directory
vlib work

# Map library
vmap work work

# Compile all Verilog Files
vlog -mfcu -lint *.sv


#vsim -coverage work.top -voptargs="+cover=bcesf"

#run -all
