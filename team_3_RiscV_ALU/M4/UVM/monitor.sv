
//-----------------------------------------------------------------------------
// File: monitor.sv
// Milestone 4
// Description:
//   This file contains the UVM-compatible input and output monitors for the ALU DUT.
//   The monitors sample signals via a virtual interface using clocking blocks and
//   broadcast transactions to subscribers (e.g., scoreboard, coverage collector)
//   using analysis ports. Logging is added for better traceability.
//-----------------------------------------------------------------------------
`ifndef MON_SV
`define MON_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "rv32i_alu_header.sv"
// Assuming transaction.sv defines transaction class
`include "transaction.sv"
//-----------------------------------------------------------------------------
// Class: alu_input_monitor
// Description:
//   This UVM monitor samples input signals from the DUT via the virtual
//   interface using the cb_input clocking block and broadcasts them as transactions
//   to subscribers.
//-----------------------------------------------------------------------------
class alu_input_monitor extends uvm_monitor;
    `uvm_component_utils(alu_input_monitor)
    // Virtual interface to access DUT signals
    virtual alu_if                   vif;
    // Analysis port to broadcast input transactions
    uvm_analysis_port #(transaction) ap;
    // Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction
    // Build phase: Retrieve virtual interface from config db
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not found in config db")
        end
    endfunction
    // Run phase: Sample inputs using cb_input and broadcast transactions
    task run_phase(uvm_phase phase);
        transaction tx;
        forever begin
            tx = transaction::type_id::create("tx");
            @(vif.cb_input);
            if (vif.cb_input.i_ce) begin
                tx.i_rst_n       = vif.cb_input.i_rst_n;
                tx.i_alu         = vif.cb_input.i_alu;
                tx.i_rs1_addr    = vif.cb_input.i_rs1_addr;
                tx.i_rs1         = vif.cb_input.i_rs1;
                tx.i_rs2         = vif.cb_input.i_rs2;
                tx.i_imm         = vif.cb_input.i_imm;
                tx.i_funct3      = vif.cb_input.i_funct3;
                tx.i_opcode      = vif.cb_input.i_opcode;
                tx.i_exception   = vif.cb_input.i_exception;
                tx.i_pc          = vif.cb_input.i_pc;
                tx.i_rd_addr     = vif.cb_input.i_rd_addr;
                tx.i_ce          = vif.cb_input.i_ce;
                tx.i_stall       = vif.cb_input.i_stall;
                tx.i_force_stall = vif.cb_input.i_force_stall;
                tx.i_flush       = vif.cb_input.i_flush;
                ap.write(tx);  // Broadcast to subscribers
                `uvm_info("INPUT_MON", $sformatf("Captured input transaction: %s",
                                                 tx.convert2string()), UVM_HIGH)
            end
        end
    endtask
endclass
//-----------------------------------------------------------------------------
// Class: alu_output_monitor
// Description:
//   This UVM monitor samples output signals from the DUT via the virtual
//   interface using the cb_output clocking block and broadcasts them as transactions
//   to subscribers. It also tracks the number of output transactions processed.
//-----------------------------------------------------------------------------
class alu_output_monitor extends uvm_monitor;
    `uvm_component_utils(alu_output_monitor)
    // Virtual interface to access DUT signals
    virtual alu_if                   vif;
    // Analysis port to broadcast output transactions
    uvm_analysis_port #(transaction) ap;
    // Transaction count
    int                              tx_count = 0;
    // Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction
    // Build phase: Retrieve virtual interface from config db
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not found in config db")
        end
    endfunction
    // Run phase: Sample outputs using cb_output and broadcast transactions
    task run_phase(uvm_phase phase);
        transaction tx;
        forever begin
            tx = transaction::type_id::create("tx");
            @(vif.cb_output);
            if (vif.cb_output.o_ce) begin
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
                ap.write(tx);  // Broadcast to subscribers
                `uvm_info("OUTPUT_MON", $sformatf("Captured output transaction: %s",
                                                  tx.convert2string()), UVM_HIGH)
                tx_count++;  // Increment transaction count
            end
        end
    endtask
endclass
`endif
