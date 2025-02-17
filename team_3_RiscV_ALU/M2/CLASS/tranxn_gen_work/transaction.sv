class transaction;
    // ALU inputs
    rand bit [13:0] i_alu;    // Control signal for ALU operation
    rand bit [3:0]  i_rs1;    // First operand
    rand bit [3:0]  i_imm;    // Immediate value
    rand bit [2:0]  i_opcode; // Opcode
    rand bit        i_ce;      // Clock enable
    bit [3:0]      verify_y;  // Expected output

    // Constraints
    constraint alu_ctrl_c {
      $onehot(i_alu);         // Only one bit active at a time
      i_alu inside {14'b00000000000001, 14'b00000000000010}; // ADD or SUB
    }

    constraint opcode_c {
      i_opcode inside {3'b000, 3'b001}; // Valid opcodes
    }

    constraint ce_c {
      i_ce dist {1 := 90, 0 := 10}; // 90% chance of being enabled
    }

    constraint operand_ranges {
      i_rs1 inside {[0:15]};
      i_imm inside {[0:15]};
    }

    // Special constraints that can be enabled/disabled
    constraint zero_operand_c {
      (i_rs1 == 0) || (i_imm == 0);
    }

    constraint max_value_c {
      (i_rs1 == 4'hF) || (i_imm == 4'hF);
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

    function void set_values(int alu_idx, bit [2:0] opcode, bit [3:0] rs1, bit [3:0] imm, bit ce);
      i_alu = 0;
      i_alu[alu_idx] = 1;
      i_opcode = opcode;
      i_rs1 = rs1;
      i_imm = imm;
      i_ce = ce;
    endfunction

    function bit [3:0] alu_operation(bit [3:0] rs1, bit [3:0] imm, bit [13:0] alu_ctrl);
      case (alu_ctrl)
        14'b00000000000001: verify_y = rs1 + imm;  // ADD
        14'b00000000000010: verify_y = rs1 - imm;  // SUB
        default: verify_y = 0;
      endcase
      return verify_y;
    endfunction
endclass

