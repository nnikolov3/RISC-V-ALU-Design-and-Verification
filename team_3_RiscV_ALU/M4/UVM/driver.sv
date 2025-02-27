// ----------------------------------------------------------------------------
// ECE593 Milestone 4 - RV32I ALU Driver (Updated)
// ----------------------------------------------------------------------------
// Description:
//   This module implements a UVM driver for the RV32I ALU DUT.
//   It drives the DUT's input signals based on transactions received from the sequencer.
//
//   Note: The virtual interface (alu_if) must be set in the UVM configuration
//         database with the key "alu_vif" prior to simulation.
// ----------------------------------------------------------------------------
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "rv32i_alu_header.sv"
`include "transaction.sv"
`ifndef ALU_DRV_SV
`define ALU_DRV_SV
class alu_driver extends uvm_driver #(transaction);
    // Register with UVM factory
    `uvm_component_utils(alu_driver)
    // Virtual interface for DUT connection
    virtual alu_if drv_if;
	integer log_file;
    // UVM-compliant constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    // Build phase to retrieve the virtual interface
    function void build_phase(uvm_phase phase);
		log_file = $fopen("uvm_log.txt", "a");

        if (log_file) begin
            // Set the report server to write to the file
			set_report_severity_action_hier(UVM_INFO, UVM_DISPLAY | UVM_LOG);   // Ensure info messages are displayed and logged
			set_report_severity_action_hier(UVM_WARNING, UVM_LOG);               // Log warnings
			set_report_severity_action_hier(UVM_ERROR, UVM_LOG | UVM_DISPLAY);   // Log and display errors

			set_report_severity_file_hier(UVM_INFO, log_file);  // Ensure the info messages go to the log file
			set_report_severity_file_hier(UVM_WARNING, log_file);
			set_report_severity_file_hier(UVM_ERROR, log_file);
			//set_report_id_file("ENV", log_file);
			set_report_default_file_hier(log_file);
			`uvm_info("DRV", "Set report server severities and outputs", UVM_NONE);
        end else begin
            `uvm_error("DRV", "Failed to open log file")
        end
		`uvm_info("DRV", "DRIVER Building", UVM_NONE);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual alu_if)::get(this, "", "alu_vif", drv_if)) begin
            `uvm_fatal("DRV", "Virtual interface not found in config db with key 'alu_vif'")
        end
    endfunction
    // Run phase to process transactions from the sequencer
    task run_phase(uvm_phase phase);
        transaction tx;
        forever begin
            // Get the next transaction from the sequencer
            seq_item_port.get_next_item(tx);
            // Drive the transaction to the DUT
            drive_item(tx);
            // Signal transaction completion
            seq_item_port.item_done();
        end
    endtask
    // drive_item: Drives the DUT input signals based on the provided transaction
    // @param tx - The transaction object containing the data for all DUT signals
    virtual task drive_item(transaction tx);
        // Optional: Log transaction details for debugging
        `uvm_info("DRV", $sformatf("Driving transaction: %s", tx.convert2string()), UVM_HIGH)
        // Handle reset condition
        if (!drv_if.i_rst_n) begin
            // Drive default values during reset
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
            // Use clocking block if available (assumes cb_input is defined in alu_if)
            //            if (drv_if.cb_input) begin
            drv_if.cb_input.i_alu         <= tx.i_alu;
            drv_if.cb_input.i_rs1_addr    <= tx.i_rs1_addr;
            drv_if.cb_input.i_rs1         <= tx.i_rs1;
            drv_if.cb_input.i_rs2         <= tx.i_rs2;
            drv_if.cb_input.i_imm         <= tx.i_imm;
            drv_if.cb_input.i_funct3      <= tx.i_funct3;
            drv_if.cb_input.i_opcode      <= tx.i_opcode;
            drv_if.cb_input.i_pc          <= tx.i_pc;
            drv_if.cb_input.i_rd_addr     <= tx.i_rd_addr;
            drv_if.cb_input.i_ce          <= tx.i_ce;
            drv_if.cb_input.i_stall       <= tx.i_stall;
            drv_if.cb_input.i_force_stall <= tx.i_force_stall;
            drv_if.cb_input.i_flush       <= tx.i_flush;
            /*            end else begin
                // Fallback if no clocking block is defined
                drv_if.i_alu         <= tx.i_alu;
                drv_if.i_rs1_addr    <= tx.i_rs1_addr;
                drv_if.i_rs1         <= tx.i_rs1;
                drv_if.i_rs2         <= tx.i_rs2;
                drv_if.i_imm         <= tx.i_imm;
                drv_if.i_funct3      <= tx.i_funct3;
                drv_if.i_opcode      <= tx.i_opcode;
                drv_if.i_pc          <= tx.i_pc;
                drv_if.i_rd_addr     <= tx.i_rd_addr;
                drv_if.i_ce          <= tx.i_ce;
                drv_if.i_stall       <= tx.i_stall;
                drv_if.i_force_stall <= tx.i_force_stall;
                drv_if.i_flush       <= tx.i_flush;
            end */
        end
        // Synchronize with the positive clock edge
        @(posedge drv_if.i_clk);
    endtask
endclass
`endif
