`ifndef UVM_SCOREBOARD_SV
`define UVM_SCOREBOARD_SV 
`include "uvm_macros.svh"
`include "transaction.sv"
`include "rv32i_alu_header.sv"  // Defines ALU operations, opcodes, and widths
import uvm_pkg::*;

//-----------------------------------------------------------------------------
// Class: uvm_scoreboard
//
// Description:
//   This scoreboard collects transactions from input and output FIFOs and
//   compares them to check for mismatches in the expected behavior of the DUT.
//   The scoreboard checks the correctness of signals like PC, flush, stall,
//   register write enables, and address validity. If a mismatch is found,
//   an error message is logged. Successful comparisons are reported via
//   UVM info.
//-----------------------------------------------------------------------------
class alu_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(alu_scoreboard)
    int                                             count         = 0;

    uvm_analysis_imp #(transaction, alu_scoreboard) scb_port;
    integer                                         log_file;
    transaction                                     tx       [$];

    //-------------------------------------------------------------------------
    // Constructor: new
    //
    // Description:
    //   Initializes the scoreboard with its name and parent component.
    //
    // Parameters:
    //   name   - The name of the scoreboard component.
    //   parent - The parent component to which this scoreboard belongs.
    //-------------------------------------------------------------------------
    function new(string name = "alu_scoreboard", uvm_component parent);
        super.new(name, parent);
        `uvm_info("SCB", "Inside constructor", UVM_HIGH)
    endfunction

    //-------------------------------------------------------------------------
    // Build phase: Initialize FIFOs
    //
    // Description:
    //   The build phase initializes the input and output FIFOs that will
    //   hold the captured transactions. These FIFOs will be populated by
    //   the monitors.
    //
    // Parameters:
    //   phase - The current phase of the simulation.
    //-------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Initialize FIFOs
        scb_port = new("scb_port", this);

        log_file = $fopen("uvm_log.txt", "a");

        if (log_file) begin
            // Set the report server to write to the file
            set_report_severity_action_hier(
                UVM_INFO, UVM_DISPLAY | UVM_LOG);  // Ensure info messages are displayed and logged
            set_report_severity_action_hier(UVM_WARNING, UVM_LOG);  // Log warnings
            set_report_severity_action_hier(UVM_ERROR,
                                            UVM_LOG | UVM_DISPLAY);  // Log and display errors

            set_report_severity_file_hier(
                UVM_INFO, log_file);  // Ensure the info messages go to the log file
            set_report_severity_file_hier(UVM_WARNING, log_file);
            set_report_severity_file_hier(UVM_ERROR, log_file);
            //set_report_id_file("ENV", log_file);
            set_report_default_file_hier(log_file);
            `uvm_info("SCB", "Set report server severities and outputs", UVM_NONE);
        end else begin
            `uvm_error("SCB", "Failed to open log file")
        end
        `uvm_info("SCB", "build phase", UVM_HIGH)
    endfunction

    function void write(transaction item);
        tx.push_back(item);
    endfunction
    //-------------------------------------------------------------------------
    // Run phase: Continuously compare transactions from both FIFOs
    //
    // Description:
    //   The run phase continuously checks if both input and output FIFOs
    //   have available transactions. Once they do, the transactions are
    //   retrieved from both FIFOs and passed to the comparison function.
    //   This phase runs in a continuous loop throughout the simulation.
    //
    // Parameters:
    //   phase - The current phase of the simulation.
    //-------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        transaction curr_tx;
        `uvm_info("SCB", "SCB started", UVM_MEDIUM)
        forever begin
            // Wait until both FIFOs have transactions to process.
            wait (tx.size() > 0);
            // Retrieve transactions from FIFOs.
            curr_tx    = tx.pop_front();
            this.count = this.count + 1;

            // Compare the transactions for correctness.
            compare_transactions(curr_tx);
        end

    endtask

    //-------------------------------------------------------------------------
    // Function: compare_transactions
    //
    // Description:
    //   This function compares two transactions, one from the input FIFO
    //   (in_t) and one from the output FIFO (out_t). The function checks
    //   for mismatches in important signals, including the program counter
    //   (PC), flush, stall, register write enable, and register address.
    //   If any mismatches are found, an error is logged. If the comparison
    //   is successful, an info message is logged.
    //
    // Parameters:
    //   in_t  - The input transaction to compare.
    //   out_t - The output transaction to compare.
    //-------------------------------------------------------------------------
    function void compare_transactions(transaction curr_tx);
        string alu_op_str;
        string opcode_str;
        string o_opcode_str;

        // Map ALU operation index to string based on rv32i_alu_header.sv
        case (1)
            curr_tx.i_alu[`ADD]:  alu_op_str = "ADD";
            curr_tx.i_alu[`SUB]:  alu_op_str = "SUB";
            curr_tx.i_alu[`SLT]:  alu_op_str = "SLT";
            curr_tx.i_alu[`SLTU]: alu_op_str = "SLTU";
            curr_tx.i_alu[`XOR]:  alu_op_str = "XOR";
            curr_tx.i_alu[`OR]:   alu_op_str = "OR";
            curr_tx.i_alu[`AND]:  alu_op_str = "AND";
            curr_tx.i_alu[`SLL]:  alu_op_str = "SLL";
            curr_tx.i_alu[`SRL]:  alu_op_str = "SRL";
            curr_tx.i_alu[`SRA]:  alu_op_str = "SRA";
            curr_tx.i_alu[`EQ]:   alu_op_str = "EQ";
            curr_tx.i_alu[`NEQ]:  alu_op_str = "NEQ";
            curr_tx.i_alu[`GE]:   alu_op_str = "GE";
            curr_tx.i_alu[`GEU]:  alu_op_str = "GEU";
            default:              alu_op_str = "UNKNOWN";
        endcase

        // Map opcode to string based on rv32i_alu_header.sv
        case (curr_tx.i_opcode)
            `RTYPE_BITS:  opcode_str = "R_TYPE";
            `ITYPE_BITS:  opcode_str = "I_TYPE";
            `LOAD_BITS:   opcode_str = "LOAD";
            `STORE_BITS:  opcode_str = "STORE";
            `BRANCH_BITS: opcode_str = "BRANCH";
            `JAL_BITS:    opcode_str = "JAL";
            `JALR_BITS:   opcode_str = "JALR";
            `LUI_BITS:    opcode_str = "LUI";
            `AUIPC_BITS:  opcode_str = "AUIPC";
            `SYSTEM_BITS: opcode_str = "SYSTEM";
            `FENCE_BITS:  opcode_str = "FENCE";
            default:      opcode_str = "UNKNOWN";
        endcase
        case (curr_tx.o_opcode)
            `RTYPE_BITS:  o_opcode_str = "R_TYPE";
            `ITYPE_BITS:  o_opcode_str = "I_TYPE";
            `LOAD_BITS:   o_opcode_str = "LOAD";
            `STORE_BITS:  o_opcode_str = "STORE";
            `BRANCH_BITS: o_opcode_str = "BRANCH";
            `JAL_BITS:    o_opcode_str = "JAL";
            `JALR_BITS:   o_opcode_str = "JALR";
            `LUI_BITS:    o_opcode_str = "LUI";
            `AUIPC_BITS:  o_opcode_str = "AUIPC";
            `SYSTEM_BITS: o_opcode_str = "SYSTEM";
            `FENCE_BITS:  o_opcode_str = "FENCE";
            default:      o_opcode_str = "UNKNOWN";
        endcase
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

        if (curr_tx.rst_n === 0) begin
            if (curr_tx.o_exception !== 0 && curr_tx.o_ce !== 0 &&
                curr_tx.o_stall_from_alu !== 0) begin
                `uvm_error("SCB", $sformatf(
                           "RESET ERROR: \no_exception: %h\no_ce: %h\no_stall_from_alu: %h",
                           curr_tx.o_exception,
                           curr_tx.o_ce,
                           curr_tx.o_stall_from_alu
                           ));
            end
        end else begin
            `uvm_info("SCB", $sformatf("Entered Checking, ALU op: %s", alu_op_str), UVM_NONE);
            check_alu_operations(curr_tx);
            // Compare program counters (PC).
            if (curr_tx.i_pc !== curr_tx.o_pc) begin
                `uvm_error("SCB", $sformatf(
                           "PC mismatch: Expected %h, Got %h", curr_tx.i_pc, curr_tx.o_pc));
            end

            // Check for flush, stall, or force stall conditions.
            if (curr_tx.i_flush || curr_tx.i_stall || curr_tx.i_force_stall) begin
                if (curr_tx.o_change_pc !== 0) begin
                    `uvm_error("SCB", "Unexpected PC change during flush/stall!")
                end

            end else if (curr_tx.i_pc + 4 !== curr_tx.o_next_pc && curr_tx.o_change_pc) begin
                `uvm_error(
                    "SCB", $sformatf(
                    "Unexpected PC change: Expected %h, Got %h", curr_tx.i_pc + 4, curr_tx.o_next_pc
                    ));
            end

            // Compare flush signals.
            if (curr_tx.i_flush !== curr_tx.o_flush) begin
                `uvm_error("SCB", "Flush signal mismatch!");
            end

            // Check register write conditions.
            if (curr_tx.i_rd_addr != 0) begin
                if (curr_tx.i_ce && !curr_tx.i_stall) begin
                    // Ensure write enable signal is set.
                    if (!curr_tx.o_wr_rd) begin
                        `uvm_error("SCB", "Missing register write enable!");
                    end

                    // Check if register address matches.
                    if (curr_tx.o_rd_addr !== curr_tx.i_rd_addr) begin
                        `uvm_error("SCB", $sformatf(
                                   "RD Address mismatch: Expected %0h, Got %0h",
                                   curr_tx.i_rd_addr,
                                   curr_tx.o_rd_addr
                                   ));
                    end

                    // Ensure RD Valid signal is set.
                    if (curr_tx.o_rd_valid !== 1) begin
                        `uvm_error("SCB", "RD Valid signal mismatch!");
                    end
                end
            end

            // Compare stall signals.
            if (curr_tx.i_stall !== curr_tx.o_stall) begin
                `uvm_error("SCB", "Stall signal mismatch!");
            end
        end
        // Log successful verification.
        `uvm_info("SCB", $sformatf("Transaction %d successfully verified!", this.count), UVM_LOW)
    endfunction

    function void check_alu_operations(transaction curr_tx);
        logic [31:0] expected_y;
        bit [31:0] a = (curr_tx.i_opcode === `JAL_BITS || curr_tx.i_opcode === `AUIPC_BITS) ?
            curr_tx.i_pc : curr_tx.i_rs1;  // a can either be pc or rs1
        bit [31:0] b = (curr_tx.i_opcode === `RTYPE_BITS || curr_tx.i_opcode === `BRANCH_BITS) ?
            curr_tx.i_rs2 : curr_tx.i_imm;  // b can either be rs2 or imm
        `uvm_info("SCB", $sformatf("A: %h\nB: %h\nOP: %h", a, b, curr_tx.i_alu), UVM_LOW)
        case (1)
            curr_tx.i_alu[`ADD]:  expected_y = a + b;
            curr_tx.i_alu[`SUB]:  expected_y = a - b;
            curr_tx.i_alu[`SLT]:  expected_y = ($signed(a) < $signed(b)) ? 1 : 0;
            curr_tx.i_alu[`SLTU]: expected_y = (a < b) ? 1 : 0;
            curr_tx.i_alu[`XOR]:  expected_y = a ^ b;
            curr_tx.i_alu[`OR]:   expected_y = a | b;
            curr_tx.i_alu[`AND]:  expected_y = a & b;
            curr_tx.i_alu[`SLL]:  expected_y = a << b[4:0];
            curr_tx.i_alu[`SRL]:  expected_y = a >> b[4:0];
            curr_tx.i_alu[`SRA]:  expected_y = $signed(a) >>> b[4:0];
            curr_tx.i_alu[`EQ]:   expected_y = (a == b) ? 1 : 0;
            curr_tx.i_alu[`NEQ]:  expected_y = (a != b) ? 1 : 0;
            curr_tx.i_alu[`GE]:   expected_y = ($signed(a) >= $signed(b)) ? 1 : 0;
            curr_tx.i_alu[`GEU]:  expected_y = (a >= b) ? 1 : 0;
            default:              expected_y = 32'hDEADBEEF;
        endcase

        if (curr_tx.o_y !== expected_y) begin
            `uvm_error("SCB", $sformatf(
                       "ALU Operation Mismatch: Expected %h, Got %h", expected_y, curr_tx.o_y));
        end
    endfunction

endclass

`endif
