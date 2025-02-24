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
class uvm_scoreboard extends uvm_component;
    `uvm_component_utils(uvm_scoreboard)

    // Input FIFO: Receives transactions from the input monitor.
    uvm_tlm_analysis_fifo#(transaction) in_fifo;

    // Output FIFO: Receives transactions from the output monitor.
    uvm_tlm_analysis_fifo#(transaction) out_fifo;

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
    function new(string name, uvm_component parent);
        super.new(name, parent);
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
        in_fifo  = new("in_fifo", this);
        out_fifo = new("out_fifo", this);
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
        transaction in_t, out_t;
        forever begin
            // Wait until both FIFOs have transactions to process.
            wait(in_fifo.used() > 0 && out_fifo.used() > 0);
            // Retrieve transactions from FIFOs.
            in_fifo.get(in_t);
            out_fifo.get(out_t);

            // Compare the transactions for correctness.
            compare_transactions(in_t, out_t);
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
    function void compare_transactions(transaction in_t, transaction out_t);
        // Compare program counters (PC).
        if (in_t.i_pc !== out_t.o_pc) begin
            `uvm_error("SCOREBOARD", $sformatf("PC mismatch: Expected %h, Got %h", in_t.i_pc, out_t.o_pc));
        end
        
        // Check for flush, stall, or force stall conditions.
        if (in_t.i_flush || in_t.i_stall || in_t.i_force_stall) begin
            if (out_t.o_change_pc !== 0) begin
                `uvm_error("SCOREBOARD", "Unexpected PC change during flush/stall!")
            end
        end else if (in_t.i_pc + 4 !== out_t.o_next_pc && out_t.o_change_pc) begin
            `uvm_error("SCOREBOARD", $sformatf("Unexpected PC change: Expected %h, Got %h", in_t.i_pc + 4, out_t.o_next_pc));
        end
        
        // Compare flush signals.
        if (in_t.i_flush !== out_t.o_flush) begin
            `uvm_error("SCOREBOARD", "Flush signal mismatch!");
        end
        
        // Check register write conditions.
        if (in_t.i_rd_addr != 0) begin
            if (in_t.i_ce && !in_t.i_stall) begin
                // Ensure write enable signal is set.
                if (!out_t.o_wr_rd) begin
                    `uvm_error("SCOREBOARD", "Missing register write enable!");
                end
                // Check if register address matches.
                if (out_t.o_rd_addr !== in_t.i_rd_addr) begin
                    `uvm_error("SCOREBOARD", $sformatf("RD Address mismatch: Expected %0d, Got %0d", in_t.i_rd_addr, out_t.o_rd_addr));
                end
                // Ensure RD Valid signal is set.
                if (out_t.o_rd_valid !== 1) begin
                    `uvm_error("SCOREBOARD", "RD Valid signal mismatch!");
                end
            end
        end
        
        // Compare stall signals.
        if (in_t.i_stall !== out_t.o_stall) begin
            `uvm_error("SCOREBOARD", "Stall signal mismatch!");
        end
        
        // Log successful verification.
        `uvm_info("SCOREBOARD", "Transaction successfully verified!", UVM_LOW)
    endfunction

endclass

`endif
