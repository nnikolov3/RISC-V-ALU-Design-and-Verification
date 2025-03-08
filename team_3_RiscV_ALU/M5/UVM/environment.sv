// ----------------------------------------------------------------------------
// Class: alu_env
// Description:
//   This module defines the top-level UVM environment for verifying an RV32I ALU.
//   It integrates an agent for driving and monitoring the DUT, a scoreboard for
//   comparing expected versus actual results, and a coverage collector for tracking
//   functional coverage. This environment orchestrates the verification process.
// Updated: Mar 08, 2025
// ----------------------------------------------------------------------------
// Guard against multiple inclusions of this file in the compilation process.
// If ALU_ENV_SV is already defined elsewhere, this file won’t be reprocessed.
`ifndef ALU_ENV_SV
`define ALU_ENV_SV 

// Include UVM macro definitions for utility functions and reporting mechanisms.
`include "uvm_macros.svh"

// Import the UVM package to access its classes, methods, and infrastructure.
import uvm_pkg::*;

// Include definitions of other components used in this environment.
// These files provide the agent, scoreboard, and coverage classes required for verification.
`include "agent.sv"  // Defines the alu_agent class for DUT interaction.
`include "scoreboard.sv"  // Defines the alu_scoreboard class for result checking.
`include "coverage.sv"  // Defines the alu_coverage class for coverage collection.

// Define the alu_env class, inheriting from uvm_env, a UVM base class that provides
// a container for integrating multiple verification components into a cohesive environment.
class alu_env extends uvm_env;
  // Register the class with UVM’s factory, enabling type registration for dynamic
  // instantiation and overrides. This allows the factory to create or replace this
  // component during simulation setup, enhancing testbench flexibility.
  `uvm_component_utils(alu_env)

  // Virtual interface handle for connecting to the DUT’s signals. This is intended
  // to be set via the UVM configuration database, though currently commented out.
  virtual alu_if dut_if;

  // Declare class members for the key components of the environment:
  // - agent: An alu_agent instance that manages transaction driving and monitoring.
  // - scoreboard: An alu_scoreboard instance that verifies DUT outputs against expected results.
  // - coverage: An alu_coverage instance that collects functional coverage data.
  alu_agent      agent;
  alu_scoreboard scoreboard;
  alu_coverage   coverage;

  // Constructor: Initializes the environment with a name and parent component.
  // The parent argument ties this environment into the UVM hierarchy, typically a test.
  function new(string name, uvm_component parent);
    super.new(name, parent);  // Call the parent class (uvm_env) constructor.
  endfunction

  // Build phase: Configures and instantiates the environment’s components.
  // This phase runs before simulation starts, setting up the verification structure.
  function void build_phase(uvm_phase phase);
    // Call the parent class’s build_phase to ensure proper initialization.
    super.build_phase(phase);

    // Log a message indicating the environment is being built, with no verbosity filtering.
    `uvm_info("ENV", "ENV Building", UVM_NONE);

    // Instantiate the agent using the UVM factory’s create method. The instance name
    // is "agent", and the parent is this environment (this).
    agent      = alu_agent::type_id::create("agent", this);

    // Instantiate the scoreboard using the UVM factory’s create method. The instance
    // name is "scoreboard", and the parent is this environment.
    scoreboard = alu_scoreboard::type_id::create("scoreboard", this);

    // Instantiate the coverage collector using the UVM factory’s create method. The
    // instance name is "coverage", and the parent is this environment.
    coverage   = alu_coverage::type_id::create("coverage", this);

    // Configure the UVM report server to control message handling for this hierarchy:
    // - UVM_INFO: Display on console and log to file for informational messages.
    // - UVM_WARNING: Log to file only to reduce console output.
    // - UVM_ERROR: Display and log to ensure errors are both visible and recorded.
    set_report_severity_action_hier(UVM_INFO, UVM_DISPLAY | UVM_LOG);
    set_report_severity_action_hier(UVM_WARNING, UVM_LOG);
    set_report_severity_action_hier(UVM_ERROR, UVM_LOG | UVM_DISPLAY);

    // Commented-out line to set the virtual interface in the config database:
    // uvm_config_db#(virtual alu_if)::set(null, "*", "alu_vif", dut_if);
    // This is not currently active but would typically pass the interface to all components.

    // Set the agent’s is_active field in the UVM configuration database to UVM_ACTIVE.
    // This configures the agent to drive transactions to the DUT, enabling its driver
    // and sequencer components during the build phase of the agent.
    uvm_config_db#(uvm_active_passive_enum)::set(this, "agent", "is_active", UVM_ACTIVE);
  endfunction

  // Connect phase: Establishes connections between components after they are built.
  // This phase ensures proper data flow using UVM’s Transaction-Level Modeling (TLM) ports.
  function void connect_phase(uvm_phase phase);
    // Connect the monitor’s analysis port (mon2scb) to the scoreboard’s analysis import
    // (scb_port). This allows the scoreboard to receive transactions observed by the
    // monitor for comparison against expected results.
    agent.monitor.mon2scb.connect(scoreboard.scb_port);

    // Connect the monitor’s analysis port (mon2scb) to the coverage collector’s analysis
    // export (analysis_export). This enables the coverage component to receive transactions
    // from the monitor and sample them for functional coverage analysis.
    agent.monitor.mon2scb.connect(coverage.analysis_export);
  endfunction
endclass

// End the inclusion guard, ensuring this file is processed only once.
`endif
