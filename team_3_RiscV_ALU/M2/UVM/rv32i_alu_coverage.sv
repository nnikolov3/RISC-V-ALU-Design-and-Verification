class rv32i_alu_coverage extends uvm_subscriber #(rv32i_alu_transaction);
  `uvm_component_utils(rv32i_alu_coverage)

  // Coverage for ALU operations
  covergroup alu_ops_cg;
    alu_operation: coverpoint trans.alu {
      bins add  = {`ADD};
      bins sub  = {`SUB};
      bins slt  = {`SLT};
      bins sltu = {`SLTU};
      bins xor  = {`XOR};
      bins or   = {`OR};
      bins and  = {`AND};
      bins sll  = {`SLL};
      bins srl  = {`SRL};
      bins sra  = {`SRA};
      bins eq   = {`EQ};
      bins neq  = {`NEQ};
      bins ge   = {`GE};
      bins geu  = {`GEU};
    }
  endgroup

  // Coverage for opcodes
  covergroup opcode_cg;
    opcode: coverpoint trans.opcode {
      bins rtype  = {`RTYPE};
      bins itype  = {`ITYPE};
      bins load   = {`LOAD};
      bins store  = {`STORE};
      bins branch = {`BRANCH};
      bins jal    = {`JAL};
      bins jalr   = {`JALR};
      bins lui    = {`LUI};
      bins auipc  = {`AUIPC};
      bins system = {`SYSTEM};
      bins fence  = {`FENCE};
    }
  endgroup

  // Cross coverage between ALU operations and opcodes
  covergroup alu_opcode_cross_cg;
    alu_op: coverpoint trans.alu {
      bins arithmetic = {`ADD, `SUB};
      bins logical   = {`AND, `OR, `XOR};
      bins shift     = {`SLL, `SRL, `SRA};
      bins compare   = {`SLT, `SLTU, `EQ, `NEQ, `GE, `GEU};
    }

    op: coverpoint trans.opcode {
      bins compute = {`RTYPE, `ITYPE};
      bins memory  = {`LOAD, `STORE};
      bins control = {`BRANCH, `JAL, `JALR};
      bins special = {`LUI, `AUIPC, `SYSTEM, `FENCE};
    }

    alu_op_x_opcode: cross alu_op, op;
  endgroup

  // Coverage for operand corner cases
  covergroup operand_cg;
    rs1_value: coverpoint trans.rs1 {
      bins zero     = {32'h0};
      bins max_pos  = {32'h7FFFFFFF};
      bins max_neg  = {32'h80000000};
      bins max_unsigned = {32'hFFFFFFFF};
      bins others   = default;
    }

    rs2_value: coverpoint trans.rs2 {
      bins zero     = {32'h0};
      bins max_pos  = {32'h7FFFFFFF};
      bins max_neg  = {32'h80000000};
      bins max_unsigned = {32'hFFFFFFFF};
      bins others   = default;
    }

    imm_value: coverpoint trans.imm {
      bins zero     = {32'h0};
      bins max_pos  = {32'h7FFFFFFF};
      bins max_neg  = {32'h80000000};
      bins others   = default;
    }
  endgroup

  // Coverage for pipeline control signals
  covergroup pipeline_control_cg;
    stall: coverpoint {trans.stall, trans.force_stall, trans.flush} {
      bins no_stall     = {3'b000};
      bins normal_stall = {3'b100};
      bins force_stall  = {3'b010};
      bins flush        = {3'b001};
      bins stall_flush  = {3'b101};
      bins illegal      = default;
    }

    ce_control: coverpoint trans.ce {
      bins enabled  = {1'b1};
      bins disabled = {1'b0};
    }

    stall_x_ce: cross stall, ce_control;
  endgroup

  // Coverage for register writeback
  covergroup writeback_cg;
    rd_addr: coverpoint trans.rd_addr {
      bins zero_reg = {5'h0};
      bins gp_regs[8] = {[1:31]};
    }

    wr_rd: coverpoint trans.wr_rd {
      bins write  = {1'b1};
      bins no_write = {1'b0};
    }

    rd_valid: coverpoint trans.rd_valid {
      bins valid = {1'b1};
      bins invalid = {1'b0};
    }

    writeback_control: cross wr_rd, rd_valid;
  endgroup

  function new(string name = "rv32i_alu_coverage", uvm_component parent);
    super.new(name, parent);
    alu_ops_cg = new();
    opcode_cg = new();
    alu_opcode_cross_cg = new();
    operand_cg = new();
    pipeline_control_cg = new();
    writeback_cg = new();
  endfunction

  function void write(rv32i_alu_transaction t);
    trans = t;
    alu_ops_cg.sample();
    opcode_cg.sample();
    alu_opcode_cross_cg.sample();
    operand_cg.sample();
    pipeline_control_cg.sample();
    writeback_cg.sample();
  endfunction

  // Suggested transaction class structure
  virtual class rv32i_alu_transaction extends uvm_sequence_item;
    rand bit [`ALU_WIDTH-1:0] alu;
    rand bit [4:0] rs1_addr;
    rand bit [31:0] rs1;
    rand bit [31:0] rs2;
    rand bit [31:0] imm;
    rand bit [2:0] funct3;
    rand bit [`OPCODE_WIDTH-1:0] opcode;
    rand bit [`EXCEPTION_WIDTH-1:0] exception;
    rand bit [31:0] pc;
    rand bit [4:0] rd_addr;
    rand bit ce;
    rand bit stall;
    rand bit force_stall;
    rand bit flush;
    rand bit wr_rd;
    rand bit rd_valid;

    // Add constraints here as needed
    constraint valid_alu_op {
      $onehot(alu) == 1;
    }

    constraint valid_opcode {
      $onehot(opcode) == 1;
    }

    `uvm_object_utils_begin(rv32i_alu_transaction)
      `uvm_field_int(alu, UVM_ALL_ON)
      `uvm_field_int(rs1_addr, UVM_ALL_ON)
      `uvm_field_int(rs1, UVM_ALL_ON)
      `uvm_field_int(rs2, UVM_ALL_ON)
      `uvm_field_int(imm, UVM_ALL_ON)
      `uvm_field_int(funct3, UVM_ALL_ON)
      `uvm_field_int(opcode, UVM_ALL_ON)
      `uvm_field_int(exception, UVM_ALL_ON)
      `uvm_field_int(pc, UVM_ALL_ON)
      `uvm_field_int(rd_addr, UVM_ALL_ON)
      `uvm_field_int(ce, UVM_ALL_ON)
      `uvm_field_int(stall, UVM_ALL_ON)
      `uvm_field_int(force_stall, UVM_ALL_ON)
      `uvm_field_int(flush, UVM_ALL_ON)
      `uvm_field_int(wr_rd, UVM_ALL_ON)
      `uvm_field_int(rd_valid, UVM_ALL_ON)
    `uvm_object_utils_end
  endclass
endclass