// ----------------------------------------------------------------------------
// ECE593 - RV32I ALU Interface
// Description:
//   This interface defines the signal connections between the RV32I ALU DUT and
//   the testbench or pipeline stages. It facilitates communication by specifying
//   input and output signals, clocking blocks for timing, modports for directional
//   control, and assertions for signal integrity. It is used by the UVM testbench
//   to drive and monitor the ALU.
// File: interface.sv
// Class: alu_if
// Updated: Mar 08, 2025
// ----------------------------------------------------------------------------
// Include ALU-specific constants and types defined in the header file.
`include "rv32i_alu_header.sv"

// Set simulation timescale to 1ns time unit and 1ps precision for timing accuracy.
`timescale 1ns / 1ps

// Prevent implicit wire declarations to enforce explicit signal definitions.
`default_nettype none

// Guard against multiple inclusions of this file in the compilation process.
// If ALU_IF_SV is already defined elsewhere, this file won’t be reprocessed.
`ifndef ALU_IF_SV
`define ALU_IF_SV

// Define the alu_if interface with clock and reset inputs provided externally.
interface alu_if (
    input wire i_clk,   // Main clock signal driving the ALU and testbench timing.
    input wire i_rst_n  // Active-low asynchronous reset signal for initializing the ALU.
);
    // Define parameter defaults for signal widths, configurable via the header file.
    // If not overridden in rv32i_alu_header.sv, these defaults apply.
    `ifdef ALU_WIDTH
        localparam ALU_WIDTH = `ALU_WIDTH;  // Width of ALU operation selection bits.
    `else
        localparam ALU_WIDTH = 4;           // Default to 4-bit ALU operation width.
    `endif

    `ifdef OPCODE_WIDTH
        localparam OPCODE_WIDTH = `OPCODE_WIDTH;  // Width of the instruction opcode.
    `else
        localparam OPCODE_WIDTH = 7;        // Default to 7-bit RISC-V opcode width.
    `endif

    `ifdef EXCEPTION_WIDTH
        localparam EXCEPTION_WIDTH = `EXCEPTION_WIDTH;  // Width of exception status bits.
    `else
        localparam EXCEPTION_WIDTH = 2;     // Default to 2-bit exception width.
    `endif

    //////////////////////////////////////////////////
    // Input signals to ALU (Driven by Controller or Testbench) //
    //////////////////////////////////////////////////
    logic [ALU_WIDTH-1:0]       i_alu;         // Selects the ALU operation (e.g., ADD, SUB).
    logic [4:0]                 i_rs1_addr;    // Address of source register 1 (5-bit, 32 registers).
    logic [31:0]                i_rs1;         // Value from source register 1 (32-bit).
    logic [31:0]                i_rs2;         // Value from source register 2 (32-bit).
    logic [31:0]                i_imm;         // Immediate value from the instruction (32-bit).
    logic [2:0]                 i_funct3;      // 3-bit function code from the instruction.
    logic [OPCODE_WIDTH-1:0]    i_opcode;      // Instruction opcode defining the operation type.
    logic [EXCEPTION_WIDTH-1:0] i_exception;   // Exception status propagated from prior stages.
    logic [31:0]                i_pc;          // Current program counter value (32-bit).
    logic [4:0]                 i_rd_addr;     // Address of the destination register (5-bit).
    logic                       i_ce;          // Clock enable signal to control ALU operation.
    logic                       i_stall;       // Pipeline stall signal from the controller.
    logic                       i_force_stall; // Debug-specific stall signal.
    logic                       i_flush;       // Pipeline flush signal to clear ALU state.
    logic                       rst_n;         // Local reset signal (driven by testbench).

    ////////////////////////////////////////////////////
    // Output signals from ALU (To Writeback Stage or Testbench) //
    ////////////////////////////////////////////////////
    logic [4:0]                 o_rs1_addr;        // Bypassed source register 1 address (5-bit).
    logic [31:0]                o_rs1;             // Bypassed source register 1 value (32-bit).
    logic [31:0]                o_rs2;             // Bypassed source register 2 value (32-bit).
    logic [11:0]                o_imm;             // Bypassed immediate value (12-bit subset).
    logic [2:0]                 o_funct3;          // Bypassed 3-bit function code.
    logic [OPCODE_WIDTH-1:0]    o_opcode;          // Bypassed instruction opcode.
    logic [EXCEPTION_WIDTH-1:0] o_exception;       // Propagated exception status from ALU.
    logic [31:0]                o_y;               // ALU computation result (32-bit).
    logic [31:0]                o_pc;              // Current program counter value (32-bit).
    logic [31:0]                o_next_pc;         // Next program counter value for jumps/branches.
    logic                       o_change_pc;       // Indicates a PC change request (1 = jump/branch taken).
    logic                       o_wr_rd;           // Write enable for the destination register.
    logic [4:0]                 o_rd_addr;         // Destination register address (5-bit).
    logic [31:0]                o_rd;              // Data to write to the destination register (32-bit).
    logic                       o_rd_valid;        // Indicates the destination register data is valid.
    logic                       o_stall_from_alu;  // Stall request generated by the ALU.
    logic                       o_ce;              // Propagated clock enable signal.
    logic                       o_stall;           // Combined stall signal output.
    logic                       o_flush;           // Propagated flush signal.

    // Clocking block for testbench driving inputs to the DUT.
    // Synchronizes input signal assignments with the positive clock edge.
    clocking cb_input @(posedge i_clk);
        default output #1ns;  // Applies a 1ns delay after the clock edge for output signals.
        output i_alu, i_rs1_addr, i_rs1, i_rs2, i_imm, i_funct3,
               i_opcode, i_exception, i_pc, i_rd_addr, i_ce,
               i_stall, i_force_stall, i_flush, rst_n;  // All inputs driven by the testbench.
    endclocking

    // Clocking block for testbench sampling outputs from the DUT.
    // Synchronizes output signal sampling with the positive clock edge.
    clocking cb_output @(posedge i_clk);
        default input #1ns;  // Samples inputs 1ns after the clock edge for timing alignment.
        input o_rs1_addr, o_rs1, o_rs2, o_imm, o_funct3,
              o_opcode, o_exception, o_y, o_pc, o_next_pc,
              o_change_pc, o_wr_rd, o_rd_addr, o_rd,
              o_rd_valid, o_stall_from_alu, o_ce, o_stall, o_flush;  // All outputs sampled.
    endclocking

    // Clocking block for DUT sampling inputs from the testbench or pipeline.
    // Synchronizes input signal sampling by the DUT with the positive clock edge.
    clocking cb_dut_input @(posedge i_clk);
        default input #1ns;  // Samples inputs 1ns after the clock edge for timing alignment.
        input i_alu, i_rs1_addr, i_rs1, i_rs2, i_imm, i_funct3,
              i_opcode, i_exception, i_pc, i_rd_addr, i_ce,
              i_stall, i_force_stall, i_flush, rst_n;  // All inputs sampled by the DUT.
    endclocking

    // Modport for DUT connection, defining the signal directions and clocking.
    // Specifies inputs received by the DUT and outputs driven by the DUT.
    modport DUT (
        input  i_alu, i_rs1_addr, i_rs1, i_rs2, i_imm, i_funct3,
               i_opcode, i_exception, i_pc, i_rd_addr, i_ce,
               i_stall, i_force_stall, i_flush, rst_n,         // DUT receives these signals.
        output o_rs1_addr, o_rs1, o_rs2, o_imm, o_funct3,
               o_opcode, o_exception, o_y, o_pc, o_next_pc,
               o_change_pc, o_wr_rd, o_rd_addr, o_rd, o_rd_valid,
               o_stall_from_alu, o_ce, o_stall, o_flush,       // DUT drives these signals.
        clocking cb_dut_input  // Associates the DUT with its input clocking block.
    );

    // Modport for testbench connection, defining the signal directions and clocking.
    // Specifies outputs driven by the testbench and inputs sampled from the DUT.
    modport TB (
        output i_alu, i_rs1_addr, i_rs1, i_rs2, i_imm, i_funct3,
               i_opcode, i_exception, i_pc, i_rd_addr, i_ce,
               i_stall, i_force_stall, i_flush, rst_n,         // Testbench drives these signals.
        input  o_rs1_addr, o_rs1, o_rs2, o_imm, o_funct3,
               o_opcode, o_exception, o_y, o_pc, o_next_pc,
               o_change_pc, o_wr_rd, o_rd_addr, o_rd, o_rd_valid,
               o_stall_from_alu, o_ce, o_stall, o_flush,       // Testbench samples these signals.
        clocking cb_input, cb_output  // Associates the testbench with input and output clocking.
    );

    // Assertions for signal integrity, enabled when UVM is defined.
    `ifdef UVM
        // Assertion 1: Ensures stall and flush signals are not asserted simultaneously.
        // Checked at each positive clock edge, disabled during reset.
        property stall_flush_conflict;
            @(posedge i_clk) disable iff (!i_rst_n)
            !(i_stall && i_flush);  // Verifies mutual exclusivity of stall and flush.
        endproperty
        assert property (stall_flush_conflict)
            else `uvm_error("IF", "Stall and flush asserted simultaneously");  // UVM error report.

        // Assertion 2: Ensures clock enable is not asserted during reset.
        // Checked at each positive clock edge.
        property ce_during_reset;
            @(posedge i_clk)
            !i_rst_n |-> !i_ce;  // Implies i_ce must be low when reset is active.
        endproperty
        assert property (ce_during_reset)
            else `uvm_error("IF", "Clock enable asserted during reset");  // UVM error report.
    `else
        // Fallback assertions without UVM, using standard SystemVerilog error reporting.
        property stall_flush_conflict;
            @(posedge i_clk) disable iff (!i_rst_n)
            !(i_stall && i_flush);  // Verifies mutual exclusivity of stall and flush.
        endproperty
        assert property (stall_flush_conflict)
            else $error("Stall and flush asserted simultaneously");  // Non-UVM error report.

        property ce_during_reset;
            @(posedge i_clk)
            !i_rst_n |-> !i_ce;  // Implies i_ce must be low when reset is active.
        endproperty
        assert property (ce_during_reset)
            else $error("Clock enable asserted during reset");  // Non-UVM error report.
    `endif

endinterface

// End the inclusion guard, ensuring this file is processed only once.
`endif