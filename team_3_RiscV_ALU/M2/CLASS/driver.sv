// ----------------------------------------------------------------------------
// ECE593 M2 - RV32I ALU Driver
// ----------------------------------------------------------------------------
// Description:
//   This module implements a UVM driver for the RV32I ALU DUT (Design Under Test).
//   It converts high-level transaction objects into corresponding low-level signal
//   manipulations on the DUT's interface. In essence, it "drives" the ALU inputs
//   based on the sequencer's transactions.
//
//   Note: A virtual interface (alu_if) must be set in the UVM configuration database
//         with the key "drv_if" prior to simulation.
// ----------------------------------------------------------------------------


`include "rv32i_alu_header.sv"
`include "transaction.sv"

class driver;

    mailbox #(transaction) driver_mb;

    // Virtual interface for DUT connection.
    virtual alu_if drv_if;

    function new(virtual alu_if drv_vif, mailbox#(transaction) mb);
        this.drv_if    = drv_if;
        this.driver_mb = mb;
    endfunction

    task run();
        transaction tx;
        // Example: retrieve an expected transaction from the mailbox for comparison
        forever begin
            driver_mb.get(tx);
            $display("Tx %d \n", tx);
            drive_item(tx);
            //driver_mb.put(tx);
        end
    endtask

    // drive_item: Drives the DUT input signals based on the provided transaction.
    // @param tx - The transaction object containing the data for all DUT signals.
    virtual task drive_item(transaction tx);
        // Map each field from the transaction to its corresponding DUT signal.
        drv_if.i_opcode      = tx.i_opcode;
        drv_if.i_alu         = tx.i_alu;
        drv_if.i_rs1         = tx.i_rs1;
        drv_if.i_rs2         = tx.i_rs2;
        drv_if.i_imm         = tx.i_imm;
        drv_if.i_funct3      = tx.i_funct3;
        drv_if.i_pc          = tx.i_pc;
        drv_if.i_rs1_addr    = tx.i_rs1_addr;
        drv_if.i_rd_addr     = tx.i_rd_addr;
        drv_if.i_ce          = tx.i_ce;
        drv_if.i_stall       = tx.i_stall;
        drv_if.i_force_stall = tx.i_force_stall;
        drv_if.i_flush       = tx.i_flush;

        // Wait for the next positive clock edge to synchronize signal updates.
        @(posedge drv_if.i_clk);
        driver_mb.put(tx);
        $display("Tx %d \n", tx);
        #20;
    endtask

endclass
