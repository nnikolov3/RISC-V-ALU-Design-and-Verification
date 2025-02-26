`ifndef ALU_MONITOR_SV
`define ALU_MONITOR_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "rv32i_alu_header.sv"
`include "transaction.sv"

class alu_monitor extends uvm_monitor;
    `uvm_component_utils(alu_monitor)

    // Virtual interface to access DUT signals
    virtual alu_if                   vif;
    // Analysis port to broadcast transactions
    uvm_analysis_port #(transaction) ap;

    // Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    // Build phase: Retrieve virtual interface
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual alu_if)::get(this, "", "alu_vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not found in config db")
        end
    endfunction

    // Run phase: Sample inputs and outputs, broadcast complete transactions
    task run_phase(uvm_phase phase);
        transaction tx;
        forever begin
            @(posedge vif.i_clk);
            tx                  = transaction::type_id::create("tx");
            // Sample inputs using cb_input
            tx.i_rst_n          = vif.cb_input.i_rst_n;
            tx.i_alu            = vif.cb_input.i_alu;
            tx.i_rs1_addr       = vif.cb_input.i_rs1_addr;
            tx.i_rs1            = vif.cb_input.i_rs1;
            tx.i_rs2            = vif.cb_input.i_rs2;
            tx.i_imm            = vif.cb_input.i_imm;
            tx.i_funct3         = vif.cb_input.i_funct3;
            tx.i_opcode         = vif.cb_input.i_opcode;
            tx.i_exception      = vif.cb_input.i_exception;
            tx.i_pc             = vif.cb_input.i_pc;
            tx.i_rd_addr        = vif.cb_input.i_rd_addr;
            tx.i_ce             = vif.cb_input.i_ce;
            tx.i_stall          = vif.cb_input.i_stall;
            tx.i_force_stall    = vif.cb_input.i_force_stall;
            tx.i_flush          = vif.cb_input.i_flush;
            // Sample outputs using cb_output
            tx.o_rs1_addr       = vif.cb_output.o_rs1_addr;
            tx.o_rs1            = vif.cb_output.o_rs1;
            tx.o_rs2            = vif.cb_output.o_rs2;
            tx.o_imm            = vif.cb_output.o_imm;
            tx.o_funct3         = vif.cb_output.o_funct3;
            tx.o_opcode         = vif.cb_output.o_opcode;
            tx.o_exception      = vif.cb_output.o_exception;
            tx.o_y              = vif.cb_output.o_y;
            tx.o_pc             = vif.cb_output.o_pc;
            tx.o_next_pc        = vif.cb_output.o_next_pc;
            tx.o_change_pc      = vif.cb_output.o_change_pc;
            tx.o_wr_rd          = vif.cb_output.o_wr_rd;
            tx.o_rd_addr        = vif.cb_output.o_rd_addr;
            tx.o_rd             = vif.cb_output.o_rd;
            tx.o_rd_valid       = vif.cb_output.o_rd_valid;
            tx.o_stall_from_alu = vif.cb_output.o_stall_from_alu;
            tx.o_ce             = vif.cb_output.o_ce;
            tx.o_stall          = vif.cb_output.o_stall;
            tx.o_flush          = vif.cb_output.o_flush;
            // Broadcast transaction
            ap.write(tx);
            `uvm_info("MONITOR", $sformatf("Captured transaction: %s", tx.convert2string()),
                      UVM_HIGH)
        end
    endtask
endclass
`endif
