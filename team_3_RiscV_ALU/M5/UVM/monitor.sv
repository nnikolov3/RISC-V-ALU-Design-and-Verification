`ifndef UVM_MONITOR_SV
`define UVM_MONITOR_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "rv32i_alu_header.sv"
`include "transaction.sv"

//-----------------------------------------------------------------------------
// Class: monitor
//
// Description:
//   This monitor samples both input and output signals from the DUT through
//   the virtual interface (vif) and packages them into a single transaction
//   object. The transaction is then sent to the scoreboard via an analysis port.
//-----------------------------------------------------------------------------
class alu_monitor extends uvm_monitor;
    `uvm_component_utils(alu_monitor)

    // Virtual interface to access DUT signals
    virtual alu_if                   vif;
	integer log_file;
    // Single analysis port to send transactions to the scoreboard
    uvm_analysis_port #(transaction) mon2scb;

    //-------------------------------------------------------------------------
    // Constructor: new
    //
    // Description:
    //   Initializes the monitor component with a virtual interface and
    //   analysis port for communication with the scoreboard.
    //-------------------------------------------------------------------------
    function new(string name = "alu_monitor", uvm_component parent);
        super.new(name, parent);
        `uvm_info("MONITOR", "Inside constructor", UVM_HIGH)
        mon2scb = new("mon2scb", this);
    endfunction

    //-------------------------------------------------------------------------
    // Phase: build_phase
    //
    // Description:
    //   Sets up the virtual interface by getting it from the UVM configuration
    //   database. If the interface is not set, an error is raised.
    //-------------------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

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
			`uvm_info("MONITOR", "Set report server severities and outputs", UVM_NONE);
        end else begin
            `uvm_error("MONITOR", "Failed to open log file")
        end

        `uvm_info("MONITOR", "Build phase", UVM_HIGH)

        if (!uvm_config_db#(virtual alu_if)::get(this, "", "alu_vif", vif)) begin
            `uvm_fatal("MONITOR", "Virtual interface not set")
        end
    endfunction

    //-------------------------------------------------------------------------
    // Task: run_phase
    //
    // Description:
    //   Continuously samples input and output signals from the DUT on each
    //   positive clock edge. If either input or output clock enable is
    //   asserted, the signals are captured and packaged into a transaction
    //   object, which is sent to the scoreboard.
    //-------------------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        transaction tx;
        `uvm_info("MONITOR", "Monitor started", UVM_MEDIUM)

        forever begin
            //@(posedge vif.i_clk);  // Wait for the next clock edge
            tx = transaction::type_id::create("tx", this);
            //wait (vif.i_ce && vif.o_ce) begin
			wait (vif.i_ce) begin
                // Capture input signals
                //tx.i_clk         = vif.i_clk;
                tx.rst_n         = vif.rst_n;
                tx.i_alu         = vif.i_alu;
                tx.i_rs1_addr    = vif.i_rs1_addr;
                tx.i_rs1         = vif.i_rs1;
                tx.i_rs2         = vif.i_rs2;
                tx.i_imm         = vif.i_imm;
                tx.i_funct3      = vif.i_funct3;
                tx.i_opcode      = vif.i_opcode;
                tx.i_exception   = vif.i_exception;
                tx.i_pc          = vif.i_pc;
                tx.i_rd_addr     = vif.i_rd_addr;
                tx.i_ce          = vif.i_ce;
                tx.i_stall       = vif.i_stall;
                tx.i_force_stall = vif.i_force_stall;
                tx.i_flush       = vif.i_flush;
            end
			
			@(posedge vif.i_clk);
            //wait (vif.o_ce) begin
                // Capture output signals
                tx.o_rs1_addr       = vif.o_rs1_addr;
                tx.o_rs1            = vif.o_rs1;
                tx.o_rs2            = vif.o_rs2;
                tx.o_imm            = vif.o_imm;
                tx.o_funct3         = vif.o_funct3;
                tx.o_opcode         = vif.o_opcode;
                tx.o_exception      = vif.o_exception;
                tx.o_y              = vif.o_y;
                tx.o_pc             = vif.o_pc;
                tx.o_next_pc        = vif.o_next_pc;
                tx.o_change_pc      = vif.o_change_pc;
                tx.o_wr_rd          = vif.o_wr_rd;
                tx.o_rd_addr        = vif.o_rd_addr;
                tx.o_rd             = vif.o_rd;
                tx.o_rd_valid       = vif.o_rd_valid;
                tx.o_stall_from_alu = vif.o_stall_from_alu;
                tx.o_ce             = vif.o_ce;
                tx.o_stall          = vif.o_stall;
                tx.o_flush          = vif.o_flush;
            //end
			
/*			`uvm_info("SCB", $sformatf(
                  "\n***** Transaction Inputs *****\nOperation Type: %h\nRS1_ADDR: %h\nRS1: %h\nRS2: %h\nIMM: %h\nFUNCT3: %h\nInstruction Type: %h\nException: %b\nPC: %h\nRD_ADDR: %h\nCE: %b\nSTALL: %h\nFORCE_STALL: %h\nFLUSH: %h\nRST_N: %h"
                      ,
                  tx.i_alu,
                  tx.i_rs1_addr,
                  tx.i_rs1,
                  tx.i_rs2,
                  tx.i_imm,
                  tx.i_funct3,
                  tx.i_opcode,
                  tx.i_exception,
                  tx.i_pc,
                  tx.i_rd_addr,
				  tx.i_ce,
                  tx.i_stall,
                  tx.i_force_stall,
                  tx.i_flush,
                  tx.rst_n
                  ), UVM_MEDIUM);
			`uvm_info("SCB", $sformatf(
                  "\n***** Transaction Outputs *****\nRS1_ADDR: %h\nRS1: %h\nRS2: %h\nIMM: %h\nFUNCT3: %h\nInstruction Type: %h\nException: %b\nY: %h\nPC: %h\nNEXT_PC: %h\nCHANGE_PC: %h\nWR_RD: %h\nRD_ADDR: %h\nRD: %h\nRD_VALID: %h\nSTALL_FROM_ALU: %h\nCE: %b\nSTALL: %h\nFLUSH: %h"
                      ,
                  tx.o_rs1_addr,
                  tx.o_rs1,
                  tx.o_rs2,
                  tx.o_imm,
                  tx.o_funct3,
                  tx.o_opcode,
                  tx.o_exception,
				  tx.o_y,
                  tx.o_pc,
				  tx.o_next_pc,
				  tx.o_change_pc,
				  tx.o_wr_rd,
                  tx.o_rd_addr,
				  tx.o_rd,
				  tx.o_rd_valid,
				  tx.o_stall_from_alu,
				  tx.o_ce,
                  tx.o_stall,
                  tx.o_flush
                  ), UVM_MEDIUM);
*/				  
			mon2scb.write(tx);
			//@(negedge vif.i_clk);
        end
    endtask
endclass

`endif
