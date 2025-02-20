if [file exists "work"] {vdel -all}
# Create work directory
vlib work

# Map library
vmap work work

# Compile all Verilog Files
vlog -mfcu -lint *.sv 


vsim -coverage work.rv32i_alu_tb -voptargs="+cover=bcesf"

run -all
