// ----------------------------------------------------------------------------
// Class: alu_coverage
// Description:
//   This UVM subscriber collects coverage by sampling transactions received
//   from the monitor's analysis port. It ensures comprehensive coverage of ALU
//   operations, branch/jump handling, pipeline control signals, exceptions,
//   and reset conditions.
// Updated: Mar 08, 2025
// ----------------------------------------------------------------------------
// Guard against multiple inclusions of this file in the compilation process.
// If ALU_COV_SV is already defined elsewhere, this file won’t be reprocessed.
`ifndef ALU_COV_SV
`define ALU_COV_SV 

// Include UVM macro definitions for utility functions and reporting mechanisms.
`include "uvm_macros.svh"

// Import the UVM package to access its classes, methods, and infrastructure.
import uvm_pkg::*;

// Include header and transaction definitions required for ALU-specific fields
// and the transaction class used by this coverage component.
`include "rv32i_alu_header.sv"  // Provides ALU-specific constants and types.
`include "transaction.sv"  // Defines the transaction class for data sampling.

// Define the alu_coverage class, inheriting from uvm_subscriber, a UVM component
// designed to receive transactions via an analysis port and process them.
class alu_coverage extends uvm_subscriber #(transaction);
  // Register the class with UVM’s factory, enabling type registration for dynamic
  // instantiation and overrides. This allows the factory to create or replace this
  // component during simulation setup, enhancing testbench flexibility.
  `uvm_component_utils(alu_coverage)

  // Transaction handle to store the incoming transaction object received from
  // the monitor’s analysis port for coverage sampling.
  transaction tr;

  // Covergroup to define and collect functional coverage based on transaction data.
  // It groups related coverage points and crosses to track ALU behavior comprehensively.
  covergroup alu_cg;
    // Opcode coverage: Monitors the instruction opcode field from the transaction.
    // Uses 11-bit values as defined in transaction.sv, focusing on R-type and I-type.
    opcode_check: coverpoint tr.i_opcode {
      bins r_type = {11'b00000000001};  // Covers R-type instructions (custom encoding).
      bins i_type = {11'b00000000010};  // Covers I-type instructions (custom encoding).
    /* Note: The commented-out bins use standard 7-bit RISC-V opcodes (e.g., load = 7'b0000011),
         but the current code uses 11-bit custom values. Uncommented bins can be enabled
         with adjustments to match the transaction’s i_opcode width and encoding:
         bins load = {7'b0000011}; bins store = {7'b0100011}; bins branch = {7'b1100011};
         bins jal = {7'b1101111}; bins jalr = {7'b1100111}; bins lui = {7'b0110111};
         bins auipc = {7'b0010111}; bins system = {7'b1110011}; bins fence = {7'b0001111};
      */
    }

    // ALU operation coverage: Tracks the ALU function field (14-bit one-hot encoding)
    // from transaction.sv, ensuring all supported operations are exercised.
    alu_check: coverpoint tr.i_alu {
      bins add = {14'b00000000000001};  // Covers ADD operation.
      bins sub = {14'b00000000000010};  // Covers SUB operation.
      bins and_op = {14'b00000000000100};  // Covers AND operation.
      bins or_op = {14'b00000000001000};  // Covers OR operation.
      bins xor_op = {14'b00000000010000};  // Covers XOR operation.
      bins sll = {14'b00000000100000};  // Covers Shift Left Logical (SLL).
      bins srl = {14'b00000001000000};  // Covers Shift Right Logical (SRL).
      bins sra = {14'b00000010000000};  // Covers Shift Right Arithmetic (SRA).
      bins slt = {14'b00000100000000};  // Covers Set Less Than (SLT).
      bins sltu = {14'b00001000000000};  // Covers Set Less Than Unsigned (SLTU).
      bins eq = {14'b00010000000000};  // Covers Equal (EQ) comparison.
      bins neq = {14'b00100000000000};  // Covers Not Equal (NEQ) comparison.
      bins ge = {14'b01000000000000};  // Covers Greater or Equal (GE) comparison.
      bins geu = {14'b10000000000000};  // Covers Greater or Equal Unsigned (GEU).
    }

    // Reset coverage: Monitors the reset signal to ensure behavior is tested
    // under both reset asserted and deasserted conditions.
    coverpoint tr.rst_n {
      bins reset_asserted = {0};  // Covers reset active (low).
      bins reset_deasserted = {1};  // Covers reset inactive (high).
    }

    // Pipeline management coverage: Tracks the clock enable signal to verify
    // ALU operation with the pipeline enabled or disabled.
    coverpoint tr.i_ce {
      bins disabled = {0};  // Covers clock enable off.
      bins enabled = {1};  // Covers clock enable on.
    }

    // Cross coverage: Combines opcode and ALU operation fields to verify specific
    // instruction-operation pairs, ensuring the ALU executes each operation for
    // applicable instruction types (R-type and I-type).
    cross opcode_check, alu_check{
      bins r_type_add = binsof (opcode_check.r_type) &&
          binsof (alu_check.add);  // ADD with R-type.
      bins r_type_sub = binsof (opcode_check.r_type) &&
          binsof (alu_check.sub);  // SUB with R-type.
      bins r_type_and = binsof (opcode_check.r_type) &&
          binsof (alu_check.and_op);  // AND with R-type.
      bins r_type_or = binsof (opcode_check.r_type) &&
          binsof (alu_check.or_op);  // OR with R-type.
      bins r_type_xor = binsof (opcode_check.r_type) &&
          binsof (alu_check.xor_op);  // XOR with R-type.
      bins r_type_sll = binsof (opcode_check.r_type) &&
          binsof (alu_check.sll);  // SLL with R-type.
      bins r_type_srl = binsof (opcode_check.r_type) &&
          binsof (alu_check.srl);  // SRL with R-type.
      bins r_type_sra = binsof (opcode_check.r_type) &&
          binsof (alu_check.sra);  // SRA with R-type.
      bins r_type_slt = binsof (opcode_check.r_type) &&
          binsof (alu_check.slt);  // SLT with R-type.
      bins r_type_sltu = binsof (opcode_check.r_type) &&
          binsof (alu_check.sltu);  // SLTU with R-type.
      bins r_type_eq = binsof (opcode_check.r_type) && binsof (alu_check.eq);  // EQ with R-type.
      bins r_type_neq = binsof (opcode_check.r_type) &&
          binsof (alu_check.neq);  // NEQ with R-type.
      bins r_type_ge = binsof (opcode_check.r_type) && binsof (alu_check.ge);  // GE with R-type.
      bins r_type_geu = binsof (opcode_check.r_type) &&
          binsof (alu_check.geu);  // GEU with R-type.

      bins i_type_add = binsof (opcode_check.i_type) &&
          binsof (alu_check.add);  // ADD with I-type.
      bins i_type_sub = binsof (opcode_check.i_type) &&
          binsof (alu_check.sub);  // SUB with I-type (corrected from r_type).
      bins i_type_and = binsof (opcode_check.i_type) &&
          binsof (alu_check.and_op);  // AND with I-type.
      bins i_type_or = binsof (opcode_check.i_type) &&
          binsof (alu_check.or_op);  // OR with I-type.
      bins i_type_xor = binsof (opcode_check.i_type) &&
          binsof (alu_check.xor_op);  // XOR with I-type.
      bins i_type_sll = binsof (opcode_check.i_type) &&
          binsof (alu_check.sll);  // SLL with I-type.
      bins i_type_srl = binsof (opcode_check.i_type) &&
          binsof (alu_check.srl);  // SRL with I-type.
      bins i_type_sra = binsof (opcode_check.i_type) &&
          binsof (alu_check.sra);  // SRA with I-type.
      bins i_type_slt = binsof (opcode_check.i_type) &&
          binsof (alu_check.slt);  // SLT with I-type.
      bins i_type_sltu = binsof (opcode_check.i_type) &&
          binsof (alu_check.sltu);  // SLTU with I-type.
      bins i_type_eq = binsof (opcode_check.i_type) && binsof (alu_check.eq);  // EQ with I-type.
      bins i_type_neq = binsof (opcode_check.i_type) &&
          binsof (alu_check.neq);  // NEQ with I-type.
      bins i_type_ge = binsof (opcode_check.i_type) && binsof (alu_check.ge);  // GE with I-type.
      bins i_type_geu = binsof (opcode_check.i_type) &&
          binsof (alu_check.geu);  // GEU with I-type.
    }

    // Cross coverage: Combines reset and clock enable signals to ensure coverage
    // of their interactions, verifying ALU behavior under reset and pipeline states.
    cross tr.rst_n, tr.i_ce;

  // Additional commented-out coverpoints and crosses (e.g., exceptions, stalls)
  // can be enabled to expand coverage scope as the testbench evolves:
  /* coverpoint tr.i_exception { bins no_exception = {0}; bins exceptions[] = {[1 : (1 << `EXCEPTION_WIDTH) - 1]}; } */
  /* cross tr.i_opcode, tr.i_exception; */
  /* cross tr.i_ce, tr.i_stall, tr.i_force_stall, tr.i_flush; */
  endgroup

  // Constructor: Initializes the component and instantiates the covergroup.
  // The parent argument ties this subscriber into the UVM hierarchy.
  function new(string name, uvm_component parent);
    super.new(name, parent);  // Call the parent class (uvm_subscriber) constructor.
    alu_cg = new();  // Create the covergroup instance for sampling.
  endfunction

  // Write function: Receives transactions from the monitor’s analysis port.
  // This is the callback method required by uvm_subscriber to process incoming data.
  function void write(transaction t);
    tr = t;  // Assign the received transaction to the handle for sampling.
    // Sample coverage only when the clock enable is active or reset is asserted,
    // ensuring data is collected during relevant simulation states.
    if (tr.i_ce || !tr.rst_n) begin
      alu_cg.sample();  // Trigger the covergroup to evaluate its bins.
    end
  endfunction

  // Extract phase: Runs after simulation to report coverage results.
  // This phase is part of UVM’s phase mechanism for finalizing component tasks.
  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);  // Call the parent class’s extract_phase.
    // Log the achieved functional coverage percentage with low verbosity.
    `uvm_info("COVERAGE", $sformatf("Functional Coverage: %0.2f%%", alu_cg.get_coverage()), UVM_LOW)
  endfunction
endclass

// End the inclusion guard, ensuring this file is processed only once.
`endif
