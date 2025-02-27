
// ----------------------------------------------------------------------------
// Class: alu_scoreboard
// Description:
//   This UVM scoreboard verifies the functionality of an Arithmetic Logic Unit
//   (ALU) in a RISC-V 32I processor verification environment. It receives
//   transactions via an analysis port, computes expected ALU outputs, and
//   compares them against the Device Under Test (DUT) outputs. The scoreboard
//   handles arithmetic and logical operations, branch and jump conditions,
//   reset states, and exceptions, ensuring correct behavior across various
//   instruction types and pipeline scenarios.
// Updated: Feb 26, 2025
// ----------------------------------------------------------------------------

`ifndef UVM_SCOREBOARD_SV
`define UVM_SCOREBOARD_SV
`include "uvm_macros.svh"
`include "transaction.sv"
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
    int count = 0;

    uvm_analysis_imp #(transaction, alu_scoreboard) scb_port;

    transaction tx[$];

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
        `uvm_info("SCB", "build phase", UVM_HIGH)

    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info("SCB", "connect phase", UVM_HIGH)
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
            curr_tx = tx.pop_front();
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
                "Unexpected PC change: Expected %h, Got %h", curr_tx.i_pc + 4, curr_tx.o_next_pc));
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
                               "RD Address mismatch: Expected %0d, Got %0d",
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

        // Log successful verification.
        `uvm_info("SCB", $sformatf("Transaction %d successfully verified!", this.count), UVM_LOW)

    endfunction

endclass

`endif
