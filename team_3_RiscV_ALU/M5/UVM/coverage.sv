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
        coverpoint tr.i_opcode {
            bins r_type = {7'b0110011};  // R-type
            bins i_type = {7'b0010011};  // I-type
            bins load = {7'b0000011};  // Load
            bins store = {7'b0100011};  // Store
            bins branch = {7'b1100011};  // Branch
            bins jal = {7'b1101111};  // JAL
            bins jalr = {7'b1100111};  // JALR
            bins lui = {7'b0110111};  // LUI
            bins auipc = {7'b0010111};  // AUIPC
            bins system = {7'b1110011};  // System
            bins fence = {7'b0001111};  // Fence
        }

        // ALU operation coverage (14-bit one-hot from transaction.sv)
        coverpoint tr.i_alu {
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
        coverpoint tr.o_change_pc {
            bins no_change = {0}; bins change = {1};
        }

        // Register writeback coverage
        coverpoint tr.o_wr_rd {
            bins no_write = {0}; bins write = {1};
        }

        coverpoint tr.o_rd_valid {bins invalid = {0}; bins valid = {1};}

        coverpoint tr.o_rd_addr {
            bins reg_addr[] = {[0 : 31]};  // Covers all 32 registers
        }

        // Pipeline management coverage
        coverpoint tr.i_ce {
            bins disabled = {0}; bins enabled = {1};
        }

        coverpoint tr.i_stall {bins no_stall = {0}; bins stall = {1};}

        coverpoint tr.i_force_stall {bins no_force_stall = {0}; bins force_stall = {1};}

        coverpoint tr.i_flush {bins no_flush = {0}; bins flush = {1};}

        coverpoint tr.o_stall_from_alu {bins no_alu_stall = {0}; bins alu_stall = {1};}

        // Exception coverage
        coverpoint tr.i_exception {   
        bins no_exception = {0};
        bins div_by_zero = {1};
        bins illegal_opcode = {2};
        bins overflow = {3};
        bins underflow = {4};
        bins misaligned_access = {5};
    }

        // Cross coverage for key interactions
        cross tr.i_opcode, tr.i_alu;
        cross tr.i_opcode, tr.i_exception;
        cross tr.i_opcode, tr.o_change_pc;
        cross tr.i_ce, tr.i_stall, tr.i_force_stall, tr.i_flush;
        cross tr.o_wr_rd, tr.o_rd_valid, tr.i_opcode;
        cross tr.rst_n, tr.i_ce;
        cross tr.i_stall, tr.o_stall_from_alu;
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
