// ----------------------------------------------------------------------------
// Class: alu_agent
// Description:
//   This UVM agent serves as a reusable verification component for testing an
//   Arithmetic Logic Unit (ALU). It can operate in active mode (driving stimulus
//   via a sequencer and driver) or passive mode (observing via a monitor). The
//   agent includes logging functionality to capture simulation messages and
//   supports flexible instantiation through the UVM factory.
// Updated: Mar 08, 2025
// ----------------------------------------------------------------------------
// Guard against multiple inclusions of this file in the compilation process.
// If ALU_AGENT_SV is already defined elsewhere, this file won’t be reprocessed.
`ifndef ALU_AGENT_SV
`define ALU_AGENT_SV 

// Include UVM macro definitions for utility functions and reporting mechanisms.
`include "uvm_macros.svh"

// Import the UVM package to access its classes, methods, and infrastructure.
import uvm_pkg::*;

// Include custom class definitions for the ALU agent: the transaction object,
// driver, and monitor, which are key building blocks for this verification component.
`include "transaction.sv"
`include "driver.sv"
`include "monitor.sv"

// Define the alu_agent class, inheriting from uvm_agent, which provides a framework
// for creating reusable, configurable verification components in UVM.
class alu_agent extends uvm_agent;
  // Register the class with UVM’s factory, a central mechanism that manages component
  // creation. This macro generates code to enable type registration, allowing the
  // factory to instantiate or override this class dynamically during simulation.
  // It supports swapping in a custom alu_agent variant without modifying the testbench.
  `uvm_component_utils(alu_agent)

  // Declare core components of the agent:
  // - sequencer: A uvm_sequencer parameterized with the transaction type, responsible
  //   for managing and dispatching sequences of transactions to the driver.
  // - driver: An alu_driver instance that takes transactions from the sequencer and
  //   translates them into pin-level signals for the Device Under Test (DUT).
  // - monitor: An alu_monitor instance that observes the DUT’s input/output signals,
  //   converting them into transaction objects for analysis or coverage collection.
  // - log_file: Integer handle for an external file to log UVM messages.
  uvm_sequencer #(transaction) sequencer;
  alu_driver                   driver;
  alu_monitor                  monitor;
  integer                      log_file;

  // Constructor: Initializes the agent with a name and parent component.
  // The parent links this agent into the UVM component hierarchy.
  function new(string name, uvm_component parent);
    super.new(name, parent);  // Call the parent class (uvm_agent) constructor.
  endfunction

  // Build phase: Configures and instantiates the agent’s components.
  // This phase runs before simulation starts, setting up the testbench structure.
  function void build_phase(uvm_phase phase);
    // Log a message indicating the agent is being built. UVM_NONE sets the verbosity level.
    `uvm_info("AGENT", "Agent Building", UVM_NONE);
    super.build_phase(phase);  // Execute the parent class’s build_phase first.

    // Instantiate the monitor unconditionally, as it’s needed regardless of whether
    // the agent is active (driving stimuli) or passive (only observing). The monitor
    // uses UVM’s analysis ports to send observed transactions to subscribers like
    // scoreboards or coverage collectors for verification purposes.
    monitor  = alu_monitor::type_id::create("monitor", this);

    // Open a log file in append mode to record UVM messages during simulation.
    // The file handle is stored in log_file for later use.
    log_file = $fopen("uvm_log.txt", "a");

    // Check if the file opened successfully (non-zero handle indicates success).
    if (log_file) begin
      // Configure the UVM report server to control how messages are handled:
      // - UVM_INFO: Display on console and log to file for informational messages.
      // - UVM_WARNING: Log to file only to reduce console output.
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
      // ensuring consistent logging behavior across the agent.
      set_report_default_file_hier(log_file);

      // Confirm that the report server configuration is complete.
      `uvm_info("AGENT", "Set report server severities and outputs", UVM_NONE);
    end else begin
      // If the file failed to open, report an error to aid in debugging file system issues.
      `uvm_error("AGENT", "Failed to open log file")
    end

    // Check if the agent is active (driving stimuli) or passive (only monitoring).
    // If active, instantiate the sequencer and driver to generate and drive transactions.
    if (get_is_active() == UVM_ACTIVE) begin
      // Create the sequencer, a UVM component that coordinates sequences and sends
      // transaction objects to the driver. It’s parameterized with the transaction
      // type to ensure compatibility.
      sequencer = uvm_sequencer#(transaction)::type_id::create("sequencer", this);
      // Create the driver, which connects to the DUT’s interface and drives signals
      // based on transactions received from the sequencer. It’s customized for ALU operations.
      driver    = alu_driver::type_id::create("driver", this);
    end
  endfunction

  // Connect phase: Establishes connections between components after they’re built.
  // This phase ensures data flows correctly between components.
  function void connect_phase(uvm_phase phase);
    // If the agent is active, connect the driver’s sequence item port to the
    // sequencer’s export. This sets up a Transaction-Level Modeling (TLM) connection,
    // enabling the sequencer to send transactions to the driver for DUT stimulation.
    if (get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction
endclass

// End the inclusion guard, ensuring this file is processed only once.
`endif
