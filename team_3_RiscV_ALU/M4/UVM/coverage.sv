// ----------------------------------------------------------------------------
// Class: alu_coverage
// ECE 593
// Milestone 4 - RV32I ALU Coverage
// Team 3
// Description:
//   This UVM subscriber class collects functional coverage data by sampling
//   transactions from the monitor’s analysis port in the RISC-V 32I ALU
//   verification environment. It tracks coverage of ALU operations, opcodes,
//   reset states, branch/jump conditions, register writeback, pipeline control
//   signals, exceptions, and their interactions through a covergroup, reporting
//   coverage metrics at simulation end.
// Updated: Feb 26, 2025
// ----------------------------------------------------------------------------

`ifndef ALU_COV_SV
`define ALU_COV_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "rv32i_alu_header.sv"  // Provides ALU operation and opcode definitions
`include "transaction.sv"  // Defines the transaction class for sampling

class alu_coverage extends uvm_subscriber #(transaction);
    // ------------------------------------------------------------------------
    // Registration: Factory Registration
    // Description:
    //   Registers the coverage class with the UVM factory for dynamic instantiation.
    // ------------------------------------------------------------------------
    `uvm_component_utils(alu_coverage)

    // ------------------------------------------------------------------------
    // Member: tr
    // Description:
    //   Handle to the transaction object received from the analysis port, used
    //   for sampling coverage data.
    // ------------------------------------------------------------------------
    transaction tr;

    // ------------------------------------------------------------------------
    // Covergroup: alu_cg
    // Description:
    //   Defines a covergroup to collect functional coverage on ALU transactions,
    //   including opcodes, ALU operations, control signals, and key interactions.
    // ------------------------------------------------------------------------
    covergroup alu_cg;
        // Opcode coverage: Tracks RISC-V 32I instruction types (7-bit)
        coverpoint tr.i_opcode {
            bins r_type = {7'b0110011};  // R-type instructions
            bins i_type = {7'b0010011};  // I-type instructions
            bins load = {7'b0000011};  // Load instructions
            bins store = {7'b0100011};  // Store instructions
            bins branch = {7'b1100011};  // Branch instructions
            bins jal = {7'b1101111};  // Jump and Link (JAL)
            bins jalr = {7'b1100111};  // Jump and Link Register (JALR)
            bins lui = {7'b0110111};  // Load Upper Immediate (LUI)
            bins auipc = {7'b0010111};  // Add Upper Immediate to PC (AUIPC)
            bins system = {7'b1110011};  // System instructions
            bins fence = {7'b0001111};  // Fence instructions
        }

        // ALU operation coverage: Tracks 14-bit one-hot ALU control signals
        coverpoint tr.i_alu {
            bins add = {14'b00000000000001};  // Addition
            bins sub = {14'b00000000000010};  // Subtraction
            bins and_op = {14'b00000000000100};  // Bitwise AND
            bins or_op = {14'b00000000001000};  // Bitwise OR
            bins xor_op = {14'b00000000010000};  // Bitwise XOR
            bins sll = {14'b00000000100000};  // Shift Left Logical
            bins srl = {14'b00000001000000};  // Shift Right Logical
            bins sra = {14'b00000010000000};  // Shift Right Arithmetic
            bins slt = {14'b00000100000000};  // Set Less Than (signed)
            bins sltu = {14'b00001000000000};  // Set Less Than (unsigned)
            bins eq = {14'b00010000000000};  // Equal
            bins neq = {14'b00100000000000};  // Not Equal
            bins ge = {14'b01000000000000};  // Greater or Equal (signed)
            bins geu = {14'b10000000000000};  // Greater or Equal (unsigned)
        }

        // Reset coverage: Tracks reset signal states
        coverpoint tr.i_rst_n {
            bins reset_asserted = {0};  // Reset active (low)
            bins reset_deasserted = {1};  // Reset inactive (high)
        }

        // Branch and jump coverage: Tracks PC change requests
        coverpoint tr.o_change_pc {
            bins no_change = {0};  // No PC update
            bins change = {1};  // PC update (branch/jump taken)
        }

        // Register writeback coverage: Tracks write enable and validity
        coverpoint tr.o_wr_rd {
            bins no_write = {0};  // No write to destination register
            bins write = {1};  // Write to destination register
        }
        coverpoint tr.o_rd_valid {
            bins invalid = {0};  // Destination data invalid
            bins valid = {1};  // Destination data valid
        }
        coverpoint tr.o_rd_addr {
            bins reg_addr[] = {[0 : 31]};  // All 32 RISC-V register addresses
        }

        // Pipeline management coverage: Tracks control signals
        coverpoint tr.i_ce {
            bins disabled = {0};  // Clock enable off
            bins enabled = {1};  // Clock enable on
        }
        coverpoint tr.i_stall {
            bins no_stall = {0};  // No pipeline stall
            bins stall = {1};  // Pipeline stalled
        }
        coverpoint tr.i_force_stall {
            bins no_force_stall = {0};  // No forced stall
            bins force_stall = {1};  // Forced stall active
        }
        coverpoint tr.i_flush {
            bins no_flush = {0};  // No pipeline flush
            bins flush = {1};  // Pipeline flush active
        }
        coverpoint tr.o_stall_from_alu {
            bins no_alu_stall = {0};  // No ALU-induced stall
            bins alu_stall = {1};  // ALU-induced stall
        }

        // Exception coverage: Tracks exception states
        coverpoint tr.i_exception {
            bins no_exception = {0};  // No exception
            bins exceptions[] = {[1 : (1 << `EXCEPTION_WIDTH) - 1]};  // All non-zero exceptions
        }

        // Cross coverage: Captures interactions between key signals
        cross tr.i_opcode, tr.i_alu;  // Opcodes vs. ALU operations
        cross tr.i_opcode, tr.i_exception;  // Opcodes vs. exceptions
        cross tr.i_opcode, tr.o_change_pc;  // Opcodes vs. PC changes
        cross tr.i_ce, tr.i_stall, tr.i_force_stall, tr.i_flush;  // Pipeline controls
        cross tr.o_wr_rd, tr.o_rd_valid, tr.i_opcode;  // Writeback vs. opcode
        cross tr.i_rst_n, tr.i_ce;  // Reset vs. clock enable
        cross tr.i_stall, tr.o_stall_from_alu;  // Stall interactions
    endgroup

    // ------------------------------------------------------------------------
    // Constructor: new
    // Description:
    //   Initializes the coverage subscriber and instantiates the covergroup.
    // Arguments:
    //   - name: String identifier for the component
    //   - parent: Parent UVM component in the hierarchy
    // ------------------------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);
        alu_cg = new();  // Create the covergroup instance
    endfunction

    // ------------------------------------------------------------------------
    // Function: write
    // Description:
    //   Receives transactions from the analysis port and samples coverage when
    //   the clock enable is active or reset is asserted.
    // Arguments:
    //   - t: Transaction object to sample
    // ------------------------------------------------------------------------
    function void write(transaction t);
        tr = t;  // Assign received transaction to handle
        if (tr.i_ce || !tr.i_rst_n) begin  // Sample if CE is on or reset is active
            alu_cg.sample();
        end

    endfunction

    // ------------------------------------------------------------------------
    // Function: extract_phase
    // Description:
    //   Reports the achieved functional coverage percentage at the end of
    //   simulation during the extract phase.
    // Arguments:
    //   - phase: UVM phase object for synchronization
    // ------------------------------------------------------------------------
    function void extract_phase(uvm_phase phase);
        super.extract_phase(phase);
        `uvm_info("COVERAGE", $sformatf("Functional Coverage: %0.2f%%", alu_cg.get_coverage()),
                  UVM_LOW)
    endfunction

endclass

`endif
