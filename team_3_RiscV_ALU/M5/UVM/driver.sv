// ----------------------------------------------------------------------------
// ECE593 - RV32I ALU Driver
// Description:
//   This module implements a UVM driver for the RV32I ALU DUT.
//   It drives the DUT's input signals based on transactions received from the sequencer.
//
//   Note: The virtual interface (alu_if) must be set in the UVM configuration
//         database with the key "alu_vif" prior to simulation.
// Updated: Mar 08, 2025
// ----------------------------------------------------------------------------
// Include UVM macro definitions for utility functions and reporting mechanisms.
`include "uvm_macros.svh"

// Import the UVM package to access its classes, methods, and infrastructure.
import uvm_pkg::*;

// Include header and transaction definitions for ALU-specific fields and the
// transaction class used by this driver.
`include "rv32i_alu_header.sv"  // Provides ALU-specific constants and interface definitions.
`include "transaction.sv"  // Defines the transaction class for driving DUT inputs.

// Guard against multiple inclusions of this file in the compilation process.
// If ALU_DRV_SV is already defined elsewhere, this file won’t be reprocessed.
`ifndef ALU_DRV_SV
`define ALU_DRV_SV 

// Define the alu_driver class, inheriting from uvm_driver, a UVM component that
// receives transactions from a sequencer and drives them to the DUT via an interface.
class alu_driver extends uvm_driver #(transaction);
  // Register the class with UVM’s factory, enabling type registration for dynamic
  // instantiation and overrides. This allows the factory to create or replace this
  // component during simulation setup, enhancing testbench flexibility.
  `uvm_component_utils(alu_driver)

  // Virtual interface handle for connecting to the DUT’s signals. This is retrieved
  // from the UVM configuration database during the build phase.
  virtual alu_if drv_if;

  // Integer handle for an external log file to record UVM messages during simulation.
  integer log_file;

  // Constructor: Initializes the driver with a name and parent component.
  // The parent argument ties this driver into the UVM hierarchy.
  function new(string name, uvm_component parent);
    super.new(name, parent);  // Call the parent class (uvm_driver) constructor.
  endfunction

  // Build phase: Configures the driver and retrieves the virtual interface.
  // This phase runs before simulation starts, setting up necessary resources.
  function void build_phase(uvm_phase phase);
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
      // ensuring consistent logging behavior across the driver.
      set_report_default_file_hier(log_file);

      // Log a message confirming the report server configuration is complete.
      `uvm_info("DRV", "Set report server severities and outputs", UVM_NONE);
    end else begin
      // If the file failed to open, report an error to aid in debugging file system issues.
      `uvm_error("DRV", "Failed to open log file")
    end

    // Log a message indicating the driver is being built, with no verbosity filtering.
    `uvm_info("DRV", "DRIVER Building", UVM_NONE);

    // Call the parent class’s build_phase to ensure proper initialization.
    super.build_phase(phase);

    // Retrieve the virtual interface from the UVM configuration database using the
    // key "alu_vif". If not found, issue a fatal error to halt simulation, as the
    // driver cannot function without this interface.
    if (!uvm_config_db#(virtual alu_if)::get(this, "", "alu_vif", drv_if)) begin
      `uvm_fatal("DRV", "Virtual interface not found in config db with key 'alu_vif'")
    end
  endfunction

  // Run phase: Executes during simulation to process transactions from the sequencer.
  // This task runs indefinitely, driving transactions to the DUT as they arrive.
  task run_phase(uvm_phase phase);
    transaction tx;  // Local handle for the transaction object.

    // Infinite loop to continuously fetch and drive transactions.
    forever begin
      // Request the next transaction from the sequencer via the seq_item_port,
      // a built-in TLM port provided by uvm_driver for communication with the sequencer.
      seq_item_port.get_next_item(tx);

      // Drive the transaction’s data to the DUT using the drive_item task.
      drive_item(tx);

      // Signal to the sequencer that the transaction has been processed, allowing
      // it to send the next item. This completes the TLM handshake.
      seq_item_port.item_done();
    end
  endtask

  // drive_item: Drives the DUT input signals based on the provided transaction.
  // This task handles reset conditions and normal operation, synchronizing with the clock.
  // @param tx - The transaction object containing the data for all DUT input signals.
  virtual task drive_item(transaction tx);
    // Log the transaction details at high verbosity for debugging purposes.
    `uvm_info("DRV", $sformatf("Driving transaction: %s", tx.convert2string()), UVM_HIGH)

    // Check the reset signal from the interface (not the transaction, as it’s a DUT input).
    if (!drv_if.i_rst_n) begin
      // During reset, drive all DUT inputs to default (inactive) values to ensure
      // a known state. These assignments override any transaction data.
      drv_if.i_alu         <= 0;
      drv_if.i_rs1_addr    <= 0;
      drv_if.i_rs1         <= 0;
      drv_if.i_rs2         <= 0;
      drv_if.i_imm         <= 0;
      drv_if.i_funct3      <= 0;
      drv_if.i_opcode      <= 0;
      drv_if.i_pc          <= 0;
      drv_if.i_rd_addr     <= 0;
      drv_if.i_ce          <= 0;
      drv_if.i_stall       <= 0;
      drv_if.i_force_stall <= 0;
      drv_if.i_flush       <= 0;
    end else begin
      // When reset is not active, drive the DUT inputs using the transaction data.
      // Assignments use the clocking block (cb_input) defined in alu_if for timing alignment.
      drv_if.cb_input.i_alu         <= tx.i_alu;  // ALU operation code.
      drv_if.cb_input.i_rs1_addr    <= tx.i_rs1_addr;  // Source register 1 address.
      drv_if.cb_input.i_rs1         <= tx.i_rs1;  // Source register 1 value.
      drv_if.cb_input.i_rs2         <= tx.i_rs2;  // Source register 2 value.
      drv_if.cb_input.i_imm         <= tx.i_imm;  // Immediate value.
      drv_if.cb_input.i_funct3      <= tx.i_funct3;  // Function code (3-bit).
      drv_if.cb_input.i_opcode      <= tx.i_opcode;  // Instruction opcode.
      drv_if.cb_input.i_pc          <= tx.i_pc;  // Program counter value.
      drv_if.cb_input.i_rd_addr     <= tx.i_rd_addr;  // Destination register address.
      drv_if.cb_input.i_ce          <= tx.i_ce;  // Clock enable signal.
      drv_if.cb_input.i_stall       <= tx.i_stall;  // Pipeline stall signal.
      drv_if.cb_input.i_force_stall <= tx.i_force_stall;  // Forced stall signal.
      drv_if.cb_input.i_flush       <= tx.i_flush;  // Pipeline flush signal.
      drv_if.cb_input.rst_n         <= tx.rst_n;  // Reset signal (active low).

      /* Commented-out fallback code without clocking block is available but not used:
         drv_if.i_alu <= tx.i_alu; drv_if.i_rs1_addr <= tx.i_rs1_addr; etc.
         This would apply if cb_input were not defined in alu_if. */

      /* Commented-out UVM_INFO block provides detailed logging of all inputs at
         medium verbosity, including i_exception, which is not driven here but
         could be relevant for debugging or scoreboard use. */
    end

    // Wait for the positive clock edge to ensure signals are driven synchronously
    // with the DUT’s clock, aligning with typical hardware timing requirements.
    @(posedge drv_if.i_clk);
  endtask
endclass

// End the inclusion guard, ensuring this file is processed only once.
`endif
