`include "rv32i_header.sv"
`include "uvm_macros.svh"
`include "rv32i_alu_transaction.sv" // Added include for transaction definition
import uvm_pkg::*;

class rv32i_alu_coverage extends uvm_subscriber #(rv32i_alu_transaction);

  `uvm_component_utils(rv32i_alu_coverage)

  // Define signal variables
  logic [`ALU_WIDTH-1:0] alu;
  logic [`OPCODE_WIDTH-1:0] opcode;
  logic [31:0] y;
  logic [31:0] imm;
  logic [`EXCEPTION_WIDTH-1:0] except;
  logic stall;
  logic force_stall;
  logic flush;

  covergroup alu_cg;
    coverpoint opcode {
      bins opcode_types[] = {`RTYPE, `ITYPE, `LOAD, `STORE, `BRANCH, `JAL, `JALR, `LUI, `AUIPC, `SYSTEM, `FENCE};
    }
    coverpoint alu {
      bins alu_ops[] = {`ADD, `SUB, `SLT, `SLTU, `XOR, `OR, `AND, `SLL, `SRL, `SRA, `EQ, `NEQ, `GE, `GEU};
    }
    alu_opcode_cross: cross opcode, alu;
    branch_condition: coverpoint y[0] iff (opcode == `BRANCH);
    stall_cover: coverpoint stall;
    force_stall_cover: coverpoint force_stall;
    flush_cover: coverpoint flush;
    imm_usage: coverpoint imm {
      bins imm_values[] = {[32'h0 : 32'hFFFF_FFFF]};
      option.at_least = 100;
    }
    exception_cover: coverpoint except {
      bins exceptions[] = {`ILLEGAL, `ECALL, `EBREAK, `MRET};
    }
  endgroup

  function new(string name = "rv32i_alu_coverage", uvm_component parent);
    super.new(name, parent);
    alu_cg = new();
  endfunction

  virtual function void write(rv32i_alu_transaction t);
    opcode = t.opcode;
    alu = t.alu_control;
    y = t.alu_result;
    imm = t.imm;
    except = t.exception;
    stall = t.stall;
    force_stall = t.force_stall;
    flush = t.flush;
    alu_cg.sample();
  endfunction

endclass
