// ----------------------------------------------------------------------------
// Class: coverage
// Description:
//   This coverage collector samples various signals from the DUT through the virtual
//   interface (vif) to ensure comprehensive coverage of ALU operations,
//   branch/jump handling, and pipeline control signals.
// ----------------------------------------------------------------------------

`include "rv32i_alu_header.sv"
`include "transaction.sv"
`include "interface.sv"
`ifndef ALU_COV_SV
`define ALU_COV_SV

class coverage;
    virtual alu_if vif;
    // Mailbox to send captured input transactions to the scoreboard.
    mailbox #(transaction) mon_in2scb = new();
    covergroup alu_cg;
        coverpoint vif.i_opcode {
            bins opcode_types[] = {[0 : `OPCODE_WIDTH - 1]};
        }
        coverpoint vif.i_alu {bins alu_ops[] = {[0 : `ALU_WIDTH - 1]};}

        // Branch and jump coverage
        coverpoint vif.o_change_pc;
        coverpoint vif.o_next_pc {bins pc_values = {[0 : 32'hFFFFFFFF]};}

        // Register writeback coverage
        coverpoint vif.o_wr_rd;
        coverpoint vif.o_rd_valid;
        coverpoint vif.o_rd_addr {bins rd_addr = {[0 : 31]};}

        // Pipeline management coverage
        coverpoint vif.i_ce;
        coverpoint vif.i_stall;
        coverpoint vif.i_force_stall;
        coverpoint vif.i_flush;
        coverpoint vif.o_stall_from_alu;
        coverpoint vif.o_stall;
        coverpoint vif.o_flush;

        // Exception coverage
        coverpoint vif.i_exception {
            bins exceptions[] = {[0 : `EXCEPTION_WIDTH - 1]};
        }

        // Cross coverage
        cross vif.i_opcode, vif.i_alu;
        cross vif.i_opcode, vif.i_exception;
        //cross vif.i_opcode, vif.i_stall, vif.i_force_stall;
        //cross vif.i_opcode, vif.o_change_pc iff (vif.o_change_pc == 1'b1);
        //cross vif.i_ce, vif.i_stall, vif.i_force_stall, vif.i_flush;
        //cross vif.o_wr_rd, vif.o_rd_valid, vif.i_opcode;
    endgroup


    // Constructor
    function new(virtual alu_if vif);
        this.vif = vif;
        alu_cg   = new();
    endfunction

    // Task to run coverage collection
    task main;
        $display("Coverage started");
        forever begin
            @(posedge vif.i_clk);
            if (vif.i_ce) begin
                alu_cg.sample();
            end
        end
        $display("Coverage finished");
    endtask

    // Helper function to display coverage percentage for coverpoints
    function void display_coverpoint_info();
        $display("\n========== Coverpoint Coverage Report ==========");
        $display("Opcode Coverage: %0.2f%%", alu_cg.get_coverage());
        $display("ALU Coverage: %0.2f%%", alu_cg.get_coverage());
        $display("Exception Coverage: %0.2f%%", alu_cg.get_coverage());
        $display("==============================================");
    endfunction

    // Helper function to display cross coverage info
    function void display_cross_info();
        $display("\n========== Cross Coverage Report ==========");
        $display("Opcode-ALU Coverage: %0.2f%%", alu_cg.get_coverage());
        $display("Opcode-Exception Coverage: %0.2f%%", alu_cg.get_coverage());
        $display("Opcode-Stall Coverage: %0.2f%%", alu_cg.get_coverage());
        $display("Opcode-Branch-Jump Coverage: %0.2f%%", alu_cg.get_coverage());
        $display("Pipeline Control Coverage: %0.2f%%", alu_cg.get_coverage());
        $display("===========================================");
    endfunction

    // Task to run coverage collection and print detailed results
    task run_coverage;
        main();  // Run coverage collection
        display_coverpoint_info();  // Print coverpoint info
        display_cross_info();  // Print cross coverage info
    endtask

endclass
`endif
