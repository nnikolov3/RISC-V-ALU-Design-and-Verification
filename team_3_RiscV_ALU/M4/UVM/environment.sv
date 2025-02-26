// Guard against multiple inclusion of this file to avoid redefinition errors
`ifndef ALU_ENV_SV
`define ALU_ENV_SV

// Include the UVM macros file, which provides useful macros like `uvm_component_utils`
`include "uvm_macros.svh"
// Import the UVM package, making all UVM classes and methods available
import uvm_pkg::*;

// Include the definitions of other components used in this environment
// These files contain the agent, scoreboard, and coverage classes
`include "agent.sv"
`include "scoreboard.sv"
`include "coverage.sv"

// Define the alu_env class, which serves as the top-level environment for ALU verification
// It extends uvm_env, the base UVM class for environments
class alu_env extends uvm_env;
    // Register the alu_env class with the UVM factory
    // This allows the class to be instantiated dynamically during simulation
    `uvm_component_utils(alu_env)

    // Declare class members for the key components of the environment
    // alu_agent handles driving and monitoring transactions to/from the DUT
    alu_agent      agent;
    // alu_scoreboard compares expected vs. actual results to verify DUT behavior
    alu_scoreboard scoreboard;
    // alu_coverage collects functional coverage data to ensure test completeness
    alu_coverage   coverage;

    // Constructor for the environment class
    // Parameters:
    // - name: A string specifying the instance name of this environment
    // - parent: The parent UVM component (e.g., a test) that instantiates this environment
    function new(string name, uvm_component parent);
        // Call the parent class (uvm_env) constructor to initialize the base class
        super.new(name, parent);
    endfunction

    // Build phase: This phase is executed before the simulation starts
    // It’s responsible for creating and configuring all components in the environment
    function void build_phase(uvm_phase phase);
        // Call the parent class’s build_phase to ensure proper initialization
        super.build_phase(phase);
        // Instantiate the agent using the UVM factory method
        // "agent" is the instance name, and "this" is the parent (the current environment)
        agent      = alu_agent::type_id::create("agent", this);
        // Instantiate the scoreboard using the UVM factory
        scoreboard = alu_scoreboard::type_id::create("scoreboard", this);
        // Instantiate the coverage collector using the UVM factory
        coverage   = alu_coverage::type_id::create("coverage", this);
        // Configure the agent to be active using the UVM configuration database
        // UVM_ACTIVE means the agent will drive transactions to the DUT
        uvm_config_db#(uvm_active_passive_enum)::set(this, "agent", "is_active", UVM_ACTIVE);
    endfunction

    // Connect phase: This phase runs after the build phase
    // It’s used to connect analysis ports and exports between components
    function void connect_phase(uvm_phase phase);
        // Connect the monitor’s analysis port (ap) to the scoreboard’s analysis import
        // This allows the scoreboard to receive transactions captured by the monitor
        agent.monitor.ap.connect(scoreboard.ap);
        // Connect the monitor’s analysis port to the coverage collector’s analysis export
        // This enables the coverage component to sample transactions for coverage analysis
        agent.monitor.ap.connect(coverage.analysis_export);
    endfunction
endclass

// End of the include guard
`endif
