/**********************************************
 UVM Test Class for ALU Verification
 Part of the RISC-V 32I ALU verification environment
 ECE593: Milestone 4, Group 3
 File: test.sv (Version: 1.0)
 Class: alu_base_test
***********************************************/

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

// Include the sequence definition, which provides stimulus for the DUT
//include "sequencer.sv"

// Define the base test class for ALU verification, inheriting from uvm_test
class alu_base_test extends uvm_test;

    // Register the class with the UVM factory for dynamic instantiation
    `uvm_component_utils(alu_base_test)

    // Declare an instance of the ALU environment, which includes agents and other components
    alu_env env;

	virtual alu_if vif;
    // Constructor to initialize the test class
    // - name: Unique instance name for this test
    // - parent: Parent component, typically the testbench top
    function new(string name, uvm_component parent);
        // Call the parent class constructor to set up base UVM functionality
        super.new(name, parent);
    endfunction

    // Build phase: Configure and instantiate testbench components before simulation
    function void build_phase(uvm_phase phase);
        // Execute the parent’s build_phase for foundational setup
        super.build_phase(phase);
/*		if (!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("MONITOR", "Virtual interface not set")
		end */
		
		uvm_config_db #(virtual alu_if)::set(this, "*", "alu_vif", vif);
        // Create the environment instance using the UVM factory
        env = alu_env::type_id::create("env", this);
    endfunction

    // Run phase: Execute the test by running the sequence during simulation
    task run_phase(uvm_phase phase);
        // Declare the sequence object that generates ALU test stimuli
        alu_sequence seq;
        // Raise an objection to keep the simulation active while the test runs
        phase.raise_objection(this);
        // Instantiate the sequence using the UVM factory
        seq = alu_sequence::type_id::create("seq");
        // Start the sequence on the agent’s sequencer to drive transactions to the DUT
        seq.start(env.agent.sequencer);
        // Drop the objection to signal that the test is complete, allowing simulation to end
        phase.drop_objection(this);
    endtask
endclass

// End of the include guard
`endif
