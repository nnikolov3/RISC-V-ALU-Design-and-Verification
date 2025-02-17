class transaction;
    // ALU inputs
    rand bit [13:0] i_alu;    // Control signal for ALU operation (14 bits)
    rand bit [31:0] i_rs1;    // First operand (32 bits)
    rand bit [31:0] i_imm;    // Immediate value (32 bits)
    rand bit [10:0] i_opcode; // Opcode (11 bits)
    rand bit        i_ce;     // Clock enable
    bit [31:0]     verify_y;  // Expected output

    // Constraints
    constraint alu_ctrl_c {
      $onehot(i_alu);         // Only one bit active at a time
      i_alu inside {14'b00000000000001, 14'b00000000000010}; // ADD or SUB
    }

    constraint opcode_c {
      i_opcode inside {11'b00000000000, 11'b00000000001}; // Valid opcodes
    }

    constraint ce_c {
      i_ce dist {1 := 90, 0 := 10}; // 90% chance of being enabled
    }

    constraint operand_ranges {
      i_rs1 inside {[0:(2**32)-1]};  // Full 32-bit range
      i_imm inside {[0:(2**32)-1]};  // Full 32-bit range
    }

    // Special constraints that can be enabled/disabled
    constraint zero_operand_c {
      (i_rs1 == 0) || (i_imm == 0);
    }

    constraint max_value_c {
      (i_rs1 == 32'hFFFFFFFF) || (i_imm == 32'hFFFFFFFF);
    }

    constraint negative_result_c {
      if (i_alu[1]) {  // For SUB operation
        i_rs1 < i_imm;
      }
    }

    function new();
      i_alu = 0;
      i_rs1 = 0;
      i_imm = 0;
      i_opcode = 0;
      i_ce = 0;
      verify_y = 0;
    endfunction

    function void set_values(int alu_idx, bit [10:0] opcode, bit [31:0] rs1, bit [31:0] imm, bit ce);
      i_alu = 0;
      i_alu[alu_idx] = 1;
      i_opcode = opcode;
      i_rs1 = rs1;
      i_imm = imm;
      i_ce = ce;
    endfunction

    function bit [31:0] alu_operation(bit [31:0] rs1, bit [31:0] imm, bit [13:0] alu_ctrl);
      case (alu_ctrl)
        14'b00000000000001: verify_y = rs1 + imm;  // ADD
        14'b00000000000010: verify_y = rs1 - imm;  // SUB
        default: verify_y = 0;
      endcase
      return verify_y;
    endfunction

    // Clone function for mailbox implementation
    function transaction clone();
      transaction clone_trans;
      clone_trans = new();
      clone_trans.i_alu = this.i_alu;
      clone_trans.i_rs1 = this.i_rs1;
      clone_trans.i_imm = this.i_imm;
      clone_trans.i_opcode = this.i_opcode;
      clone_trans.i_ce = this.i_ce;
      clone_trans.verify_y = this.verify_y;
      return clone_trans;
    endfunction
endclass
