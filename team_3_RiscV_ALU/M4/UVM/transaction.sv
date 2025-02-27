// ----------------------------------------------------------------------------
// ECE593 M4 - RV32I ALU Transaction (Updated)
// ----------------------------------------------------------------------------
// This file defines the transaction class used to generate stimulus for the
// RISC-V ALU design under verification. It extends uvm_sequence_item for
// compatibility with UVM sequencers and drivers.
// Updated: Feb 26, 2025
// ----------------------------------------------------------------------------
`ifndef TRANSACTION_SV
`define TRANSACTION_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "rv32i_alu_header.sv"

class transaction extends uvm_sequence_item;
    `uvm_object_utils(transaction)

    //--------------------------------------------------------------------------
    // Randomized Input Signals (for stimulus generation)
    //--------------------------------------------------------------------------
    rand bit [                13:0] i_alu;  // ALU control signal (14-bit one-hot encoded)
    rand bit [                31:0] i_rs1;  // First operand (32-bit)
    rand bit [                31:0] i_rs2;  // Second operand (32-bit)
    rand bit [                31:0] i_imm;  // Immediate value (32-bit)
    rand bit [   `OPCODE_WIDTH-1:0] i_opcode;  // Opcode (7-bit, aligned with rv32i_alu_header.sv)
    rand bit                        i_ce;  // Clock enable signal
    rand bit [                 4:0] i_rs1_addr;  // Address for source register 1 (5-bit)
    rand bit [                 2:0] i_funct3;  // Function field (3-bit)
    rand bit [                31:0] i_pc;  // Program counter (32-bit)
    rand bit [                 4:0] i_rd_addr;  // Destination register address (5-bit)
    bit                        i_stall;  // Stall signal
    bit                        i_force_stall;  // Force stall signal
    bit                        i_flush;  // Flush signal
    rand bit                        i_rst_n;  // Active-low reset signal

    // Non-randomized fields (set externally or in specific cases)
    bit      [`EXCEPTION_WIDTH-1:0] i_exception;  // Exception signal

    //--------------------------------------------------------------------------
    // Output Signals (for monitoring and verification, not driven to DUT)
    //--------------------------------------------------------------------------
    bit      [                 4:0] o_rs1_addr;  // Output source register address
    bit      [                31:0] o_rs1;  // Output value of the first operand
    bit      [                31:0] o_rs2;  // Output value of the second operand
    bit      [                31:0] o_imm;  // Output immediate value (32-bit)
    bit      [                 2:0] o_funct3;  // Output function field
    bit      [   `OPCODE_WIDTH-1:0] o_opcode;  // Output opcode
    bit      [`EXCEPTION_WIDTH-1:0] o_exception;  // Output exception signal
    bit      [                31:0] o_y;  // Output ALU result
    bit      [                31:0] o_pc;  // Output program counter
    bit      [                31:0] o_next_pc;  // Output next program counter
    bit                             o_change_pc;  // Flag indicating a change in PC
    bit                             o_wr_rd;  // Write/read flag for destination register
    bit      [                 4:0] o_rd_addr;  // Output destination register address
    bit      [                31:0] o_rd;  // Output data for destination register
    bit                             o_rd_valid;  // Validity flag for destination register data
    bit                             o_stall_from_alu;  // Stall signal from the ALU
    bit                             o_ce;  // Clock enable output
    bit                             o_stall;  // Stall signal output
    bit                             o_flush;  // Flush signal output

    // Expected output for verification
    bit      [                31:0] verify_y;  // Expected ALU result (32-bit)

    //--------------------------------------------------------------------------
    // Constraints
    //--------------------------------------------------------------------------
    // Constraint for ALU control: one-hot and valid operations
    constraint alu_ctrl_c {
        $onehot(i_alu);
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
        14'b10000000000000};  // GEU
    }

    // Constraint for opcode: valid RISC-V instruction types (7-bit)
    constraint opcode_c {
        i_opcode inside {11'b00000000001,  // R-type
        11'b00000000010,  // I-type
        11'b00000000100,  // Load
        11'b00000001000,  // Store
        11'b00000010000,  // Branch
        11'b00000100000,  // JAL
        11'b00001000000,  // JALR
        11'b00010000000,  // LUI
        11'b00100000000,  // AUIPC
        11'b01000000000,  // System
        11'b10000000000};  // Fence
    }

    // Constraint for clock enable: 90% enabled
    constraint ce_c {
        i_ce dist {
            1 := 90,
            0 := 10
        };
    }

    // Constraint for reset: defaults to active (1) unless testing reset
    constraint reset_c {
        i_rst_n dist {
            1 := 95,
            0 := 5
        };
    }

    // Constraint for operand ranges
    constraint operand_ranges {
        i_rs1 inside {[0 : (1 << 32) - 1]};
        i_rs2 inside {[0 : (1 << 32) - 1]};
        i_imm inside {[0 : (1 << 32) - 1]};
    }

    // Special constraints (can be activated externally)
    constraint zero_operand_c {(i_rs1 == 0) || (i_rs2 == 0) || (i_imm == 0);}
    constraint max_value_c {
        (i_rs1 == 32'hFFFFFFFF) || (i_rs2 == 32'hFFFFFFFF) || (i_imm == 32'hFFFFFFFF);
    }
    constraint sign_boundary_c {
        (i_rs1 inside {32'h7FFFFFFF, 32'h80000000}) || (i_rs2 inside {32'h7FFFFFFF, 32'h80000000});
    }

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "transaction");
        super.new(name);
        // Initialize non-randomized fields to defaults
        i_exception = 0;
    endfunction

    //--------------------------------------------------------------------------
    // Function: set_values
    // Manually set transaction fields for predefined scenarios
    //--------------------------------------------------------------------------
    function void set_values(int alu_idx, bit [`OPCODE_WIDTH-1:0] opcode, bit [31:0] rs1,
                             bit [31:0] rs2, bit [31:0] imm, bit ce);
        i_alu          = 0;  // Clear previous ALU control settings
        i_alu[alu_idx] = 1;  // Set the specified ALU control bit
        i_opcode       = opcode;  // Set the instruction opcode
        i_rs1          = rs1;  // Assign first operand
        i_rs2          = rs2;  // Assign second operand
        i_imm          = imm;  // Assign immediate value
        i_ce           = ce;  // Set clock enable
        i_rst_n        = 1;  // Default to active unless explicitly testing reset
    endfunction

    //--------------------------------------------------------------------------
    // Function: alu_operation
    // Computes the expected ALU result based on class fields
    //--------------------------------------------------------------------------
    function bit [31:0] alu_operation();
        bit [31:0] operand_b = (i_opcode == 7'b0010011) ? i_imm :
            i_rs2;  // Use imm for I-type, rs2 otherwise
        case (i_alu)
            14'b00000000000001: verify_y = i_rs1 + operand_b;  // ADD
            14'b00000000000010: verify_y = i_rs1 - operand_b;  // SUB
            14'b00000000000100: verify_y = i_rs1 & operand_b;  // AND
            14'b00000000001000: verify_y = i_rs1 | operand_b;  // OR
            14'b00000000010000: verify_y = i_rs1 ^ operand_b;  // XOR
            14'b00000000100000: verify_y = i_rs1 << (operand_b[4:0]);  // SLL
            14'b00000001000000: verify_y = i_rs1 >> (operand_b[4:0]);  // SRL
            14'b00000010000000: verify_y = $signed(i_rs1) >>> (operand_b[4:0]);  // SRA
            14'b00000100000000:
            verify_y = ($signed(i_rs1) < $signed(operand_b)) ? 32'h1 : 32'h0;  // SLT
            14'b00001000000000: verify_y = (i_rs1 < operand_b) ? 32'h1 : 32'h0;  // SLTU
            14'b00010000000000: verify_y = (i_rs1 == operand_b) ? 32'h1 : 32'h0;  // EQ
            14'b00100000000000: verify_y = (i_rs1 != operand_b) ? 32'h1 : 32'h0;  // NEQ
            14'b01000000000000:
            verify_y = ($signed(i_rs1) >= $signed(operand_b)) ? 32'h1 : 32'h0;  // GE
            14'b10000000000000: verify_y = (i_rs1 >= operand_b) ? 32'h1 : 32'h0;  // GEU
            default: verify_y = 0;
        endcase
        return verify_y;
    endfunction

    //--------------------------------------------------------------------------
    // Function: do_copy
    // Implements UVM copy functionality
    //--------------------------------------------------------------------------
    function void do_copy(uvm_object rhs);
        transaction rhs_;
        if (!$cast(rhs_, rhs)) begin
            `uvm_fatal("COPY_ERROR", "Cannot cast rhs to transaction")
        end
        super.do_copy(rhs);
        // Copy input fields
        this.i_alu            = rhs_.i_alu;
        this.i_rs1            = rhs_.i_rs1;
        this.i_rs2            = rhs_.i_rs2;
        this.i_imm            = rhs_.i_imm;
        this.i_opcode         = rhs_.i_opcode;
        this.i_ce             = rhs_.i_ce;
        this.i_rs1_addr       = rhs_.i_rs1_addr;
        this.i_funct3         = rhs_.i_funct3;
        this.i_pc             = rhs_.i_pc;
        this.i_rd_addr        = rhs_.i_rd_addr;
        this.i_stall          = rhs_.i_stall;
        this.i_force_stall    = rhs_.i_force_stall;
        this.i_flush          = rhs_.i_flush;
        this.i_rst_n          = rhs_.i_rst_n;
        this.i_exception      = rhs_.i_exception;
        // Copy output fields
        this.o_rs1_addr       = rhs_.o_rs1_addr;
        this.o_rs1            = rhs_.o_rs1;
        this.o_rs2            = rhs_.o_rs2;
        this.o_imm            = rhs_.o_imm;
        this.o_funct3         = rhs_.o_funct3;
        this.o_opcode         = rhs_.o_opcode;
        this.o_exception      = rhs_.o_exception;
        this.o_y              = rhs_.o_y;
        this.o_pc             = rhs_.o_pc;
        this.o_next_pc        = rhs_.o_next_pc;
        this.o_change_pc      = rhs_.o_change_pc;
        this.o_wr_rd          = rhs_.o_wr_rd;
        this.o_rd_addr        = rhs_.o_rd_addr;
        this.o_rd             = rhs_.o_rd;
        this.o_rd_valid       = rhs_.o_rd_valid;
        this.o_stall_from_alu = rhs_.o_stall_from_alu;
        this.o_ce             = rhs_.o_ce;
        this.o_stall          = rhs_.o_stall;
        this.o_flush          = rhs_.o_flush;
        // Copy expected output
        this.verify_y         = rhs_.verify_y;
    endfunction

    //--------------------------------------------------------------------------
    // Function: do_compare
    // Implements comparison for UVM (useful in scoreboards)
    //--------------------------------------------------------------------------
    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        transaction rhs_;
        if (!$cast(rhs_, rhs)) return 0;
        return super.do_compare(
            rhs, comparer
        ) && (this.i_alu == rhs_.i_alu) && (this.i_rs1 == rhs_.i_rs1) && (this.i_rs2 == rhs_.i_rs2)
            && (this.i_imm == rhs_.i_imm) && (this.i_opcode == rhs_.i_opcode) &&
            (this.i_ce == rhs_.i_ce) && (this.verify_y == rhs_.verify_y);
    endfunction

    //--------------------------------------------------------------------------
    // Function: convert2string
    // For debugging and logging (enhanced)
    //--------------------------------------------------------------------------
    function string convert2string();
        return $sformatf(
            "i_alu=%b, i_opcode=%b, i_rs1=%h, i_rs2=%h, i_imm=%h, i_ce=%b, i_rst_n=%b, verify_y=%h",
            i_alu,
            i_opcode,
            i_rs1,
            i_rs2,
            i_imm,
            i_ce,
            i_rst_n,
            verify_y
        );
    endfunction
endclass

`endif
