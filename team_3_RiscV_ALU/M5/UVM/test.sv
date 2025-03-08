// ----------------------------------------------------------------------------
// Class: alu_base_test
// Description:
//   This UVM base test class orchestrates the verification of an RV32I ALU DUT.
//   It instantiates the ALU environment, configures the testbench, and executes
//   a predefined sequence to stimulate the DUT via the agent's sequencer.
//   Part of the RISC-V 32I ALU verification environment for ECE593, Group 3.
// File: test.sv
// Updated: Mar 08, 2025
// ----------------------------------------------------------------------------
// Guard against multiple inclusions of this file in the compilation process.
// If ALU_TEST_SV is already defined elsewhere, this file won’t be reprocessed.
`ifndef ALU_TEST_SV
`define ALU_TEST_SV 

// Include UVM macro definitions for utility functions and reporting mechanisms.
`include "uvm_macros.svh"

// Include ALU-specific constants and types defined in the header file.
`include "rv32i_alu_header.sv"

// Import the UVM package to access its classes, methods, and infrastructure.
import uvm_pkg::*;

// Include the environment definition to instantiate the testbench structure.
// This includes agents, scoreboard, and coverage components.
`include "environment.sv"

// Include the sequence definition to provide stimulus for the DUT.
// Note: The original file had an incorrect comment "#include 'sequencer.sv'",
// which is replaced with the correct sequence include (assumed to be alu_sequence.sv).
`include "alu_sequence.sv"

// Define the alu_base_test class, inheriting from uvm_test, a UVM base class
// that serves as the top-level test controller for simulation execution.
class alu_base_test extends uvm_test;
  // Register the class with UVM’s factory, enabling type registration for dynamic
  // instantiation and overrides. This allows the factory to create or replace this
  // test during simulation setup, enhancing testbench flexibility.
  `uvm_component_utils(alu_base_test)

  // Instance of the ALU environment, containing agents, scoreboard, and coverage components.
  alu_env env;

  // Integer handle for an external log file to record UVM messages during simulation.
  integer log_file;

  // Virtual interface handle for connecting to the DUT’s signals, retrieved from the
  // UVM configuration database during the build phase.
  virtual alu_if vif;

  // Constructor: Initializes the test with a name and parent component.
  // Parameters:
  // - name: A string specifying the instance name (e.g., "alu_base_test").
  // - parent: The parent UVM component, typically null for the top-level test.
  function new(string name, uvm_component parent);
    super.new(name, parent);  // Call the parent class (uvm_test) constructor.
  endfunction

  // Build phase: Configures and instantiates testbench components before simulation starts.
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);  // Call the parent class’s build_phase for initialization.

    // Open the log file in append mode ("a") instead of write mode ("w") to preserve
    // logs from multiple test runs. The original "w" mode would overwrite existing logs.
    log_file = $fopen("uvm_log.txt", "a");

    // Check if the file opened successfully (non-zero handle indicates success).
    if (log_file) begin
      // Configure the UVM report server to control message handling for this hierarchy:
      // - UVM_INFO: Display on console and log to file for informational messages.
      // - UVM_WARNING: Log to file only to reduce console clutter.
      // - UVM_ERROR: Display and log to ensure errors are both visible and recorded.
      set_report_severity_action_hier(UVM_INFO, UVM_DISPLAY | UVM_LOG);
      set_report_severity_action_hier(UVM_WARNING, UVM_LOG);
      set_report_severity_action_hier(UVM_ERROR, UVM_LOG | UVM_DISPLAY);

      // Direct each severity level’s messages to the log file by associating
      // the file handle with the report server’s output for this hierarchy.
      set_report_severity_file_hier(UVM_INFO, log_file);
      set_report_severity_file_hier(UVM_WARNING, log_file);
      set_report_severity_file_hier(UVM_ERROR, log_file);

      // Set the default file for all messages in this hierarchy to the log file,
      // ensuring consistent logging behavior across the test.
      set_report_default_file_hier(log_file);

      // Log a message confirming the report server configuration is complete.
      `uvm_info("TEST", "Set report server severities and outputs", UVM_NONE);
    end else begin
      // If the file failed to open, report an error to aid in debugging file system issues.
      `uvm_error("TEST", "Failed to open log file")
    end

    // Retrieve the virtual interface from the UVM configuration database using the
    // key "alu_vif". If not found, issue a fatal error to halt simulation, as the
    // test cannot proceed without this interface. The original commented-out lines
    // are replaced with this functional retrieval.
    if (!uvm_config_db#(virtual alu_if)::get(this, "", "alu_vif", vif)) begin
      `uvm_fatal("TEST", "Virtual interface not found in config db with key 'alu_vif'")
    end

    // Set the virtual interface in the configuration database for all components
    // in the environment to access. This ensures the DUT interface is available
    // to drivers, monitors, etc.
    uvm_config_db#(virtual alu_if)::set(this, "env.*", "alu_vif", vif);

    // Instantiate the environment using the UVM factory’s create method. The instance
    // name is "env", and the parent is this test.
    env = alu_env::type_id::create("env", this);

    // Log a message indicating the build phase is complete, with high verbosity.
    `uvm_info("TEST", "Build phase completed", UVM_HIGH)
  endfunction

  // Run phase: Executes the test by running the sequence during simulation.
  // Controls the simulation timeline and drives the DUT with stimuli.
  task run_phase(uvm_phase phase);
    alu_sequence seq;  // Sequence object to generate ALU test stimuli.

    // Raise an objection to prevent the simulation from ending prematurely.
    // This keeps the run phase active until the test explicitly completes.
    phase.raise_objection(this);

    // Instantiate the sequence using the UVM factory’s create method.
    seq = alu_sequence::type_id::create("seq");

    // Log a message indicating the test is starting, with medium verbosity.
    `uvm_info("TEST", "Starting ALU sequence", UVM_MEDIUM)

    // Start the sequence on the agent’s sequencer within the environment.
    // This drives transactions to the DUT via the driver connected to the sequencer.
    seq.start(env.agent.sequencer);

    // Add a delay of 1,000,000 time units to allow the sequence to complete its
    // execution fully before dropping the objection. This ensures all transactions
    // are processed by the DUT and monitored.
    #1000000;

    // Drop the objection to signal that the test is complete, allowing the simulation
    // to proceed to the next phase and eventually terminate.
    phase.drop_objection(this);

    // Log a message indicating the test has finished, with medium verbosity.
    `uvm_info("TEST", "Test execution completed", UVM_MEDIUM)
  endtask
endclass

// End the inclusion guard, ensuring this file is processed only once.
`endif
