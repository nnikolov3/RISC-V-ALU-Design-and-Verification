// ----------------------------------------------------------------------------
// Class: alu_env
// ECE 593
// Milestone 4 - RV32I ALU Environment
// Team 3
// Description:
//   This UVM environment serves as the top-level verification structure for
//   the RV32I Arithmetic Logic Unit (ALU) Device Under Test (DUT). It
//   integrates an agent for driving and monitoring transactions, a scoreboard
//   for verifying DUT behavior, and a coverage collector for assessing test
//   completeness. The environment configures and connects these components
//   to ensure comprehensive ALU verification.
// Updated: Feb 26, 2025
// ----------------------------------------------------------------------------

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
class alu_env extends uvm_env;
    // ------------------------------------------------------------------------
    // Registration: Factory Registration
    // Description:
    //   Registers the environment with the UVM factory for dynamic instantiation.
    // ------------------------------------------------------------------------
    `uvm_component_utils(alu_env)

    // ------------------------------------------------------------------------
    // Members: Components
    // Description:
    //   Declares the key components of the environment:
    //   - agent: Drives and monitors DUT transactions.
    //   - scoreboard: Compares expected vs. actual DUT outputs.
    //   - coverage: Collects functional coverage data.
    // ------------------------------------------------------------------------
    alu_agent      agent;
    alu_scoreboard scoreboard;
    alu_coverage   coverage;

    // ------------------------------------------------------------------------
    // Constructor: new
    // Description:
    //   Initializes the environment with a name and parent in the UVM hierarchy.
    // Arguments:
    //   - name: String identifier for the environment instance
    //   - parent: Parent UVM component (e.g., a test) in the hierarchy
    // ------------------------------------------------------------------------
    function new(string name, uvm_component parent);
        // Call the parent class constructor to initialize the base environment
        super.new(name, parent);
    endfunction

    // ------------------------------------------------------------------------
    // Function: build_phase
    // Description:
    //   Constructs and configures the environment’s components during the build
    //   phase. Instantiates the agent, scoreboard, and coverage collector, and
    //   sets the agent to active mode for driving the DUT.
    // Arguments:
    //   - phase: UVM phase object for synchronization
    // ------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        // Call the parent class’s build_phase for proper initialization
        super.build_phase(phase);
        // Instantiate the agent using the UVM factory
        agent      = alu_agent::type_id::create("agent", this);
        // Instantiate the scoreboard using the UVM factory
        scoreboard = alu_scoreboard::type_id::create("scoreboard", this);
        // Instantiate the coverage collector using the UVM factory
        coverage   = alu_coverage::type_id::create("coverage", this);
        // Configure the agent as active via the UVM configuration database
        // UVM_ACTIVE enables the agent to drive transactions to the DUT
        uvm_config_db#(uvm_active_passive_enum)::set(this, "agent", "is_active", UVM_ACTIVE);
    endfunction

    // ------------------------------------------------------------------------
    // Function: connect_phase
    // Description:
    //   Establishes connections between components during the connect phase.
    //   Links the monitor’s analysis port to the scoreboard and coverage
    //   collector for transaction analysis and coverage sampling.
    // Arguments:
    //   - phase: UVM phase object for synchronization
    // ------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        // Connect the monitor’s analysis port to the scoreboard’s analysis import
        // Enables the scoreboard to receive DUT transactions for verification
        agent.monitor.ap.connect(scoreboard.ap);
        // Connect the monitor’s analysis port to the coverage collector’s export
        // Allows the coverage component to sample transactions for coverage metrics
        agent.monitor.ap.connect(coverage.analysis_export);
    endfunction
endclass

// End of the include guard
`endif
