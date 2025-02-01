if [file exists "work"] {vdel -all}
# Create work directory
vlib work

# Map library
vmap work work

# Compile all Verilog Files
vlog ./CLASS/*.sv ./UVM/*.sv


vsim work.rv32i_alu_tb

run -all
