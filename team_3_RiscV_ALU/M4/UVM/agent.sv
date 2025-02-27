`ifndef ALU_AGENT_SV
`define ALU_AGENT_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "transaction.sv"
`include "driver.sv"
`include "monitor.sv"

class alu_agent extends uvm_agent;
    `uvm_component_utils(alu_agent)

    // Components
    uvm_sequencer #(transaction) sequencer;
    alu_driver                   driver;
    alu_monitor                  monitor;

    // Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // Build phase: Instantiate components based on is_active
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = alu_monitor::type_id::create("monitor", this);
        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = uvm_sequencer#(transaction)::type_id::create("sequencer", this);
            driver    = alu_driver::type_id::create("driver", this);
        end
    endfunction

    // Connect phase: Link driver to sequencer if active
    function void connect_phase(uvm_phase phase);
        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction
endclass
`endif
