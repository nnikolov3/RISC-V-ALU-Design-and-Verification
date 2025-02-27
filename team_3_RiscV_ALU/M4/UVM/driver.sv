// ----------------------------------------------------------------------------
// Class: alu_driver
// ECE 593
// Milestone 4 - RV32I ALU Driver
// Team 3
// Description:
//   This UVM driver stimulates the RV32I Arithmetic Logic Unit (ALU) Device
//   Under Test (DUT) by driving its input signals based on transactions
//   received from a sequencer. It supports reset conditions and normal
//   operation, synchronizing with the DUT clock. The driver relies on a
//   virtual interface (alu_if) configured in the UVM database under the key
//   "alu_vif".
// Updated: Feb 26, 2025
// ----------------------------------------------------------------------------

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "rv32i_alu_header.sv"
`include "transaction.sv"
`ifndef ALU_DRV_SV
`define ALU_DRV_SV

class alu_driver extends uvm_driver #(transaction);
    // ------------------------------------------------------------------------
    // Registration: Factory Registration
    // Description:
    //   Registers the driver with the UVM factory for component creation.
    // ------------------------------------------------------------------------
    `uvm_component_utils(alu_driver)

    // ------------------------------------------------------------------------
    // Member: drv_if
    // Description:
    //   Virtual interface to connect the driver to the DUT's signals. Must be
    //   set in the UVM configuration database with the key "alu_vif".
    // ------------------------------------------------------------------------
    virtual alu_if drv_if;

    // ------------------------------------------------------------------------
    // Constructor: new
    // Description:
    //   Initializes the driver with a name and parent in the UVM hierarchy.
    // Arguments:
    //   - name: String identifier for the driver instance
    //   - parent: Parent UVM component in the hierarchy
    // ------------------------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);
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
        if (!uvm_config_db#(virtual alu_if)::get(this, "", "alu_vif", drv_if)) begin
            `uvm_fatal("NO_VIF", "Virtual interface not found in config db with key 'alu_vif'")
        end

    endfunction

    // ------------------------------------------------------------------------
    // Task: run_phase
    // Description:
    //   Main execution loop of the driver. Continuously retrieves transactions
    //   from the sequencer, drives them to the DUT, and signals completion.
    // Arguments:
    //   - phase: UVM phase object for synchronization
    // ------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        transaction tx;
        forever begin
            // Retrieve the next transaction from the sequencer
            seq_item_port.get_next_item(tx);
            // Drive the transaction to the DUT
            drive_item(tx);
            // Notify the sequencer that the transaction is complete
            seq_item_port.item_done();
        end

    endtask

    // ------------------------------------------------------------------------
    // Task: drive_item
    // Description:
    //   Drives the DUT's input signals based on the transaction data. Handles
    //   reset conditions and normal operation, optionally using a clocking
    //   block for synchronization. Waits for a positive clock edge to ensure
    //   timing alignment.
    // Arguments:
    //   - tx: Transaction object containing input signal values for the DUT
    // ------------------------------------------------------------------------
    virtual task drive_item(transaction tx);
        // Log transaction details for debugging (optional, high verbosity)
        `uvm_info("DRV", $sformatf("Driving transaction: %s", tx.convert2string()), UVM_HIGH)

        // ------------------------------------------------------------------------
        // Reset Handling
        // Description:
        //   If reset (i_rst_n) is low, drive all inputs to zero to simulate a
        //   reset state.
        // ------------------------------------------------------------------------
        if (!drv_if.i_rst_n) begin
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

        // ------------------------------------------------------------------------
        // Clock Synchronization
        // Description:
        //   Wait for the positive edge of the clock to ensure signals are driven
        //   at the appropriate time.
        // ------------------------------------------------------------------------
        @(posedge drv_if.i_clk);
    endtask

endclass

`endif
