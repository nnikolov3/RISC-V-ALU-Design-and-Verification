// ----------------------------------------------------------------------------
// Class: alu_monitor
// ECE 593
// Milestone 4 - RV32I ALU Monitor
// Team 3
// Description:
//   This UVM monitor observes the RV32I Arithmetic Logic Unit (ALU) Device
//   Under Test (DUT) by sampling input and output signals through a virtual
//   interface. It captures these signals into transactions and broadcasts
//   them via an analysis port to components like scoreboards and coverage
//   collectors. The monitor operates synchronously with the DUT clock and
//   relies on a virtual interface (alu_if) configured in the UVM database
//   under the key "alu_vif".
// Updated: Feb 26, 2025
// ----------------------------------------------------------------------------

`ifndef ALU_MONITOR_SV
`define ALU_MONITOR_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "rv32i_alu_header.sv"
`include "transaction.sv"

class alu_monitor extends uvm_monitor;
    // ------------------------------------------------------------------------
    // Registration: Factory Registration
    // Description:
    //   Registers the monitor with the UVM factory for dynamic instantiation.
    // ------------------------------------------------------------------------
    `uvm_component_utils(alu_monitor)

    // ------------------------------------------------------------------------
    // Members: Interface and Analysis Port
    // Description:
    //   - vif: Virtual interface to access DUT signals.
    //   - ap: Analysis port to broadcast captured transactions to subscribers.
    // ------------------------------------------------------------------------
    virtual alu_if                   vif;  // Virtual interface for DUT signal access
    uvm_analysis_port #(transaction) ap;  // Port to send transactions to other components

    // ------------------------------------------------------------------------
    // Constructor: new
    // Description:
    //   Initializes the monitor with a name and parent, and creates the analysis port.
    // Arguments:
    //   - name: String identifier for the monitor instance
    //   - parent: Parent UVM component in the hierarchy
    // ------------------------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);  // Instantiate the analysis port
    endfunction

    // ------------------------------------------------------------------------
    // Function: build_phase
    // Description:
    //   Retrieves the virtual interface from the UVM configuration database
    //   during the build phase. Fails simulation if the interface is not found.
    // Arguments:
    //   - phase: UVM phase object for synchronization
    // ------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual alu_if)::get(this, "", "alu_vif", vif)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not found in config db")
        end
    endfunction

    // ------------------------------------------------------------------------
    // Task: run_phase
    // Description:
    //   Main execution loop of the monitor. Continuously samples ALU input and
    //   output signals on each clock cycle, constructs transactions, and
    //   broadcasts them via the analysis port. Logs captured transactions for
    //   debugging at high verbosity.
    // Arguments:
    //   - phase: UVM phase object for synchronization
    // ------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        transaction tx;
        forever begin
            // Synchronize sampling with the positive clock edge
            @(posedge vif.i_clk);
            // Create a new transaction instance
            tx                  = transaction::type_id::create("tx");

            // ------------------------------------------------------------------------
            // Input Sampling
            // Description:
            //   Samples input signals from the DUT using the cb_input clocking block.
            // ------------------------------------------------------------------------
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

            // ------------------------------------------------------------------------
            // Output Sampling
            // Description:
            //   Samples output signals from the DUT using the cb_output clocking block.
            // ------------------------------------------------------------------------
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

            // ------------------------------------------------------------------------
            // Transaction Broadcast
            // Description:
            //   Sends the completed transaction to subscribers via the analysis port
            //   and logs it for debugging at high verbosity.
            // ------------------------------------------------------------------------
            ap.write(tx);
            `uvm_info("MONITOR", $sformatf("Captured transaction: %s", tx.convert2string()),
                      UVM_HIGH)
        end
    endtask
endclass
`endif
