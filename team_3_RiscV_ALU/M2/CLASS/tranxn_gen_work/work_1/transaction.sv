`include "rv32i_header.sv"

class transaction;
    // ALU inputs with expanded operations
    rand bit [13:0] i_alu;    // Control signal for ALU operation (14 bits for all operations)
    rand bit [31:0] i_rs1;    // First operand (32 bits)
    rand bit [31:0] i_rs2;    // Second operand (32 bits) - Added
    rand bit [31:0] i_imm;    // Immediate value (32 bits)
    rand bit [10:0] i_opcode; // Opcode (11 bits)
    rand bit        i_ce;     // Clock enable
    bit [31:0]     verify_y;  // Expected output

    // Constraints
    constraint alu_ctrl_c {
        $onehot(i_alu);         // Only one bit active at a time
        i_alu inside {
            14'b00000000000001, // ADD
            14'b00000000000010, // SUB
            14'b00000000000100, // AND
            14'b00000000001000, // OR
            14'b00000000010000, // XOR
            14'b00000000100000, // SLL
            14'b00000001000000, // SRL
            14'b00000010000000, // SRA
            14'b00000100000000, // SLT
            14'b00001000000000, // SLTU
            14'b00010000000000, // EQ
            14'b00100000000000, // NEQ
            14'b01000000000000, // GE
            14'b10000000000000  // GEU
        };
    }

constraint opcode_c {
    i_opcode inside {
        11'b00000000000,  // R-type instructions
        11'b00000000001,  // I-type instructions
        11'b00000000010,  // Load instructions
        11'b00000000011,  // Store instructions
        11'b00000000100,  // Branch instructions
        11'b00000000101,  // Jump and Link
        11'b00000000110,  // Jump and Link Register
        11'b00000000111,  // Load Upper Immediate
        11'b00000001000,  // Add Upper Immediate to PC
        11'b00000001001,  // System instructions
        11'b00000001010   // Memory fence
    };
}


    constraint ce_c {
        i_ce dist {1 := 90, 0 := 10}; // 90% chance of being enabled
    }

    constraint operand_ranges {
        i_rs1 inside {[0:(2**32)-1]};
        i_rs2 inside {[0:(2**32)-1]};
        i_imm inside {[0:(2**32)-1]};
    }

    // Special constraints (can be enabled/disabled)
    constraint zero_operand_c {
        (i_rs1 == 0) || (i_rs2 == 0) || (i_imm == 0);
    }

    constraint max_value_c {
        (i_rs1 == 32'hFFFFFFFF) || (i_rs2 == 32'hFFFFFFFF) || (i_imm == 32'hFFFFFFFF);
    }

    constraint sign_boundary_c {
        (i_rs1 inside {32'h7FFFFFFF, 32'h80000000}) ||
        (i_rs2 inside {32'h7FFFFFFF, 32'h80000000});
    }

    function new();
        i_alu = 0;
        i_rs1 = 0;
        i_rs2 = 0;
        i_imm = 0;
        i_opcode = 0;
        i_ce = 0;
        verify_y = 0;
    endfunction

    function void set_values(int alu_idx, bit [10:0] opcode, bit [31:0] rs1, bit [31:0] rs2, bit [31:0] imm, bit ce);
        i_alu = 0;
        i_alu[alu_idx] = 1;
        i_opcode = opcode;
        i_rs1 = rs1;
        i_rs2 = rs2;
        i_imm = imm;
        i_ce = ce;
    endfunction

    function bit [31:0] alu_operation(bit [31:0] rs1, bit [31:0] rs2, bit [31:0] imm, bit [13:0] alu_ctrl);
        case (alu_ctrl)
            14'b00000000000001: verify_y = rs1 + (i_opcode[0] ? imm : rs2);  // ADD
            14'b00000000000010: verify_y = rs1 - (i_opcode[0] ? imm : rs2);  // SUB
            14'b00000000000100: verify_y = rs1 & (i_opcode[0] ? imm : rs2);  // AND
            14'b00000000001000: verify_y = rs1 | (i_opcode[0] ? imm : rs2);  // OR
            14'b00000000010000: verify_y = rs1 ^ (i_opcode[0] ? imm : rs2);  // XOR
            14'b00000000100000: verify_y = rs1 << (i_opcode[0] ? imm[4:0] : rs2[4:0]);  // SLL
            14'b00000001000000: verify_y = rs1 >> (i_opcode[0] ? imm[4:0] : rs2[4:0]);  // SRL
            14'b00000010000000: verify_y = $signed(rs1) >>> (i_opcode[0] ? imm[4:0] : rs2[4:0]);  // SRA
            14'b00000100000000: verify_y = $signed(rs1) < $signed(rs2) ? 32'h1 : 32'h0;  // SLT
            14'b00001000000000: verify_y = rs1 < rs2 ? 32'h1 : 32'h0;  // SLTU
            14'b00010000000000: verify_y = (rs1 == rs2) ? 32'h1 : 32'h0;  // EQ
            14'b00100000000000: verify_y = (rs1 != rs2) ? 32'h1 : 32'h0;  // NEQ
            14'b01000000000000: verify_y = $signed(rs1) >= $signed(rs2) ? 32'h1 : 32'h0;  // GE
            14'b10000000000000: verify_y = rs1 >= rs2 ? 32'h1 : 32'h0;  // GEU
            default: verify_y = 0;
        endcase
        return verify_y;
    endfunction

    // Clone function remains the same
    function transaction clone();
        transaction clone_trans;
        clone_trans = new();
        clone_trans.i_alu = this.i_alu;
        clone_trans.i_rs1 = this.i_rs1;
        clone_trans.i_rs2 = this.i_rs2;
        clone_trans.i_imm = this.i_imm;
        clone_trans.i_opcode = this.i_opcode;
        clone_trans.i_ce = this.i_ce;
        clone_trans.verify_y = this.verify_y;
        return clone_trans;
    endfunction
endclass
