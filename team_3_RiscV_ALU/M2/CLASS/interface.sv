`include "rv32i_alu_header.sv"

// ALU Interface for RISC-V 32I implementation
// Handles communication between ALU and pipeline stages
interface alu_if (
    input logic i_clk,   // Main clock
    input logic i_rst_n  // Active-low asynchronous reset
);

  //////////////////////////////////////////////////
  // Input signals to ALU (Driven by Controller)  //
  //////////////////////////////////////////////////
  logic [`ALU_WIDTH-1:0] i_alu;  // ALU operation selection bits
  logic [4:0] i_rs1_addr;  // Source register 1 address
  logic [31:0] i_rs1;  // Source register 1 value
  logic [31:0] i_rs2;  // Source register 2 value
  logic [31:0] i_imm;  // Immediate value from instruction
  logic [2:0] i_funct3;  // 3-bit function code from instruction
  logic [`OPCODE_WIDTH-1:0] i_opcode;  // Instruction opcode
  logic [`EXCEPTION_WIDTH-1:0] i_exception;  // Exception status from previous stages
  logic [31:0] i_pc;  // Program counter value
  logic [4:0] i_rd_addr;  // Destination register address
  logic i_ce;  // Clock enable
  logic i_stall;  // Pipeline stall signal from controller
  logic i_force_stall;  // Debug stall signal
  logic i_flush;  // Pipeline flush signal

  ////////////////////////////////////////////////////
  // Output signals from ALU (To Writeback Stage)   //
  ////////////////////////////////////////////////////
  logic [4:0] o_rs1_addr;  // Bypassed RS1 address
  logic [31:0] o_rs1;  // Bypassed RS1 value
  logic [31:0] o_rs2;  // Bypassed RS2 value
  logic [11:0] o_imm;  // Bypassed immediate value (12-bit)
  logic [2:0] o_funct3;  // Bypassed function code
  logic [`OPCODE_WIDTH-1:0] o_opcode;  // Bypassed opcode
  logic [`EXCEPTION_WIDTH-1:0] o_exception;  // Propagated exception status
  logic [31:0] o_y;  // ALU computation result
  logic [31:0] o_pc;  // Current PC value
  logic [31:0] o_next_pc;  // Calculated next PC (for jumps/branches)
  logic o_change_pc;  // PC change request (1 = branch/jump taken)
  logic o_wr_rd;  // Write enable for destination register
  logic [4:0] o_rd_addr;  // Destination register address
  logic [31:0] o_rd;  // Data to write to destination register
  logic o_rd_valid;  // Destination register write valid
  logic o_stall_from_alu;  // ALU-generated stall request
  logic o_ce;  // Propagated clock enable
  logic o_stall;  // Combined stall signal output
  logic o_flush;  // Propagated flush signal

endinterface
