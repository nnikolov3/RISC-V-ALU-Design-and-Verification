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
    virtual alu_if vif;
    
    // Single analysis port to send transactions to the scoreboard
    uvm_analysis_port#(transaction) mon2scb;
    
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
            @(posedge vif.i_clk); // Wait for the next clock edge
            tx = transaction::type_id::create("tx", this);
            wait (vif.i_ce) begin
                
                
                // Capture input signals
                //tx.i_clk         = vif.i_clk;
                tx.i_rst_n       = vif.i_rst_n;
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
            
			wait (vif.o_ce) begin
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
			end
                
                // Send the transaction to the scoreboard
            mon2scb.write(tx);

        end
    endtask
endclass

`endif
