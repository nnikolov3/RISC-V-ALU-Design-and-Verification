# Start fresh
vdel -lib work -all

# Create work directory
vlib work

# Map library
vmap work work

# Compile all Verilog Files
vlog -sv *.sv "+acc"
