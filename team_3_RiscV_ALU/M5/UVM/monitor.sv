// ----------------------------------------------------------------------------
// Class: alu_monitor
// Description:
//   This UVM monitor observes both input and output signals of the RV32I ALU DUT
//   through a virtual interface. It captures these signals into a transaction object
//   and sends it to the scoreboard and other subscribers via an analysis port for
//   verification and coverage analysis.
// Updated: Mar 08, 2025
// ----------------------------------------------------------------------------
// Guard against multiple inclusions of this file in the compilation process.
// If UVM_MONITOR_SV is already defined elsewhere, this file won’t be reprocessed.
`ifndef UVM_MONITOR_SV
`define UVM_MONITOR_SV 

// Include UVM macro definitions for utility functions and reporting mechanisms.
`include "uvm_macros.svh"

// Import the UVM package to access its classes, methods, and infrastructure.
import uvm_pkg::*;

// Include header and transaction definitions for ALU-specific fields and the
// transaction class used by this monitor.
`include "rv32i_alu_header.sv"  // Provides ALU-specific constants and types.
`include "transaction.sv"  // Defines the transaction class for signal capture.

// Define the alu_monitor class, inheriting from uvm_monitor, a UVM component that
// observes DUT signals and broadcasts them as transactions via analysis ports.
class alu_monitor extends uvm_monitor;
  // Register the class with UVM’s factory, enabling type registration for dynamic
  // instantiation and overrides. This allows the factory to create or replace this
  // component during simulation setup, enhancing testbench flexibility.
  `uvm_component_utils(alu_monitor)

  // Virtual interface handle for accessing the DUT’s signals. This is retrieved
  // from the UVM configuration database during the build phase.
  virtual alu_if vif;

  // Integer handle for an external log file to record UVM messages during simulation.
  integer log_file;

  // Analysis port for broadcasting transaction objects to subscribers (e.g., scoreboard,
  // coverage collector). Parameterized with the transaction type for type safety.
  uvm_analysis_port #(transaction) mon2scb;

  // Constructor: Initializes the monitor with a name and parent component.
  // Creates the analysis port for communication with other components.
  // Parameters:
  // - name: A string specifying the instance name (defaults to "alu_monitor").
  // - parent: The parent UVM component (e.g., an agent) that instantiates this monitor.
  function new(string name = "alu_monitor", uvm_component parent);
    super.new(name, parent);  // Call the parent class (uvm_monitor) constructor.
    `uvm_info("MONITOR", "Inside constructor", UVM_HIGH)  // Log constructor entry.
    mon2scb = new("mon2scb", this);  // Instantiate the analysis port with the name "mon2scb".
  endfunction

  // Build phase: Configures the monitor and retrieves the virtual interface.
  // This phase runs before simulation starts, setting up necessary resources.
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);  // Call the parent class’s build_phase for initialization.

    // Open a log file in append mode to record UVM messages. The file handle is
    // stored in log_file for subsequent use.
    log_file = $fopen("uvm_log.txt", "a");

    // Check if the file opened successfully (non-zero handle indicates success).
    if (log_file) begin
      // Configure the UVM report server to control message handling:
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
      // ensuring consistent logging behavior across the monitor.
      set_report_default_file_hier(log_file);

      // Log a message confirming the report server configuration is complete.
      `uvm_info("MONITOR", "Set report server severities and outputs", UVM_NONE);
    end else begin
      // If the file failed to open, report an error to aid in debugging file system issues.
      `uvm_error("MONITOR", "Failed to open log file")
    end

    // Log a message indicating the build phase is executing, with high verbosity.
    `uvm_info("MONITOR", "Build phase", UVM_HIGH)

    // Retrieve the virtual interface from the UVM configuration database using the
    // key "alu_vif". If not found, issue a fatal error to halt simulation, as the
    // monitor cannot function without this interface.
    if (!uvm_config_db#(virtual alu_if)::get(this, "", "alu_vif", vif)) begin
      `uvm_fatal("MONITOR", "Virtual interface not set")
    end
  endfunction

  // Run phase: Executes during simulation to continuously sample DUT signals.
  // Captures inputs and outputs into a transaction object and sends it via the analysis port.
  virtual task run_phase(uvm_phase phase);
    transaction tx;  // Local handle for the transaction object.

    // Log a message indicating the monitor has started, with medium verbosity.
    `uvm_info("MONITOR", "Monitor started", UVM_MEDIUM)

    // Infinite loop to sample signals on each clock cycle.
    forever begin
      // Create a new transaction object using the UVM factory’s create method.
      tx = transaction::type_id::create("tx", this);

      // Wait for the input clock enable (i_ce) to be asserted before capturing input signals.
      wait (vif.i_ce) begin
        // Capture all input signals from the virtual interface into the transaction object.
        tx.rst_n         = vif.rst_n;  // Reset signal (active low).
        tx.i_alu         = vif.i_alu;  // ALU operation code.
        tx.i_rs1_addr    = vif.i_rs1_addr;  // Source register 1 address.
        tx.i_rs1         = vif.i_rs1;  // Source register 1 value.
        tx.i_rs2         = vif.i_rs2;  // Source register 2 value.
        tx.i_imm         = vif.i_imm;  // Immediate value.
        tx.i_funct3      = vif.i_funct3;  // 3-bit function code.
        tx.i_opcode      = vif.i_opcode;  // Instruction opcode.
        tx.i_exception   = vif.i_exception;  // Exception status.
        tx.i_pc          = vif.i_pc;  // Program counter value.
        tx.i_rd_addr     = vif.i_rd_addr;  // Destination register address.
        tx.i_ce          = vif.i_ce;  // Clock enable signal.
        tx.i_stall       = vif.i_stall;  // Pipeline stall signal.
        tx.i_force_stall = vif.i_force_stall;  // Forced stall signal.
        tx.i_flush       = vif.i_flush;  // Pipeline flush signal.
      end

      // Wait for the positive clock edge to synchronize output sampling with DUT timing.
      @(posedge vif.i_clk);

      // Capture all output signals from the virtual interface into the transaction object.
      tx.o_rs1_addr       = vif.o_rs1_addr;  // Bypassed source register 1 address.
      tx.o_rs1            = vif.o_rs1;  // Bypassed source register 1 value.
      tx.o_rs2            = vif.o_rs2;  // Bypassed source register 2 value.
      tx.o_imm            = vif.o_imm;  // Bypassed immediate value.
      tx.o_funct3         = vif.o_funct3;  // Bypassed 3-bit function code.
      tx.o_opcode         = vif.o_opcode;  // Bypassed instruction opcode.
      tx.o_exception      = vif.o_exception;  // Propagated exception status.
      tx.o_y              = vif.o_y;  // ALU computation result.
      tx.o_pc             = vif.o_pc;  // Current program counter value.
      tx.o_next_pc        = vif.o_next_pc;  // Next program counter value.
      tx.o_change_pc      = vif.o_change_pc;  // PC change request signal.
      tx.o_wr_rd          = vif.o_wr_rd;  // Write enable for destination register.
      tx.o_rd_addr        = vif.o_rd_addr;  // Destination register address.
      tx.o_rd             = vif.o_rd;  // Data for destination register.
      tx.o_rd_valid       = vif.o_rd_valid;  // Destination register data validity.
      tx.o_stall_from_alu = vif.o_stall_from_alu;  // ALU-generated stall request.
      tx.o_ce             = vif.o_ce;  // Propagated clock enable signal.
      tx.o_stall          = vif.o_stall;  // Combined stall signal.
      tx.o_flush          = vif.o_flush;  // Propagated flush signal.

      // Commented-out wait for o_ce is not active; outputs are captured regardless of o_ce.

      // Commented-out UVM_INFO blocks provide detailed logging of inputs and outputs
      // at medium verbosity but are currently disabled.

      // Send the completed transaction object to all subscribers (e.g., scoreboard,
      // coverage) via the analysis port’s write method.
      mon2scb.write(tx);
    end
  endtask
endclass

// End the inclusion guard, ensuring this file is processed only once.
`endif
