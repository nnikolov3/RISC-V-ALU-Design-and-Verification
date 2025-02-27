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

    // ------------------------------------------------------------------------
    // Constructor: new
    // Description:
    //   Initializes the test class with a name and parent in the UVM hierarchy.
    // Arguments:
    //   - name: String identifier for the test instance
    //   - parent: Parent UVM component (typically the testbench top)
    // ------------------------------------------------------------------------
    function new(string name, uvm_component parent);
        // Call the parent class constructor to set up base UVM functionality
        super.new(name, parent);
    endfunction

    // ------------------------------------------------------------------------
    // Function: build_phase
    // Description:
    //   Configures and instantiates testbench components during the build phase,
    //   prior to simulation start. Creates the ALU environment instance.
    // Arguments:
    //   - phase: UVM phase object for synchronization
    // ------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        // Execute the parent’s build_phase for foundational setup
        super.build_phase(phase);
        // Create the environment instance using the UVM factory
        env = alu_env::type_id::create("env", this);
    endfunction

    // ------------------------------------------------------------------------
    // Task: run_phase
    // Description:
    //   Executes the test during the simulation run phase. Instantiates and
    //   starts an ALU sequence on the agent’s sequencer to drive the DUT,
    //   managing simulation duration with phase objections.
    // Arguments:
    //   - phase: UVM phase object for synchronization
    // ------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        // Declare the sequence object for ALU stimulus generation
        alu_sequence seq;
        // Raise an objection to keep the simulation active during the test
        phase.raise_objection(this);
        // Instantiate the sequence using the UVM factory
        seq = alu_sequence::type_id::create("seq");
        // Start the sequence on the agent’s sequencer to drive transactions to the DUT
        seq.start(env.agent.sequencer);
        // Drop the objection to signal test completion, allowing simulation to end
        phase.drop_objection(this);
    endtask
endclass

// End of the include guard
`endif
