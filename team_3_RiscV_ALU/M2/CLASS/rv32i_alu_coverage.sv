`include "rv32i_header.sv"
`include "uvm_macros.svh"

covergroup alu_coverage(
    ref logic clk,
    ref logic [`ALU_WIDTH-1:0] alu,
    ref logic [`OPCODE_WIDTH-1:0] opcode,
    ref logic [31:0] y,
    ref logic [31:0] imm,
    ref logic [`EXCEPTION_WIDTH-1:0] except,
    ref logic stall,
    ref logic force_stall,
    ref logic flush
);
  // Coverpoint for each opcode
  opcode_cover: coverpoint opcode {
    bins opcode_types[] = {`RTYPE, `ITYPE, `LOAD, `STORE, `BRANCH, `JAL, `JALR, `LUI, `AUIPC, `SYSTEM, `FENCE};
  }

  // Coverpoint for each ALU operation
  alu_operation_cover: coverpoint alu {
    bins alu_ops[] = {`ADD, `SUB, `SLT, `SLTU, `XOR, `OR, `AND, `SLL, `SRL, `SRA, `EQ, `NEQ, `GE, `GEU};
  }

  // Cross coverage for opcode and ALU operation combinations
  alu_opcode_cross: cross opcode_cover, alu_operation_cover;

  // Specific scenario coverage
  // Cover branch condition when a branch opcode is active
  branch_condition: coverpoint y[0] iff (opcode == `BRANCH);

  // Coverage for control signals
  stall_cover: coverpoint stall;
  force_stall_cover: coverpoint force_stall;
  flush_cover: coverpoint flush;

  // Cover immediate value usage (simplified here due to complexity)
  imm_usage: coverpoint imm {
    bins imm_values[] = {[32'h0 : 32'hFFFF_FFFF]};
    option.at_least = 100;  // Ensure at least 100 different immediate values are covered
  }

  // Coverage for exceptions
  exception_cover: coverpoint except {
    bins exceptions[] = {`ILLEGAL, `ECALL, `EBREAK, `MRET};
  }
endgroup

class alu_coverage_class extends uvm_object;
  `uvm_object_utils(alu_coverage_class)

  alu_coverage cg;

  function new(string name = "alu_coverage_class");
    super.new(name);
  endfunction

  // Method to connect coverage group to signals
  function void connect(input logic clk, input logic [`ALU_WIDTH-1:0] alu,
                        input logic [`OPCODE_WIDTH-1:0] opcode, input logic [31:0] y,
                        input logic [31:0] imm, input logic [`EXCEPTION_WIDTH-1:0] except,
                        input logic stall, input logic force_stall, input logic flush);
    cg = new(clk, alu, opcode, y, imm, except, stall, force_stall, flush);
  endfunction
endclass
