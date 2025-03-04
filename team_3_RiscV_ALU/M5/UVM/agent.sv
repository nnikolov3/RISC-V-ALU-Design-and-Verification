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
    integer                      log_file;
    // Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // Build phase: Instantiate components based on is_active
    function void build_phase(uvm_phase phase);
        `uvm_info("AGENT", "Agent Building", UVM_NONE);
        super.build_phase(phase);
        monitor  = alu_monitor::type_id::create("monitor", this);

        log_file = $fopen("uvm_log.txt", "a");

        if (log_file) begin
            // Set the report server to write to the file
            set_report_severity_action_hier(
                UVM_INFO, UVM_DISPLAY | UVM_LOG);  // Ensure info messages are displayed and logged
            set_report_severity_action_hier(UVM_WARNING, UVM_LOG);  // Log warnings
            set_report_severity_action_hier(UVM_ERROR,
                                            UVM_LOG | UVM_DISPLAY);  // Log and display errors

            set_report_severity_file_hier(
                UVM_INFO, log_file);  // Ensure the info messages go to the log file
            set_report_severity_file_hier(UVM_WARNING, log_file);
            set_report_severity_file_hier(UVM_ERROR, log_file);
            //set_report_id_file("ENV", log_file);
            set_report_default_file_hier(log_file);
            `uvm_info("AGENT", "Set report server severities and outputs", UVM_NONE);
        end else begin
            `uvm_error("AGENT", "Failed to open log file")
        end
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
