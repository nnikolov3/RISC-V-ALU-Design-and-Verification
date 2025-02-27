// ----------------------------------------------------------------------------
// *********************************************
// ALU Interface for RISC-V 32I Implementation
// ECE 593: Milestone 4, Group 3
// File: interface.sv
// Class: alu_if
// Description:
// This SystemVerilog interface defines the signal connections between the
// RV32I Arithmetic Logic Unit (ALU) and pipeline stages in a verification
// environment. It includes input signals from the controller, output signals
// to the writeback stage, clocking blocks for testbench and DUT synchronization,
// modports for DUT and testbench connectivity, and assertions for signal
// integrity. Parameterized widths allow customization of ALU operations,
// opcodes, and exceptions.
// Updated: Feb 26, 2025
// **********************************************
// ----------------------------------------------------------------------------
`include "rv32i_alu_header.sv"
`timescale 1ns / 1ps `default_nettype none
`ifndef ALU_IF_SV
`define ALU_IF_SV

interface alu_if (

    input wire i_clk,   // Main clock
    input wire i_rst_n  // Active-low asynchronous reset

);
    // ------------------------------------------------------------------------
    // Parameter Definitions
    // Description:
    //   Defines configurable parameters for ALU operation width, opcode width,
    //   and exception width. Uses values from the header file if defined;
    //   otherwise, sets default values.
    // ------------------------------------------------------------------------
    `ifdef ALU_WIDTH
        localparam ALU_WIDTH = `ALU_WIDTH;
    `else
        localparam ALU_WIDTH = 4;           // Default to 4-bit ALU operation width
    `endif

    `ifdef OPCODE_WIDTH
        localparam OPCODE_WIDTH = `OPCODE_WIDTH;
    `else
        localparam OPCODE_WIDTH = 7;        // Default to 7-bit RISC-V opcode width
    `endif

    `ifdef EXCEPTION_WIDTH
        localparam EXCEPTION_WIDTH = `EXCEPTION_WIDTH;
    `else
        localparam EXCEPTION_WIDTH = 2;     // Default to 2-bit exception width
    `endif

    // ------------------------------------------------------------------------
    // Input Signals to ALU (Driven by Controller)
    //
    // Description:
    //   Signals driven by the controller or testbench to stimulate the ALU.
    // ------------------------------------------------------------------------
    logic [ALU_WIDTH-1:0]       i_alu;         // ALU operation selection bits
    logic [4:0]                 i_rs1_addr;    // Source register 1 address (5-bit)
    logic [31:0]                i_rs1;         // Source register 1 value (32-bit)
    logic [31:0]                i_rs2;         // Source register 2 value (32-bit)
    logic [31:0]                i_imm;         // Immediate value from instruction (32-bit)
    logic [2:0]                 i_funct3;      // 3-bit function code from instruction
    logic [OPCODE_WIDTH-1:0]    i_opcode;      // Instruction opcode (parameterized width)
    logic [EXCEPTION_WIDTH-1:0] i_exception;   // Exception status from previous stages
    logic [31:0]                i_pc;          // Current program counter value (32-bit)
    logic [4:0]                 i_rd_addr;     // Destination register address (5-bit)
    logic                       i_ce;          // Clock enable signal
    logic                       i_stall;       // Pipeline stall signal from controller
    logic                       i_force_stall; // Debug/testbench-forced stall signal
    logic                       i_flush;       // Pipeline flush signal



    ////////////////////////////////////////////////////
    // Output signals from ALU (To Writeback Stage)   //
    ////////////////////////////////////////////////////
    logic [4:0]                 o_rs1_addr;        // Bypassed RS1 address
    logic [31:0]                o_rs1;             // Bypassed RS1 value
    logic [31:0]                o_rs2;             // Bypassed RS2 value
    logic [11:0]                o_imm;             // Bypassed immediate value (32-bit)
    logic [2:0]                 o_funct3;          // Bypassed function code
    logic [OPCODE_WIDTH-1:0]    o_opcode;          // Bypassed opcode
    logic [EXCEPTION_WIDTH-1:0] o_exception;       // Propagated exception status
    logic [31:0]                o_y;               // ALU computation result (32-bit)
    logic [31:0]                o_pc;              // Current PC value (32-bit)
    logic [31:0]                o_next_pc;         // Calculated next PC for jumps/branches
    logic                       o_change_pc;       // PC change request (1 = branch/jump taken)
    logic                       o_wr_rd;           // Write enable for destination register
    logic [4:0]                 o_rd_addr;         // Destination register address (5-bit)
    logic [31:0]                o_rd;              // Data to write to destination register
    logic                       o_rd_valid;        // Destination register write valid signal
    logic                       o_stall_from_alu;  // ALU-generated stall request
    logic                       o_ce;              // Propagated clock enable signal
    logic                       o_stall;           // Combined stall signal output
    logic                       o_flush;           // Propagated flush signal

    // ------------------------------------------------------------------------
    // Clocking Block: cb_input
    // Description:
    //   Clocking block for the testbench to drive input signals to the DUT,
    //   synchronized to the positive clock edge with a 1ns output delay.
    // ------------------------------------------------------------------------
    clocking cb_input @(posedge i_clk);
        default output #1ns;  // Output delay for timing alignment
        output i_alu, i_rs1_addr, i_rs1, i_rs2, i_imm, i_funct3,
               i_opcode, i_exception, i_pc, i_rd_addr, i_ce,
               i_stall, i_force_stall, i_flush;
    endclocking

    // ------------------------------------------------------------------------
    // Clocking Block: cb_output
    // Description:
    //   Clocking block for the testbench to sample output signals from the DUT,
    //   synchronized to the positive clock edge with a 1ns input delay.
    // ------------------------------------------------------------------------
    clocking cb_output @(posedge i_clk);
        default input #1ns;   // Input delay for timing alignment
        input o_rs1_addr, o_rs1, o_rs2, o_imm, o_funct3,
              o_opcode, o_exception, o_y, o_pc, o_next_pc,
              o_change_pc, o_wr_rd, o_rd_addr, o_rd,
              o_rd_valid, o_stall_from_alu, o_ce, o_stall, o_flush;
    endclocking

    // ------------------------------------------------------------------------
    // Clocking Block: cb_dut_input
    // Description:
    //   Clocking block for the DUT to sample input signals, synchronized to the
    //   positive clock edge with a 1ns input delay.
    // ------------------------------------------------------------------------
    clocking cb_dut_input @(posedge i_clk);
        default input #1ns;   // Input delay for timing alignment
        input i_alu, i_rs1_addr, i_rs1, i_rs2, i_imm, i_funct3,
              i_opcode, i_exception, i_pc, i_rd_addr, i_ce,
              i_stall, i_force_stall, i_flush;
    endclocking

    // ------------------------------------------------------------------------
    // Modport: DUT
    // Description:
    //   Modport defining the DUT’s perspective, specifying inputs it receives
    //   and outputs it drives, along with its clocking block for input sampling.
    // ------------------------------------------------------------------------
    modport DUT (
        input  i_alu, i_rs1_addr, i_rs1, i_rs2, i_imm, i_funct3,
               i_opcode, i_exception, i_pc, i_rd_addr, i_ce,
               i_stall, i_force_stall, i_flush,
        output o_rs1_addr, o_rs1, o_rs2, o_imm, o_funct3,
               o_opcode, o_exception, o_y, o_pc, o_next_pc,
               o_change_pc, o_wr_rd, o_rd_addr, o_rd, o_rd_valid,
               o_stall_from_alu, o_ce, o_stall, o_flush,
        clocking cb_dut_input
    );

    // ------------------------------------------------------------------------
    // Modport: TB
    // Description:
    //   Modport defining the testbench’s perspective, specifying outputs it
    //   drives and inputs it monitors, along with its clocking blocks for
    //   driving and sampling.
    // ------------------------------------------------------------------------
    modport TB (
        output i_alu, i_rs1_addr, i_rs1, i_rs2, i_imm, i_funct3,
               i_opcode, i_exception, i_pc, i_rd_addr, i_ce,
               i_stall, i_force_stall, i_flush,
        input  o_rs1_addr, o_rs1, o_rs2, o_imm, o_funct3,
               o_opcode, o_exception, o_y, o_pc, o_next_pc,
               o_change_pc, o_wr_rd, o_rd_addr, o_rd, o_rd_valid,
               o_stall_from_alu, o_ce, o_stall, o_flush,
        clocking cb_input, cb_output
    );

    // ------------------------------------------------------------------------
    // Assertions: Signal Integrity Checks
    // Description:
    //   Defines properties to ensure proper signal behavior, with UVM-aware
    //   error reporting if available, and fallback to standard $error otherwise.
    // ------------------------------------------------------------------------
    `ifdef UVM
        // Assertion 1: Stall and flush should not be asserted simultaneously
        property stall_flush_conflict;
            @(posedge i_clk) disable iff (!i_rst_n)
            !(i_stall && i_flush);
        endproperty
        assert property (stall_flush_conflict)
            else `uvm_error("IF", "Stall and flush asserted simultaneously");

        // Assertion 2: Clock enable should not be asserted during reset
        property ce_during_reset;
            @(posedge i_clk)
            !i_rst_n |-> !i_ce;
        endproperty
        assert property (ce_during_reset)
            else `uvm_error("IF", "Clock enable asserted during reset");
    `else
        // Fallback assertions without UVM
        property stall_flush_conflict;
            @(posedge i_clk) disable iff (!i_rst_n)
            !(i_stall && i_flush);
        endproperty
        assert property (stall_flush_conflict)
            else $error("Stall and flush asserted simultaneously");

        property ce_during_reset;
            @(posedge i_clk)
            !i_rst_n |-> !i_ce;
        endproperty
        assert property (ce_during_reset)
            else $error("Clock enable asserted during reset");
    `endif

endinterface
`endif
