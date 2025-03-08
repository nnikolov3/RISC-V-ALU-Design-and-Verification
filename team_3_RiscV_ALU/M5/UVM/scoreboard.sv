// ----------------------------------------------------------------------------
// Class: alu_scoreboard
// Description:
//   This UVM scoreboard receives transactions from the monitor via an analysis
//   port and verifies the correctness of the RV32I ALU DUT’s behavior. It compares
//   input and output signals, including ALU operations, program counter (PC),
//   flush, stall, and register write conditions, logging errors for mismatches
//   and info messages for successful checks.
// Updated: Mar 08, 2025
// ----------------------------------------------------------------------------
// Guard against multiple inclusions of this file in the compilation process.
// If UVM_SCOREBOARD_SV is already defined elsewhere, this file won’t be reprocessed.
`ifndef UVM_SCOREBOARD_SV
`define UVM_SCOREBOARD_SV 

// Include UVM macro definitions for utility functions and reporting mechanisms.
`include "uvm_macros.svh"

// Include transaction and header definitions for signal fields and ALU-specific constants.
`include "transaction.sv"  // Defines the transaction class for signal data.
`include "rv32i_alu_header.sv"  // Defines ALU operations, opcodes, and widths.

// Import the UVM package to access its classes, methods, and infrastructure.
import uvm_pkg::*;

// Define the alu_scoreboard class, inheriting from uvm_scoreboard, a UVM component
// that facilitates verification by comparing observed DUT behavior against expected results.
class alu_scoreboard extends uvm_scoreboard;
  // Register the class with UVM’s factory, enabling type registration for dynamic
  // instantiation and overrides. This allows the factory to create or replace this
  // component during simulation setup, enhancing testbench flexibility.
  `uvm_component_utils(alu_scoreboard)

  // Counter to track the number of transactions processed.
  int count = 0;

  // Analysis import for receiving transactions from the monitor’s analysis port.
  // Parameterized with transaction type and bound to this scoreboard for callback.
  uvm_analysis_imp #(transaction, alu_scoreboard) scb_port;

  // Integer handle for an external log file to record UVM messages during simulation.
  integer log_file;

  // Queue to store incoming transactions until they are processed in the run phase.
  transaction tx[$];

  // Constructor: Initializes the scoreboard with a name and parent component.
  // Parameters:
  // - name: A string specifying the instance name (defaults to "alu_scoreboard").
  // - parent: The parent UVM component (e.g., an environment) that instantiates this scoreboard.
  function new(string name = "alu_scoreboard", uvm_component parent);
    super.new(name, parent);  // Call the parent class (uvm_scoreboard) constructor.
    `uvm_info("SCB", "Inside constructor", UVM_HIGH)  // Log constructor entry with high verbosity.
  endfunction

  // Build phase: Configures the scoreboard and initializes its resources.
  // This phase runs before simulation starts, setting up the analysis port and logging.
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);  // Call the parent class’s build_phase for initialization.

    // Instantiate the analysis import to receive transactions from the monitor.
    scb_port = new("scb_port", this);

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
      // ensuring consistent logging behavior across the scoreboard.
      set_report_default_file_hier(log_file);

      // Log a message confirming the report server configuration is complete.
      `uvm_info("SCB", "Set report server severities and outputs", UVM_NONE);
    end else begin
      // If the file failed to open, report an error to aid in debugging file system issues.
      `uvm_error("SCB", "Failed to open log file")
    end

    // Log a message indicating the build phase is executing, with high verbosity.
    `uvm_info("SCB", "build phase", UVM_HIGH)
  endfunction

  // Write function: Callback for the analysis import to receive transactions.
  // Stores each incoming transaction in the queue for processing in the run phase.
  function void write(transaction item);
    tx.push_back(item);  // Add the transaction to the end of the queue.
  endfunction

  // Run phase: Executes during simulation to process and compare transactions.
  // Continuously checks the queue and verifies each transaction’s signals.
  task run_phase(uvm_phase phase);
    transaction curr_tx;  // Local handle for the current transaction being processed.

    // Log a message indicating the scoreboard has started, with medium verbosity.
    `uvm_info("SCB", "SCB started", UVM_MEDIUM)

    // Infinite loop to process transactions as they become available in the queue.
    forever begin
      // Wait until the queue has at least one transaction to process.
      wait (tx.size() > 0);

      // Retrieve the next transaction from the front of the queue and increment the counter.
      curr_tx    = tx.pop_front();
      this.count = this.count + 1;

      // Compare the transaction’s input and output signals for correctness.
      compare_transactions(curr_tx);
    end
  endtask

  // Compare transactions: Verifies the DUT’s behavior by checking key signals.
  // Logs detailed transaction data and reports errors for mismatches.
  function void compare_transactions(transaction curr_tx);
    string alu_op_str;  // String representation of the ALU operation.
    string opcode_str;  // String representation of the input opcode.
    string o_opcode_str;  // String representation of the output opcode.

    // Map the ALU operation (one-hot encoded) to a string based on indices from rv32i_alu_header.sv.
    case (1)
      curr_tx.i_alu[`ADD]:  alu_op_str = "ADD";  // Addition operation.
      curr_tx.i_alu[`SUB]:  alu_op_str = "SUB";  // Subtraction operation.
      curr_tx.i_alu[`SLT]:  alu_op_str = "SLT";  // Signed less than comparison.
      curr_tx.i_alu[`SLTU]: alu_op_str = "SLTU";  // Unsigned less than comparison.
      curr_tx.i_alu[`XOR]:  alu_op_str = "XOR";  // Bitwise XOR operation.
      curr_tx.i_alu[`OR]:   alu_op_str = "OR";  // Bitwise OR operation.
      curr_tx.i_alu[`AND]:  alu_op_str = "AND";  // Bitwise AND operation.
      curr_tx.i_alu[`SLL]:  alu_op_str = "SLL";  // Shift left logical.
      curr_tx.i_alu[`SRL]:  alu_op_str = "SRL";  // Shift right logical.
      curr_tx.i_alu[`SRA]:  alu_op_str = "SRA";  // Shift right arithmetic.
      curr_tx.i_alu[`EQ]:   alu_op_str = "EQ";  // Equality comparison.
      curr_tx.i_alu[`NEQ]:  alu_op_str = "NEQ";  // Inequality comparison.
      curr_tx.i_alu[`GE]:   alu_op_str = "GE";  // Signed greater or equal comparison.
      curr_tx.i_alu[`GEU]:  alu_op_str = "GEU";  // Unsigned greater or equal comparison.
      default:              alu_op_str = "UNKNOWN";  // Unrecognized operation.
    endcase

    // Map the input opcode to a string based on values from rv32i_alu_header.sv.
    case (curr_tx.i_opcode)
      `RTYPE_BITS:  opcode_str = "R_TYPE";  // R-type instruction.
      `ITYPE_BITS:  opcode_str = "I_TYPE";  // I-type instruction.
      `LOAD_BITS:   opcode_str = "LOAD";  // Load instruction.
      `STORE_BITS:  opcode_str = "STORE";  // Store instruction.
      `BRANCH_BITS: opcode_str = "BRANCH";  // Branch instruction.
      `JAL_BITS:    opcode_str = "JAL";  // Jump and link instruction.
      `JALR_BITS:   opcode_str = "JALR";  // Jump and link register instruction.
      `LUI_BITS:    opcode_str = "LUI";  // Load upper immediate instruction.
      `AUIPC_BITS:  opcode_str = "AUIPC";  // Add upper immediate to PC instruction.
      `SYSTEM_BITS: opcode_str = "SYSTEM";  // System instruction.
      `FENCE_BITS:  opcode_str = "FENCE";  // Fence instruction.
      default:      opcode_str = "UNKNOWN";  // Unrecognized opcode.
    endcase

    // Map the output opcode to a string based on values from rv32i_alu_header.sv.
    case (curr_tx.o_opcode)
      `RTYPE_BITS:  o_opcode_str = "R_TYPE";  // R-type instruction.
      `ITYPE_BITS:  o_opcode_str = "I_TYPE";  // I-type instruction.
      `LOAD_BITS:   o_opcode_str = "LOAD";  // Load instruction.
      `STORE_BITS:  o_opcode_str = "STORE";  // Store instruction.
      `BRANCH_BITS: o_opcode_str = "BRANCH";  // Branch instruction.
      `JAL_BITS:    o_opcode_str = "JAL";  // Jump and link instruction.
      `JALR_BITS:   o_opcode_str = "JALR";  // Jump and link register instruction.
      `LUI_BITS:    o_opcode_str = "LUI";  // Load upper immediate instruction.
      `AUIPC_BITS:  o_opcode_str = "AUIPC";  // Add upper immediate to PC instruction.
      `SYSTEM_BITS: o_opcode_str = "SYSTEM";  // System instruction.
      `FENCE_BITS:  o_opcode_str = "FENCE";  // Fence instruction.
      default:      o_opcode_str = "UNKNOWN";  // Unrecognized opcode.
    endcase

    // Log input signals of the current transaction with medium verbosity.
    `uvm_info("SCB", $sformatf(
              "\n***** Transaction %d Inputs *****\nOperation Type: %s\nRS1_ADDR: %h\nRS1: %h\nRS2: %h\nIMM: %h\nFUNCT3: %h\nInstruction Type: %s\nException: %b\nPC: %h\nRD_ADDR: %h\nCE: %b\nSTALL: %h\nFORCE_STALL: %h\nFLUSH: %h\nRST_N: %h"
                  ,
              this.count,
              alu_op_str,
              curr_tx.i_rs1_addr,
              curr_tx.i_rs1,
              curr_tx.i_rs2,
              curr_tx.i_imm,
              curr_tx.i_funct3,
              opcode_str,
              curr_tx.i_exception,
              curr_tx.i_pc,
              curr_tx.i_rd_addr,
              curr_tx.i_ce,
              curr_tx.i_stall,
              curr_tx.i_force_stall,
              curr_tx.i_flush,
              curr_tx.rst_n
              ), UVM_MEDIUM);

    // Log output signals of the current transaction with medium verbosity.
    `uvm_info("SCB", $sformatf(
              "\n***** Transaction %d Outputs *****\nRS1_ADDR: %h\nRS1: %h\nRS2: %h\nIMM: %h\nFUNCT3: %h\nInstruction Type: %s\nException: %b\nY: %h\nPC: %h\nNEXT_PC: %h\nCHANGE_PC: %h\nWR_RD: %h\nRD_ADDR: %h\nRD: %h\nRD_VALID: %h\nSTALL_FROM_ALU: %h\nCE: %b\nSTALL: %h\nFLUSH: %h"
                  ,
              this.count,
              curr_tx.o_rs1_addr,
              curr_tx.o_rs1,
              curr_tx.o_rs2,
              curr_tx.o_imm,
              curr_tx.o_funct3,
              o_opcode_str,
              curr_tx.o_exception,
              curr_tx.o_y,
              curr_tx.o_pc,
              curr_tx.o_next_pc,
              curr_tx.o_change_pc,
              curr_tx.o_wr_rd,
              curr_tx.o_rd_addr,
              curr_tx.o_rd,
              curr_tx.o_rd_valid,
              curr_tx.o_stall_from_alu,
              curr_tx.o_ce,
              curr_tx.o_stall,
              curr_tx.o_flush
              ), UVM_MEDIUM);

    // Check behavior based on reset state.
    if (curr_tx.rst_n === 0) begin
      // During reset, verify that exception, clock enable, and ALU stall signals are zero.
      if (curr_tx.o_exception !== 0 || curr_tx.o_ce !== 0 || curr_tx.o_stall_from_alu !== 0) begin
        `uvm_error("SCB", $sformatf(
                   "RESET ERROR: \no_exception: %h\no_ce: %h\no_stall_from_alu: %h",
                   curr_tx.o_exception,
                   curr_tx.o_ce,
                   curr_tx.o_stall_from_alu
                   ));
      end
    end else begin
      // Log entry into normal operation checking with no verbosity filtering.
      `uvm_info("SCB", $sformatf("Entered Checking, ALU op: %s", alu_op_str), UVM_NONE);

      // Verify ALU operation results.
      check_alu_operations(curr_tx);

      // Compare input and output program counters for consistency.
      if (curr_tx.i_pc !== curr_tx.o_pc) begin
        `uvm_error("SCB", $sformatf("PC mismatch: Expected %h, Got %h", curr_tx.i_pc, curr_tx.o_pc
                   ));
      end

      // Check PC change conditions under flush, stall, or force stall.
      if (curr_tx.i_flush || curr_tx.i_stall || curr_tx.i_force_stall) begin
        if (curr_tx.o_change_pc !== 0) begin
          `uvm_error("SCB", "Unexpected PC change during flush/stall!");
        end
      end else if (curr_tx.i_pc + 4 !== curr_tx.o_next_pc && curr_tx.o_change_pc) begin
        `uvm_error("SCB", $sformatf(
                   "Unexpected PC change: Expected %h, Got %h", curr_tx.i_pc + 4, curr_tx.o_next_pc
                   ));
      end

      // Compare input and output flush signals for consistency.
      if (curr_tx.i_flush !== curr_tx.o_flush) begin
        `uvm_error("SCB", "Flush signal mismatch!");
      end

      // Verify register write conditions when destination address is non-zero.
      if (curr_tx.i_rd_addr != 0) begin
        if (curr_tx.i_ce && !curr_tx.i_stall) begin
          // Check if write enable is set when clock is enabled and not stalled.
          if (!curr_tx.o_wr_rd) begin
            `uvm_error("SCB", "Missing register write enable!");
          end

          // Compare input and output destination register addresses.
          if (curr_tx.o_rd_addr !== curr_tx.i_rd_addr) begin
            `uvm_error(
                "SCB", $sformatf(
                "RD Address mismatch: Expected %0h, Got %0h", curr_tx.i_rd_addr, curr_tx.o_rd_addr
                ));
          end

          // Verify the register data validity signal is set.
          if (curr_tx.o_rd_valid !== 1) begin
            `uvm_error("SCB", "RD Valid signal mismatch!");
          end
        end
      end

      // Compare input and output stall signals for consistency.
      if (curr_tx.i_stall !== curr_tx.o_stall) begin
        `uvm_error("SCB", "Stall signal mismatch!");
      end
    end

    // Log successful verification of the transaction with low verbosity.
    `uvm_info("SCB", $sformatf("Transaction %d successfully verified!", this.count), UVM_LOW)
  endfunction

  // Check ALU operations: Computes expected ALU output and compares with actual.
  function void check_alu_operations(transaction curr_tx);
    logic [31:0] expected_y;  // Expected ALU result based on operation and operands.

    // Select operand A based on opcode: PC for JAL/AUIPC, RS1 otherwise.
    bit [31:0] a = (curr_tx.i_opcode === `JAL_BITS || curr_tx.i_opcode === `AUIPC_BITS) ?
        curr_tx.i_pc : curr_tx.i_rs1;

    // Select operand B based on opcode: RS2 for R-type/BRANCH, IMM otherwise.
    bit [31:0] b = (curr_tx.i_opcode === `RTYPE_BITS || curr_tx.i_opcode === `BRANCH_BITS) ?
        curr_tx.i_rs2 : curr_tx.i_imm;

    // Log operands and operation for debugging with low verbosity.
    `uvm_info("SCB", $sformatf("A: %h\nB: %h\nOP: %h", a, b, curr_tx.i_alu), UVM_LOW)

    // Compute expected result based on the ALU operation (one-hot encoded).
    case (1)
      curr_tx.i_alu[`ADD]: expected_y = a + b;  // Addition.
      curr_tx.i_alu[`SUB]: expected_y = a - b;  // Subtraction.
      curr_tx.i_alu[`SLT]: expected_y = ($signed(a) < $signed(b)) ? 1 : 0;  // Signed less than.
      curr_tx.i_alu[`SLTU]: expected_y = (a < b) ? 1 : 0;  // Unsigned less than.
      curr_tx.i_alu[`XOR]: expected_y = a ^ b;  // Bitwise XOR.
      curr_tx.i_alu[`OR]: expected_y = a | b;  // Bitwise OR.
      curr_tx.i_alu[`AND]: expected_y = a & b;  // Bitwise AND.
      curr_tx.i_alu[`SLL]: expected_y = a << b[4:0];  // Shift left logical (5-bit shift).
      curr_tx.i_alu[`SRL]: expected_y = a >> b[4:0];  // Shift right logical (5-bit shift).
      curr_tx.i_alu[`SRA]:
      expected_y = $signed(a) >>> b[4:0];  // Shift right arithmetic (5-bit shift).
      curr_tx.i_alu[`EQ]: expected_y = (a == b) ? 1 : 0;  // Equality comparison.
      curr_tx.i_alu[`NEQ]: expected_y = (a != b) ? 1 : 0;  // Inequality comparison.
      curr_tx.i_alu[`GE]:
      expected_y = ($signed(a) >= $signed(b)) ? 1 : 0;  // Signed greater or equal.
      curr_tx.i_alu[`GEU]: expected_y = (a >= b) ? 1 : 0;  // Unsigned greater or equal.
      default: expected_y = 32'hDEADBEEF;  // Default value for unrecognized operation.
    endcase

    // Compare expected ALU result with actual output and report any mismatch.
    if (curr_tx.o_y !== expected_y) begin
      `uvm_error("SCB", $sformatf(
                 "ALU Operation Mismatch: Expected %h, Got %h", expected_y, curr_tx.o_y));
    end
  endfunction

endclass

// End the inclusion guard, ensuring this file is processed only once.
`endif
