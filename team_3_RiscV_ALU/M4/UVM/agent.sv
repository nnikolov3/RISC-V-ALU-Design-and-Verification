// ----------------------------------------------------------------------------
// Class: alu_agent
// ECE 593
// Milestone 4
// Team 3
// Description:
//   This UVM agent encapsulates components for driving and monitoring an
//   Arithmetic Logic Unit (ALU) in a RISC-V 32I processor verification
//   environment. It includes a sequencer and driver for stimulus generation
//   (when active) and a monitor for observing DUT behavior. The agent's
//   configuration supports both active and passive modes.
// Updated: Feb 26, 2025
// ----------------------------------------------------------------------------

`ifndef ALU_AGENT_SV
`define ALU_AGENT_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "transaction.sv"
`include "driver.sv"
`include "monitor.sv"

class alu_agent extends uvm_agent;
    `uvm_component_utils(alu_agent)

    // ------------------------------------------------------------------------
    // Members: Components
    // Description:
    //   The agent contains a sequencer, driver, and monitor:
    //   - sequencer: Generates and sequences transactions (active mode only).
    //   - driver: Drives transactions to the DUT via the interface (active mode only).
    //   - monitor: Observes DUT signals and sends transactions to analysis ports.
    // ------------------------------------------------------------------------
    uvm_sequencer #(transaction) sequencer;
    alu_driver                   driver;
    alu_monitor                  monitor;

    // ------------------------------------------------------------------------
    // Constructor: new
    // Description:
    //   Initializes the agent instance with a name and parent in the UVM hierarchy.
    // Arguments:
    //   - name: String identifier for the agent instance
    //   - parent: Parent UVM component in the hierarchy
    // ------------------------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // ------------------------------------------------------------------------
    // Function: build_phase
    // Description:
    //   Constructs the agent's components during the build phase. The monitor is
    //   always created, while the sequencer and driver are instantiated only if
    //   the agent is configured as active (UVM_ACTIVE).
    // Arguments:
    //   - phase: UVM phase object for synchronization
    // ------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Create the monitor regardless of agent mode
        monitor = alu_monitor::type_id::create("monitor", this);
        // Create sequencer and driver only if the agent is active
        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = uvm_sequencer#(transaction)::type_id::create("sequencer", this);
            driver    = alu_driver::type_id::create("driver", this);
        end

    endfunction

    // ------------------------------------------------------------------------
    // Function: connect_phase
    // Description:
    //   Establishes connections between components during the connect phase.
    //   If the agent is active, links the driver's sequence item port to the
    //   sequencer's export, enabling transaction flow from sequencer to driver.
    // Arguments:
    //   - phase: UVM phase object for synchronization
    // ------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end

    endfunction

endclass

`endif
