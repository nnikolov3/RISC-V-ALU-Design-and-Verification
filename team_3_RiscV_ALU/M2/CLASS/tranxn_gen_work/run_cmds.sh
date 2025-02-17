vlog transaction.sv generator.sv tb_generator_verif.sv
vsim -c tb_alu_stimulus -do "run -all; quit" -solvefaildebug=2