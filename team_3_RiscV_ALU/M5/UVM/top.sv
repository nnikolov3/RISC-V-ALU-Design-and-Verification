// ----------------------------------------------------------------------------
// Module: top
// Description:
//   This top-level module integrates the RV32I ALU DUT with its interface and
//   UVM testbench infrastructure. It generates clock and reset signals, connects
//   the DUT to the interface, sets up the UVM configuration database, and initiates
//   a UVM test to verify the ALU’s functionality.
// Updated: Mar 08, 2025
// ----------------------------------------------------------------------------
// Include UVM macro definitions for utility functions and reporting mechanisms.
`include "uvm_macros.svh"

// Import the UVM package to access its classes, methods, and infrastructure.
import uvm_pkg::*;

// Set simulation timescale to 1ns time unit and 1ps precision for timing accuracy.
`timescale 1ns / 1ps

// Prevent implicit wire declarations to enforce explicit signal definitions.
`default_nettype none

// Define the top module, serving as the entry point for simulation.
module top;
  // Clock and reset signals driving the DUT and testbench.
  logic i_clk;  // Clock signal with a 10ns period.
  logic i_rst_n;  // Active-low reset signal.

  // Instantiate the ALU interface, connecting clock and reset inputs.
  alu_if dut_if (
      .i_clk  (i_clk),   // Connects the clock signal to the interface.
      .i_rst_n(i_rst_n)  // Connects the reset signal to the interface.
  );

  // Instantiate the RV32I ALU DUT, mapping all interface signals to DUT ports.
  rv32i_alu DUT (
      .i_clk           (dut_if.i_clk),             // Clock input from interface.
      .i_rst_n         (dut_if.rst_n),             // Reset input from interface.
      .i_alu           (dut_if.i_alu),             // ALU operation selection bits.
      .i_rs1_addr      (dut_if.i_rs1_addr),        // Source register 1 address.
      .i_rs1           (dut_if.i_rs1),             // Source register 1 value.
      .i_rs2           (dut_if.i_rs2),             // Source register 2 value.
      .i_imm           (dut_if.i_imm),             // Immediate value from instruction.
      .i_funct3        (dut_if.i_funct3),          // 3-bit function code from instruction.
      .i_opcode        (dut_if.i_opcode),          // Instruction opcode.
      .i_exception     (dut_if.i_exception),       // Exception status input.
      .i_pc            (dut_if.i_pc),              // Program counter value.
      .i_rd_addr       (dut_if.i_rd_addr),         // Destination register address.
      .i_ce            (dut_if.i_ce),              // Clock enable signal.
      .i_stall         (dut_if.i_stall),           // Pipeline stall signal.
      .i_force_stall   (dut_if.i_force_stall),     // Debug stall signal.
      .i_flush         (dut_if.i_flush),           // Pipeline flush signal.
      .o_rs1_addr      (dut_if.o_rs1_addr),        // Bypassed RS1 address output.
      .o_rs1           (dut_if.o_rs1),             // Bypassed RS1 value output.
      .o_rs2           (dut_if.o_rs2),             // Bypassed RS2 value output.
      .o_imm           (dut_if.o_imm),             // Bypassed immediate value output.
      .o_funct3        (dut_if.o_funct3),          // Bypassed function code output.
      .o_opcode        (dut_if.o_opcode),          // Bypassed opcode output.
      .o_exception     (dut_if.o_exception),       // Propagated exception status output.
      .o_y             (dut_if.o_y),               // ALU computation result output.
      .o_pc            (dut_if.o_pc),              // Current PC value output.
      .o_next_pc       (dut_if.o_next_pc),         // Calculated next PC output.
      .o_change_pc     (dut_if.o_change_pc),       // PC change request output.
      .o_wr_rd         (dut_if.o_wr_rd),           // Write enable for destination register.
      .o_rd_addr       (dut_if.o_rd_addr),         // Destination register address output.
      .o_rd            (dut_if.o_rd),              // Data to write to destination register.
      .o_rd_valid      (dut_if.o_rd_valid),        // Destination register write valid output.
      .o_stall_from_alu(dut_if.o_stall_from_alu),  // ALU-generated stall request output.
      .o_ce            (dut_if.o_ce),              // Propagated clock enable output.
      .o_stall         (dut_if.o_stall),           // Combined stall signal output.
      .o_flush         (dut_if.o_flush)            // Propagated flush signal output.
  );

  // Clock generation: Produces a continuous clock signal with a 10ns period.
  initial begin
    i_clk = 0;  // Initialize clock to 0.
    forever #5 i_clk = ~i_clk;  // Toggle clock every 5ns (10ns period, 100MHz frequency).
  end

  // Reset assertion: Applies an initial reset pulse to synchronize the DUT and testbench.
  initial begin
    i_rst_n = 0;  // Assert reset (active-low) at simulation start.
    #20;  // Hold reset for 20ns (two clock cycles).
    i_rst_n = 1;  // Deassert reset to allow normal operation.
    // The original reset block was commented out; this is now active for proper initialization.
  end

  // UVM configuration: Sets the virtual interface in the UVM configuration database.
  initial begin
    // Store the interface instance in the config DB with the key "alu_vif".
    // The null context and wildcard path "*" make it accessible to all UVM components.
    uvm_config_db#(virtual alu_if)::set(null, "*", "alu_vif", dut_if);
  end

  // UVM test execution: Initiates the UVM test and controls simulation termination.
  initial begin
    // Start the specified UVM test ("alu_base_test") to drive the DUT.
    run_test("alu_base_test");

    // Wait for 1000ns to allow the test to complete its sequence and collect results.
    #1000;

    // Explicitly terminate the simulation to ensure a clean exit after the test.
    $finish;
  end
endmodule
