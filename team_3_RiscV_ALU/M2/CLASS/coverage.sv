// ----------------------------------------------------------------------------
// ECE544 M2 - RV32I ALU Coverage
// ----------------------------------------------------------------------------
// This file implements a UVM subscriber for monitoring and recording coverage
// metrics for the RV32I ALU. It samples key signals (opcode and ALU control) and
// tracks functional coverage using a covergroup.
// ----------------------------------------------------------------------------

`include "rv32i_alu_header.sv"
`include "uvm_macros.svh"
`include "transaction.sv"
import uvm_pkg::*;

class coverage extends uvm_subscriber #(transaction);

    `uvm_component_utils(coverage)

    // Signals used for coverage sampling
    logic [`OPCODE_WIDTH-1:0] opcode;  // Current opcode being executed
    logic [`ALU_WIDTH-1:0] alu;  // Current ALU control value

    // Covergroup definition for ALU functionality
    covergroup alu_cg;
        coverpoint opcode;
        coverpoint alu;
    endgroup

    // Constructor: initializes the coverage collector and covergroup
    function new(string name = "coverage", uvm_component parent);
        super.new(name, parent);
        alu_cg = new();
    endfunction

    // Write method: called automatically when a transaction is received
    // This method samples the current state of the ALU and updates coverage
    virtual function void write(transaction t);
        opcode = t.i_opcode;  // Corrected field name
        alu = t.i_alu;  // Corrected field name
        alu_cg.sample();
    endfunction

endclass
