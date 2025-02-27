// ----------------------------------------------------------------------------
// *********************************************
// UVM Test Class for ALU Verification
// ECE 593: Milestone 4, Group 3
// File: test.sv
// Class: alu_base_test
// Description:
// This UVM base test class establishes the foundation for verifying the
// RV32I Arithmetic Logic Unit (ALU) within a RISC-V 32I processor verification
// environment. It instantiates an ALU environment and executes a predefined
// sequence to stimulate the Device Under Test (DUT) via an agent’s sequencer.
// The test manages simulation phases and objections to ensure proper execution.
// Updated: Feb 26, 2025
// **********************************************
// ----------------------------------------------------------------------------

// Prevent multiple inclusions of this file to avoid redefinition errors
`ifndef ALU_TEST_SV
`define ALU_TEST_SV

// Include UVM macros to enable utility functions and shortcuts
`include "uvm_macros.svh"
`include "rv32i_alu_header.sv"

// Import the UVM package to use its classes and methods
import uvm_pkg::*;

// Include the environment definition, which sets up the testbench structure
`include "environment.sv"

// Define the base test class for ALU verification, inheriting from uvm_test
class alu_base_test extends uvm_test;
    // ------------------------------------------------------------------------
    // Registration: Factory Registration
    // Description:
    //   Registers the test class with the UVM factory for dynamic instantiation.
    // ------------------------------------------------------------------------
    `uvm_component_utils(alu_base_test)

    // ------------------------------------------------------------------------
    // Member: env
    // Description:
    //   Instance of the ALU environment, which encapsulates agents, scoreboards,
    //   and coverage collectors for ALU verification.
    // ------------------------------------------------------------------------
    alu_env env;


		
        // Drop the objection to signal that the test is complete, allowing simulation to end

        phase.drop_objection(this);
    endtask

endclass

// End of the include guard
`endif
