// ----------------------------------------------------------------------------
// *********************************************
// UVM Testbench Top Module for ALU Verification
// ECE 593: Milestone 4, Group 3
// File: top.sv
// Description:
// This top-level SystemVerilog module acts as the integration point for the
// UVM-based verification of the RV32I Arithmetic Logic Unit (ALU) within a
// RISC-V 32I processor environment. It instantiates the ALU DUT and its
// interface, generates clock and reset signals, configures the UVM framework
// with the virtual interface, and launches the ALU base test to drive
// verification.
// Updated: Feb 26, 2025
// **********************************************
// ----------------------------------------------------------------------------

`include "uvm_macros.svh"
import uvm_pkg::*;
`timescale 1ns / 1ps  // Timescale set to 1ns unit, 1ps precision
`default_nettype none  // Prevents implicit net creation for safer design

module top;
    // ------------------------------------------------------------------------
    // Signals: Clock and Reset
    // Description:
    //   Declares clock and reset signals essential for DUT operation and
    //   testbench synchronization.
    // ------------------------------------------------------------------------
    logic i_clk;  // Clock signal driving the DUT
    logic i_rst_n;  // Active-low reset signal

    // ------------------------------------------------------------------------
    // Interface Instantiation: dut_if
    // Description:
    //   Creates an instance of the ALU interface, connecting clock and reset
    //   signals to facilitate DUT-testbench interaction.
    // ------------------------------------------------------------------------
    alu_if dut_if (
        .i_clk  (i_clk),
        .i_rst_n(i_rst_n)
    );

    // ------------------------------------------------------------------------
    // DUT Instantiation: rv32i_alu
    // Description:
    //   Instantiates the RV32I ALU DUT, wiring all input and output signals
    //   through the interface for verification.
    // ------------------------------------------------------------------------
    rv32i_alu DUT (
        .i_clk           (dut_if.i_clk),
        .i_rst_n         (dut_if.i_rst_n),
        .i_alu           (dut_if.i_alu),
        .i_rs1_addr      (dut_if.i_rs1_addr),
        .i_rs1           (dut_if.i_rs1),
        .i_rs2           (dut_if.i_rs2),
        .i_imm           (dut_if.i_imm),
        .i_funct3        (dut_if.i_funct3),
        .i_opcode        (dut_if.i_opcode),
        .i_exception     (dut_if.i_exception),
        .i_pc            (dut_if.i_pc),
        .i_rd_addr       (dut_if.i_rd_addr),
        .i_ce            (dut_if.i_ce),
        .i_stall         (dut_if.i_stall),
        .i_force_stall   (dut_if.i_force_stall),
        .i_flush         (dut_if.i_flush),
        .o_rs1_addr      (dut_if.o_rs1_addr),
        .o_rs1           (dut_if.o_rs1),
        .o_rs2           (dut_if.o_rs2),
        .o_imm           (dut_if.o_imm),
        .o_funct3        (dut_if.o_funct3),
        .o_opcode        (dut_if.o_opcode),
        .o_exception     (dut_if.o_exception),
        .o_y             (dut_if.o_y),
        .o_pc            (dut_if.o_pc),
        .o_next_pc       (dut_if.o_next_pc),
        .o_change_pc     (dut_if.o_change_pc),
        .o_wr_rd         (dut_if.o_wr_rd),
        .o_rd_addr       (dut_if.o_rd_addr),
        .o_rd            (dut_if.o_rd),
        .o_rd_valid      (dut_if.o_rd_valid),
        .o_stall_from_alu(dut_if.o_stall_from_alu),
        .o_ce            (dut_if.o_ce),
        .o_stall         (dut_if.o_stall),
        .o_flush         (dut_if.o_flush)
    );

    // ------------------------------------------------------------------------
    // Clock Generation
    // Description:
    //   Produces a continuous clock signal with a 10ns period (100MHz frequency)
    //   to synchronize the DUT and testbench operations.
    // ------------------------------------------------------------------------
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk;  // Toggle every 5ns for 10ns period
    end

    // ------------------------------------------------------------------------
    // Reset Assertion
    // Description:
    //   Initializes the DUT with a 20ns reset pulse, asserting reset low then
    //   releasing it to begin normal operation.
    // ------------------------------------------------------------------------
    initial begin
        i_rst_n = 0;  // Start with reset active
        #20;  // Hold for 20ns
        i_rst_n = 1;  // Release reset
    end

    // ------------------------------------------------------------------------
    // UVM Configuration: Virtual Interface Registration
    // Description:
    //   Registers the virtual interface in the UVM configuration database under
    //   the key "alu_vif", using a wildcard path for accessibility across the
    //   testbench hierarchy.
    // ------------------------------------------------------------------------
    initial begin
        uvm_config_db#(virtual alu_if)::set(null, "*", "alu_vif", dut_if);
    end

    // ------------------------------------------------------------------------
    // UVM Test Execution
    // Description:
    //   Launches the UVM verification process by running the "alu_base_test"
    //   class, which orchestrates stimulus generation and DUT verification.
    // ------------------------------------------------------------------------
    initial begin
        run_test("alu_base_test");  // Execute the ALU base test
    end

endmodule
