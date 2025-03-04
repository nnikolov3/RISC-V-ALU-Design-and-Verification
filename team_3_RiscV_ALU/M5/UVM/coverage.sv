// ----------------------------------------------------------------------------
// Class: alu_coverage
// Description:
//   This UVM subscriber collects coverage by sampling transactions received
//   from the monitor's analysis port. It ensures comprehensive coverage of ALU
//   operations, branch/jump handling, pipeline control signals, exceptions,
//   and reset conditions.
// Updated: Feb 26, 2025
// ----------------------------------------------------------------------------
`ifndef ALU_COV_SV
`define ALU_COV_SV 

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "rv32i_alu_header.sv"  // Include the provided header file
`include "transaction.sv"  // Include the updated transaction.sv

class alu_coverage extends uvm_subscriber #(transaction);
    `uvm_component_utils(alu_coverage)

    // Transaction handle
    transaction tr;

    // Covergroup to sample coverage based on transaction data
    covergroup alu_cg;
        // Opcode coverage (7-bit standard RISC-V opcodes from transaction.sv)
        opcode_check: coverpoint tr.i_opcode {
            bins r_type = {11'b00000000001};  // R-type
            bins i_type = {11'b00000000010};  // I-type
/*            bins load = {7'b0000011};  // Load
            bins store = {7'b0100011};  // Store
            bins branch = {7'b1100011};  // Branch
            bins jal = {7'b1101111};  // JAL
            bins jalr = {7'b1100111};  // JALR
            bins lui = {7'b0110111};  // LUI
            bins auipc = {7'b0010111};  // AUIPC
            bins system = {7'b1110011};  // System
            bins fence = {7'b0001111};  // Fence
			*/
        }

        // ALU operation coverage (14-bit one-hot from transaction.sv)
        alu_check: coverpoint tr.i_alu {
            bins add = {14'b00000000000001};  // ADD
            bins sub = {14'b00000000000010};  // SUB
            bins and_op = {14'b00000000000100};  // AND
            bins or_op = {14'b00000000001000};  // OR
            bins xor_op = {14'b00000000010000};  // XOR
            bins sll = {14'b00000000100000};  // SLL
            bins srl = {14'b00000001000000};  // SRL
            bins sra = {14'b00000010000000};  // SRA
            bins slt = {14'b00000100000000};  // SLT
            bins sltu = {14'b00001000000000};  // SLTU
            bins eq = {14'b00010000000000};  // EQ
            bins neq = {14'b00100000000000};  // NEQ
            bins ge = {14'b01000000000000};  // GE
            bins geu = {14'b10000000000000};  // GEU
        }

        // Reset coverage
        coverpoint tr.rst_n {
            bins reset_asserted = {0}; bins reset_deasserted = {1};
        }

        // Branch and jump coverage
        /*coverpoint tr.o_change_pc {
            bins no_change = {0}; bins change = {1};
        }*/

        // Register writeback coverage
        /*coverpoint tr.o_wr_rd {
            bins no_write = {0}; bins write = {1};
        }*/

        //coverpoint tr.o_rd_valid {bins invalid = {0}; bins valid = {1};}

        /*coverpoint tr.o_rd_addr {
            bins reg_addr[] = {[0 : 31]};  // Covers all 32 registers
        }*/

        // Pipeline management coverage
        coverpoint tr.i_ce {
            bins disabled = {0}; bins enabled = {1};
        }

        //coverpoint tr.i_stall {bins no_stall = {0}; bins stall = {1};}

        //coverpoint tr.i_force_stall {bins no_force_stall = {0}; bins force_stall = {1};}

        //coverpoint tr.i_flush {bins no_flush = {0}; bins flush = {1};}

        //coverpoint tr.o_stall_from_alu {bins no_alu_stall = {0}; bins alu_stall = {1};}

        // Exception coverage
        /*coverpoint tr.i_exception {
            bins no_exception = {0};
            bins exceptions[] =
                {[1 : (1 << `EXCEPTION_WIDTH) - 1]};  // e.g., 1 to 3 if EXCEPTION_WIDTH=2
        }*/

        // Cross coverage for key interactions
        cross opcode_check, alu_check {
			bins r_type_add 	= binsof(opcode_check.r_type) && binsof(alu_check.add);  // ADD for R-type
			bins r_type_sub 	= binsof(opcode_check.r_type) && binsof(alu_check.sub);  // SUB for R-type
			bins r_type_and 	= binsof(opcode_check.r_type) && binsof(alu_check.and_op);  // AND for R-type
			bins r_type_or 		= binsof(opcode_check.r_type) && binsof(alu_check.or_op);  // OR for R-type
			bins r_type_xor 	= binsof(opcode_check.r_type) && binsof(alu_check.xor_op);  // XOR for R-type
			bins r_type_sll 	= binsof(opcode_check.r_type) && binsof(alu_check.sll);  // SLL for R-type
			bins r_type_srl 	= binsof(opcode_check.r_type) && binsof(alu_check.srl);  // SRL for R-type
			bins r_type_sra 	= binsof(opcode_check.r_type) && binsof(alu_check.sra);  // SRA for R-type
			bins r_type_slt 	= binsof(opcode_check.r_type) && binsof(alu_check.slt);  // SLT for R-type
			bins r_type_sltu 	= binsof(opcode_check.r_type) && binsof(alu_check.sltu);  // SLTU for R-type
			bins r_type_eq 		= binsof(opcode_check.r_type) && binsof(alu_check.eq);  // EQ for R-type
			bins r_type_neq 	= binsof(opcode_check.r_type) && binsof(alu_check.neq);  // NEQ for R-type
			bins r_type_ge 		= binsof(opcode_check.r_type) && binsof(alu_check.ge);  // GE for R-type
			bins r_type_geu 	= binsof(opcode_check.r_type) && binsof(alu_check.geu);  // GEU for R-type
																		
			bins i_type_add 	= binsof(opcode_check.i_type) && binsof(alu_check.add);  // ADD for I-type
			bins i_type_sub 	= binsof(opcode_check.i_type) && binsof(alu_check.sub);  // SUB for I-type
			bins i_type_and 	= binsof(opcode_check.i_type) && binsof(alu_check.and_op);  // AND for I-type
			bins i_type_or 		= binsof(opcode_check.i_type) && binsof(alu_check.or_op);  // OR for I-type
			bins i_type_xor 	= binsof(opcode_check.i_type) && binsof(alu_check.xor_op);  // XOR for I-type
			bins i_type_sll 	= binsof(opcode_check.i_type) && binsof(alu_check.sll);  // SLL for I-type
			bins i_type_srl 	= binsof(opcode_check.i_type) && binsof(alu_check.srl);  // SRL for I-type
			bins i_type_sra 	= binsof(opcode_check.i_type) && binsof(alu_check.sra);  // SRA for I-type
			bins i_type_slt 	= binsof(opcode_check.i_type) && binsof(alu_check.slt);  // SLT for I-type
			bins i_type_sltu	= binsof(opcode_check.i_type) && binsof(alu_check.sltu);  // SLTU for I-type
			bins i_type_eq 		= binsof(opcode_check.i_type) && binsof(alu_check.eq);  // EQ for I-type
			bins i_type_neq 	= binsof(opcode_check.i_type) && binsof(alu_check.neq);  // NEQ for I-type
			bins i_type_ge 		= binsof(opcode_check.i_type) && binsof(alu_check.ge);  // GE for I-type
			bins i_type_geu 	= binsof(opcode_check.i_type) && binsof(alu_check.geu);  // GEU for I-type
    }
        //cross tr.i_opcode, tr.i_exception;
        //cross tr.i_opcode, tr.o_change_pc;
        //cross tr.i_ce, tr.i_stall, tr.i_force_stall, tr.i_flush;
        //cross tr.o_wr_rd, tr.o_rd_valid, tr.i_opcode;
        cross tr.rst_n, tr.i_ce;
        //cross tr.i_stall, tr.o_stall_from_alu;
    endgroup

    // Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
        alu_cg = new();
    endfunction

    // Write function to receive transactions from analysis port
    function void write(transaction t);
        tr = t;
        if (tr.i_ce || !tr.rst_n) begin  // Sample during active clock enable or reset
            alu_cg.sample();
        end
    endfunction

    // Extract phase to display coverage results
    function void extract_phase(uvm_phase phase);
        super.extract_phase(phase);
        `uvm_info("COVERAGE", $sformatf("Functional Coverage: %0.2f%%", alu_cg.get_coverage()),
                  UVM_LOW)
    endfunction
endclass

`endif
