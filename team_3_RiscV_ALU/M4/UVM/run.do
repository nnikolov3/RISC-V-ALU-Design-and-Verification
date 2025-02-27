if {[file exists "work"]} {vdel -lib work -all}
# Create work directory
vlib work

# Map library
vmap work work

# Compile all Verilog Files
vlog -mfcu -lint top.sv interface.sv rv32i_alu.sv transaction.sv agent.sv coverage.sv driver.sv environment.sv monitor.sv scoreboard.sv sequencer.sv test.sv 


vsim -coverage work.top -voptargs="+cover=bcesf"

run -all
