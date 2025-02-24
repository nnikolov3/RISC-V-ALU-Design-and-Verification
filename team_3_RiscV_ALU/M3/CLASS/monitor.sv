`ifndef UVM_MONITOR_SV
`define UVM_MONITOR_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "rv32i_alu_header.sv"
`include "transaction.sv"

//-----------------------------------------------------------------------------
// Class: monitor_in
//
// Description:
//   This monitor samples input signals from the DUT through the virtual
//   interface (vif) and packages them into a transaction object. The
//   transaction is then sent to the scoreboard via the mon_in2scb mailbox.
//-----------------------------------------------------------------------------
class monitor_in extends uvm_monitor;
    `uvm_component_utils(monitor_in)
    
    // Virtual interface to access input signals of the DUT.
    virtual alu_if vif;
    
    // Analysis port to send input transactions to the scoreboard.
    uvm_analysis_port#(transaction) mon_in2scb;

    //-------------------------------------------------------------------------
    // Constructor: new
    //
    // Description:
    //   Initializes the monitor_in component with a virtual interface and 
    //   analysis port for communication with the scoreboard.
    //
    // Parameters:
    //   name   - Name of the monitor (optional, default "monitor_in").
    //   parent - Parent UVM component (passed to super class).
    //-------------------------------------------------------------------------
    function new(string name = "monitor_in", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    //-------------------------------------------------------------------------
    // Phase: build_phase
    //
    // Description:
    //   Sets up the virtual interface by getting it from the UVM configuration 
    //   database. If the interface is not set, an error is raised.
    //
    // Parameters:
    //   phase - The UVM phase object (used for UVM lifecycle).
    //-------------------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("MONITOR_IN", "Virtual interface not set")
        end
    endfunction

    //-------------------------------------------------------------------------
    // Phase: connect_phase
    //
    // Description:
    //   Initializes the analysis port for communication with the scoreboard.
    //
    // Parameters:
    //   phase - The UVM phase object (used for UVM lifecycle).
    //-------------------------------------------------------------------------
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        mon_in2scb = new("mon_in2scb", this);
    endfunction
    
    //-------------------------------------------------------------------------
    // Task: run_phase
    //
    // Description:
    //   Continuously samples input signals from the DUT on each positive clock 
    //   edge. If clock enable (i_ce) is asserted, the signals are captured and 
    //   packaged into a transaction object, which is sent to the scoreboard.
    //
    // Parameters:
    //   phase - The UVM phase object (used for UVM lifecycle).
    //-------------------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        transaction tx;
        `uvm_info("MONITOR_IN", "Monitor started", UVM_MEDIUM)
        
        forever begin
            @(posedge vif.i_clk);  // Wait for the next clock edge
            if (vif.i_ce) begin  // Capture signals if clock enable is high
                tx = transaction::type_id::create("tx", this);
                
                // Capture DUT input signals into the transaction object
                tx.i_clk         = vif.i_clk;
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

                // Send the captured transaction to the scoreboard
                mon_in2scb.write(tx);
            end
        end
    endtask
endclass

//-----------------------------------------------------------------------------
// Class: monitor_out
//
// Description:
//   This monitor samples output signals from the DUT via the virtual
//   interface (vif), packages them into a transaction object, and sends the
//   transaction to the scoreboard through the mon_out2scb mailbox. It also
//   keeps a count of the output transactions processed.
//-----------------------------------------------------------------------------
class monitor_out extends uvm_monitor;
    `uvm_component_utils(monitor_out)
    
    // Virtual interface to access output signals of the DUT.
    virtual alu_if vif;
    
    // Analysis port to send output transactions to the scoreboard.
    uvm_analysis_port#(transaction) mon_out2scb;

    //-------------------------------------------------------------------------
    // Constructor: new
    //
    // Description:
    //   Initializes the monitor_out component with a virtual interface and 
    //   analysis port for communication with the scoreboard.
    //
    // Parameters:
    //   name   - Name of the monitor (optional, default "monitor_out").
    //   parent - Parent UVM component (passed to super class).
    //-------------------------------------------------------------------------
    function new(string name = "monitor_out", uvm_component parent);
        super.new(name, parent);
    endfunction
    
    //-------------------------------------------------------------------------
    // Phase: build_phase
    //
    // Description:
    //   Sets up the virtual interface by getting it from the UVM configuration 
    //   database. If the interface is not set, an error is raised.
    //
    // Parameters:
    //   phase - The UVM phase object (used for UVM lifecycle).
    //-------------------------------------------------------------------------
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("MONITOR_OUT", "Virtual interface not set")
        end
    endfunction

    //-------------------------------------------------------------------------
    // Phase: connect_phase
    //
    // Description:
    //   Initializes the analysis port for communication with the scoreboard.
    //
    // Parameters:
    //   phase - The UVM phase object (used for UVM lifecycle).
    //-------------------------------------------------------------------------
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        mon_out2scb = new("mon_out2scb", this);
    endfunction
    
    //-------------------------------------------------------------------------
    // Task: run_phase
    //
    // Description:
    //   Continuously samples the DUT output signals on each positive clock 
    //   edge. If output clock enable (o_ce) is asserted, the signals are 
    //   captured and packaged into a transaction object, which is sent to the 
    //   scoreboard. The task also increments a counter for the output transactions.
    //
    // Parameters:
    //   phase - The UVM phase object (used for UVM lifecycle).
    //-------------------------------------------------------------------------
    virtual task run_phase(uvm_phase phase);
        transaction tx;
        `uvm_info("MONITOR_OUT", "Monitor started", UVM_MEDIUM)
        
        forever begin
            @(posedge vif.i_clk);  // Wait for the next clock edge
            if (vif.o_ce) begin  // Capture signals if output clock enable is high
                tx = transaction::type_id::create("tx", this);
                
                // Capture DUT output signals into the transaction object
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

                // Send the captured transaction to the scoreboard
                mon_out2scb.write(tx);
            end
        end
    endtask
endclass

`endif
