// ----------------------------------------------------------------------------
// ECE593 M2 - RV32I ALU Transaction
// ----------------------------------------------------------------------------
// This file defines the transaction class used to generate stimulus for the
// RISC-V ALU design under verification. Each transaction represents a data
// packet containing input signals, control information, and expected results.
// ----------------------------------------------------------------------------

`ifndef TRANSACTION_SV
`define TRANSACTION_SV

`include "rv32i_alu_header.sv"

class transaction;
    //--------------------------------------------------------------------------
    // Randomized ALU Input Signals
    //--------------------------------------------------------------------------
    rand
    bit [13:0]
    i_alu;  // ALU control signal (14-bit one-hot encoded for different operations)
    rand bit [31:0] i_rs1;  // First operand (32-bit)
    rand bit [31:0] i_rs2;  // Second operand (32-bit)
    rand bit [31:0] i_imm;  // Immediate value (32-bit)
    rand
    bit [10:0]
    i_opcode;  // Opcode (11-bit) specifying the instruction type
    rand bit i_ce;  // Clock enable signal

    // Expected output for verification purposes
    bit [31:0] verify_y;  // Expected ALU result (32-bit)

    //--------------------------------------------------------------------------
    // Additional Input Signals (Control, Addressing, and Miscellaneous)
    //--------------------------------------------------------------------------
    bit i_clk;  // Clock signal
    bit i_rst_n;  // Active-low reset signal
    bit [4:0] i_rs1_addr;  // Address for source register 1 (5-bit)
    bit [2:0] i_funct3;  // Function field (3-bit)
    bit [`EXCEPTION_WIDTH-1:0] i_exception;  // Exception signal (width defined externally)
    bit [31:0] i_pc;  // Program counter (32-bit)
    bit [4:0] i_rd_addr;  // Destination register address (5-bit)
    bit i_stall;  // Stall signal
    bit i_force_stall;  // Force stall signal
    bit i_flush;  // Flush signal

    //--------------------------------------------------------------------------
    // Output Signals (For Monitoring and Verification)
    //--------------------------------------------------------------------------
    bit [4:0] o_rs1_addr;  // Output source register address
    bit [31:0] o_rs1;  // Output value of the first operand
    bit [31:0] o_rs2;  // Output value of the second operand
    bit [11:0] o_imm;  // Output immediate value (may be truncated)
    bit [2:0] o_funct3;  // Output function field
    bit [10:0] o_opcode;  // Output opcode
    bit [`EXCEPTION_WIDTH-1:0] o_exception;  // Output exception signal
    bit [31:0] o_y;  // Output ALU result
    bit [31:0] o_pc;  // Output program counter
    bit [31:0] o_next_pc;  // Output next program counter
    bit o_change_pc;  // Flag indicating a change in PC
    bit o_wr_rd;  // Write/read flag for destination register
    bit [4:0] o_rd_addr;  // Output destination register address
    bit [31:0] o_rd;  // Output data for destination register
    bit o_rd_valid;  // Validity flag for destination register data
    bit o_stall_from_alu;  // Stall signal coming from the ALU
    bit o_ce;  // Clock enable output
    bit o_stall;  // Stall signal output
    bit o_flush;  // Flush signal output

    //--------------------------------------------------------------------------
    // Constraints
    //--------------------------------------------------------------------------
    // Constraint for ALU control signal: enforce one-hot encoding and valid operations.
    constraint alu_ctrl_c {
        $onehot(i_alu);  // Ensure only one operation is selected.
        i_alu inside {14'b00000000000001,  // ADD
        14'b00000000000010,  // SUB
        14'b00000000000100,  // AND
        14'b00000000001000,  // OR
        14'b00000000010000,  // XOR
        14'b00000000100000,  // SLL
        14'b00000001000000,  // SRL
        14'b00000010000000,  // SRA
        14'b00000100000000,  // SLT
        14'b00001000000000,  // SLTU
        14'b00010000000000,  // EQ
        14'b00100000000000,  // NEQ
        14'b01000000000000,  // GE
        14'b10000000000000  // GEU
        };
    }

    // Constraint for opcode: restrict to valid instruction types.
    constraint opcode_c {
        i_opcode inside {11'b00000000000,  // R-type instructions
        11'b00000000001,  // I-type instructions
        11'b00000000010,  // Load instructions
        11'b00000000011,  // Store instructions
        11'b00000000100,  // Branch instructions
        11'b00000000101,  // Jump and Link (JAL)
        11'b00000000110,  // Jump and Link Register (JALR)
        11'b00000000111,  // Load Upper Immediate (LUI)
        11'b00000001000,  // Add Upper Immediate to PC (AUIPC)
        11'b00000001001,  // System instructions
        11'b00000001010  // Memory fence instructions
        };
    }

    // Constraint for clock enable distribution: 90% probability enabled.
    constraint ce_c {
        i_ce dist {
            1 := 90,
            0 := 10
        };
    }

    // Constraint to define valid ranges for operands (full 32-bit range).
    constraint operand_ranges {
        i_rs1 inside {[0 : (2 ** 32) - 1]};
        i_rs2 inside {[0 : (2 ** 32) - 1]};
        i_imm inside {[0 : (2 ** 32) - 1]};
    }

    // Special constraints (optional, can be activated externally):

    // Enforce that at least one operand is zero.
    constraint zero_operand_c {(i_rs1 == 0) || (i_rs2 == 0) || (i_imm == 0);}

    // Enforce that at least one operand is at its maximum value (0xFFFFFFFF).
    constraint max_value_c {
        (i_rs1 == 32'hFFFFFFFF) || (i_rs2 == 32'hFFFFFFFF) || (i_imm == 32'hFFFFFFFF);
    }

    // Enforce operands near the sign boundary (useful for testing sign-related behavior).
    constraint sign_boundary_c {
        (i_rs1 inside {32'h7FFFFFFF, 32'h80000000}) ||
            (i_rs2 inside {32'h7FFFFFFF, 32'h80000000});
    }

    //--------------------------------------------------------------------------
    // Constructor: Initialize all signals to default values.
    //--------------------------------------------------------------------------
    function new();
        // Initialize randomized inputs.
        i_alu            = 0;
        i_rs1            = 0;
        i_rs2            = 0;
        i_imm            = 0;
        i_opcode         = 0;
        i_ce             = 0;
        verify_y         = 0;

        // Initialize additional input signals.
        i_clk            = 0;
        i_rst_n          = 1;
        i_rs1_addr       = 0;
        i_funct3         = 0;
        i_exception      = 0;
        i_pc             = 0;
        i_rd_addr        = 0;
        i_stall          = 0;
        i_force_stall    = 0;
        i_flush          = 0;

        // Initialize output signals.
        o_rs1_addr       = 0;
        o_rs1            = 0;
        o_rs2            = 0;
        o_imm            = 0;
        o_funct3         = 0;
        o_opcode         = 0;
        o_exception      = 0;
        o_y              = 0;
        o_pc             = 0;
        o_next_pc        = 0;
        o_change_pc      = 0;
        o_wr_rd          = 0;
        o_rd_addr        = 0;
        o_rd             = 0;
        o_rd_valid       = 0;
        o_stall_from_alu = 0;
        o_ce             = 0;
        o_stall          = 0;
        o_flush          = 0;
    endfunction

    //--------------------------------------------------------------------------
    // Function: set_values
    // Configures the transaction inputs for a specific ALU operation.
    //
    // Parameters:
    //  alu_idx - Index corresponding to the one-hot ALU control bit.
    //  opcode  - Opcode specifying the instruction type.
    //  rs1     - First operand.
    //  rs2     - Second operand.
    //  imm     - Immediate value.
    //  ce      - Clock enable signal.
    //--------------------------------------------------------------------------
    function void set_values(int alu_idx, bit [10:0] opcode, bit [31:0] rs1,
                             bit [31:0] rs2, bit [31:0] imm, bit ce);
        i_alu          = 0;  // Clear previous ALU control settings.
        i_alu[alu_idx] = 1;  // Set the specified ALU control bit.
        i_opcode       = opcode;  // Set the instruction opcode.
        i_rs1          = rs1;  // Assign first operand.
        i_rs2          = rs2;  // Assign second operand.
        i_imm          = imm;  // Assign immediate value.
        i_ce           = ce;  // Set clock enable.
    endfunction

    //--------------------------------------------------------------------------
    // Function: alu_operation
    // Computes the expected ALU result based on the provided operands and control.
    //
    // Parameters:
    //  rs1      - First operand.
    //  rs2      - Second operand.
    //  imm      - Immediate value.
    //  alu_ctrl - ALU control signal (one-hot encoded).
    //
    // Returns:
    //  The expected result of the ALU operation.
    //--------------------------------------------------------------------------
    function bit [31:0] alu_operation(bit [31:0] rs1, bit [31:0] rs2,
                                      bit [31:0] imm, bit [13:0] alu_ctrl);
        case (alu_ctrl)
            14'b00000000000001:
            verify_y = rs1 + (i_opcode[0] ? imm : rs2);  // ADD
            14'b00000000000010:
            verify_y = rs1 - (i_opcode[0] ? imm : rs2);  // SUB
            14'b00000000000100:
            verify_y = rs1 & (i_opcode[0] ? imm : rs2);  // AND
            14'b00000000001000:
            verify_y = rs1 | (i_opcode[0] ? imm : rs2);  // OR
            14'b00000000010000:
            verify_y = rs1 ^ (i_opcode[0] ? imm : rs2);  // XOR
            14'b00000000100000:
            verify_y = rs1 << (i_opcode[0] ? imm[4:0] : rs2[4:0]);  // SLL
            14'b00000001000000:
            verify_y = rs1 >> (i_opcode[0] ? imm[4:0] : rs2[4:0]);  // SRL
            14'b00000010000000:
            verify_y = $signed(rs1) >>>
                (i_opcode[0] ? imm[4:0] : rs2[4:0]);  // SRA
            14'b00000100000000:
            verify_y = $signed(rs1) < $signed(rs2) ? 32'h1 : 32'h0;  // SLT
            14'b00001000000000: verify_y = rs1 < rs2 ? 32'h1 : 32'h0;  // SLTU
            14'b00010000000000: verify_y = (rs1 == rs2) ? 32'h1 : 32'h0;  // EQ
            14'b00100000000000: verify_y = (rs1 != rs2) ? 32'h1 : 32'h0;  // NEQ
            14'b01000000000000:
            verify_y = $signed(rs1) >= $signed(rs2) ? 32'h1 : 32'h0;  // GE
            14'b10000000000000: verify_y = rs1 >= rs2 ? 32'h1 : 32'h0;  // GEU
            default: verify_y = 0;
        endcase
        return verify_y;
    endfunction

    //--------------------------------------------------------------------------
    // Function: clone
    // Creates and returns an exact copy of the current transaction.
    //
    // Returns:
    //  A new transaction object with identical input and control values.
    //--------------------------------------------------------------------------
    function transaction clone();
        transaction clone_trans;
        clone_trans          = new();
        clone_trans.i_alu    = this.i_alu;
        clone_trans.i_rs1    = this.i_rs1;
        clone_trans.i_rs2    = this.i_rs2;
        clone_trans.i_imm    = this.i_imm;
        clone_trans.i_opcode = this.i_opcode;
        clone_trans.i_ce     = this.i_ce;
        clone_trans.verify_y = this.verify_y;
        return clone_trans;
    endfunction
endclass


`endif
