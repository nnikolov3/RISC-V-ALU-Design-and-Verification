// ----------------------------------------------------------------------------
// Class: transaction
// ECE 593: Milestone 4 - RV32I ALU Transaction
// Team 3
// Description:
//   This UVM transaction class defines the structure for stimulus generation
//   and monitoring in the RISC-V 32I Arithmetic Logic Unit (ALU) verification
//   environment. Extending uvm_sequence_item, it supports UVM sequencers and
//   drivers with randomized inputs, monitored outputs, constraints for valid
//   test cases, and methods for manual configuration, expected result
//   computation, and debugging.
// Updated: Feb 26, 2025
// ----------------------------------------------------------------------------

`ifndef TRANSACTION_SV
`define TRANSACTION_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "rv32i_alu_header.sv"

class transaction extends uvm_sequence_item;
    // ------------------------------------------------------------------------
    // Registration: Factory Registration
    // Description:
    //   Registers the transaction class with the UVM factory for dynamic creation.
    // ------------------------------------------------------------------------
    `uvm_object_utils(transaction)

    //--------------------------------------------------------------------------
    // Randomized Input Signals (for stimulus generation)
    // Description:
    //   Randomized fields representing ALU input signals, designed to generate
    //   diverse test stimuli compatible with the RISC-V 32I ALU interface.
    //--------------------------------------------------------------------------
    rand bit [                13:0] i_alu;  // 14-bit one-hot ALU control signal
    rand bit [                31:0] i_rs1;  // 32-bit first operand
    rand bit [                31:0] i_rs2;  // 32-bit second operand
    rand bit [                31:0] i_imm;  // 32-bit immediate value
    rand bit [   `OPCODE_WIDTH-1:0] i_opcode;  // 7-bit opcode (parameterized width)
    rand bit                        i_ce;  // Clock enable signal
    rand bit [                 4:0] i_rs1_addr;  // 5-bit source register 1 address
    rand bit [                 2:0] i_funct3;  // 3-bit function field
    rand bit [                31:0] i_pc;  // 32-bit program counter
    rand bit [                 4:0] i_rd_addr;  // 5-bit destination register address
    rand bit                        i_stall;  // Pipeline stall signal
    rand bit                        i_force_stall;  // Forced stall signal (e.g., debug)
    rand bit                        i_flush;  // Pipeline flush signal
    rand bit                        i_rst_n;  // Active-low reset signal

    // Non-randomized field for external control
    bit      [`EXCEPTION_WIDTH-1:0] i_exception;  // Exception signal (parameterized width)

    //--------------------------------------------------------------------------
    // Output Signals (for monitoring and verification)
    // Description:
    //   Non-randomized fields capturing ALU outputs, sampled by the monitor for
    //   verification purposes; not driven to the DUT.
    //--------------------------------------------------------------------------
    bit      [                 4:0] o_rs1_addr;  // 5-bit output source register 1 address
    bit      [                31:0] o_rs1;  // 32-bit output first operand
    bit      [                31:0] o_rs2;  // 32-bit output second operand
    bit      [                31:0] o_imm;  // 32-bit output immediate value
    bit      [                 2:0] o_funct3;  // 3-bit output function field
    bit      [   `OPCODE_WIDTH-1:0] o_opcode;  // Output opcode (parameterized width)
    bit      [`EXCEPTION_WIDTH-1:0] o_exception;  // Output exception signal
    bit      [                31:0] o_y;  // 32-bit ALU result
    bit      [                31:0] o_pc;  // 32-bit output program counter
    bit      [                31:0] o_next_pc;  // 32-bit output next program counter
    bit                             o_change_pc;  // Flag for PC change (e.g., branch/jump)
    bit                             o_wr_rd;  // Write enable for destination register
    bit      [                 4:0] o_rd_addr;  // 5-bit output destination register address
    bit      [                31:0] o_rd;  // 32-bit output destination register data
    bit                             o_rd_valid;  // Validity flag for destination data
    bit                             o_stall_from_alu;  // Stall signal from ALU
    bit                             o_ce;  // Output clock enable
    bit                             o_stall;  // Combined stall signal output
    bit                             o_flush;  // Output flush signal

    // Expected output for verification
    bit      [                31:0] verify_y;  // 32-bit expected ALU result

    //--------------------------------------------------------------------------
    // Constraints
    // Description:
    //   Constraints ensuring valid stimulus generation, including one-hot ALU
    //   control, RISC-V opcodes, and biased distributions for control signals.
    //--------------------------------------------------------------------------
    // Constraint for ALU control: ensures one-hot encoding and valid operations
    constraint alu_ctrl_c {
        $onehot(i_alu);  // Only one ALU operation active
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

    // Constraint for opcode: restricts to valid RISC-V 32I instruction types
    constraint opcode_c {
        i_opcode inside {7'b0110011,  // R-type
        7'b0010011,  // I-type
        7'b0000011,  // Load
        7'b0100011,  // Store
        7'b1100011,  // Branch
        7'b1101111,  // JAL
        7'b1100111,  // JALR
        7'b0110111,  // LUI
        7'b0010111,  // AUIPC
        7'b1110011,  // System
        7'b0001111};  // Fence
    }

    // Constraint for clock enable: biases towards enabled state
    constraint ce_c {
        i_ce dist {
            1 := 90,
            0 := 10
        };  // 90% chance of clock enable being active
    }

    // Constraint for reset: biases towards no reset
    constraint reset_c {
        i_rst_n dist {
            1 := 95,
            0 := 5
        };  // 95% chance of reset being inactive
    }

    // Constraint for operand ranges: full 32-bit unsigned range
    constraint operand_ranges {
        i_rs1 inside {[0 : (1 << 32) - 1]};
        i_rs2 inside {[0 : (1 << 32) - 1]};
        i_imm inside {[0 : (1 << 32) - 1]};
    }

    // Special constraints (togglable externally for specific test scenarios)
    constraint zero_operand_c {
        (i_rs1 == 0) || (i_rs2 == 0) || (i_imm == 0);  // At least one operand zero
    }
    constraint max_value_c {
        (i_rs1 == 32'hFFFFFFFF) || (i_rs2 == 32'hFFFFFFFF) ||
            (i_imm == 32'hFFFFFFFF);  // At least one max value
    }
    constraint sign_boundary_c {
        (i_rs1 inside {32'h7FFFFFFF, 32'h80000000}) ||
            (i_rs2 inside {32'h7FFFFFFF, 32'h80000000});  // Sign edges
    }

    //--------------------------------------------------------------------------
    // Constructor: new
    // Description:
    //   Initializes the transaction with a name and sets default values for
    //   non-randomized fields.
    // Arguments:
    //   - name: String identifier (default: "transaction")
    //--------------------------------------------------------------------------
    function new(string name = "transaction");
        super.new(name);
        i_exception = 0;  // Default exception to zero
    endfunction

    //--------------------------------------------------------------------------
    // Function: set_values
    // Description:
    //   Sets specific values for key fields in predefined test scenarios,
    //   ensuring one-hot ALU control and defaulting reset to active.
    // Arguments:
    //   - alu_idx: ALU operation index (0-13)
    //   - opcode: 7-bit opcode
    //   - rs1: First operand (32-bit)
    //   - rs2: Second operand (32-bit)
    //   - imm: Immediate value (32-bit)
    //   - ce: Clock enable value
    //--------------------------------------------------------------------------
    function void set_values(int alu_idx, bit [`OPCODE_WIDTH-1:0] opcode, bit [31:0] rs1,
                             bit [31:0] rs2, bit [31:0] imm, bit ce);
        i_alu          = 0;  // Reset ALU control
        i_alu[alu_idx] = 1;  // Enable specified ALU operation
        i_opcode       = opcode;  // Set opcode
        i_rs1          = rs1;  // Set first operand
        i_rs2          = rs2;  // Set second operand
        i_imm          = imm;  // Set immediate
        i_ce           = ce;  // Set clock enable
        i_rst_n        = 1;  // Default to no reset
    endfunction

    //--------------------------------------------------------------------------
    // Function: alu_operation
    // Description:
    //   Calculates the expected ALU output based on input fields, selecting
    //   between rs2 and imm based on opcode, and updates verify_y.
    // Returns:
    //   32-bit expected result
    //--------------------------------------------------------------------------
    function bit [31:0] alu_operation();
        bit [31:0] operand_b = (i_opcode == 7'b0010011) ? i_imm : i_rs2;  // I-type uses imm
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
            default: verify_y = 0;  // Default to zero
        endcase
        return verify_y;
    endfunction

    //--------------------------------------------------------------------------
    // Function: do_copy
    // Description:
    //   Copies all fields from another transaction object, supporting UVM’s
    //   deep copy mechanism.
    // Arguments:
    //   - rhs: Source transaction object to copy from
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
    // Description:
    //   Compares key fields with another transaction object for verification,
    //   used in UVM scoreboards.
    // Arguments:
    //   - rhs: Object to compare against
    //   - comparer: UVM comparer for customization
    // Returns:
    //   1 if comparison passes, 0 if it fails
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
    // Description:
    //   Generates a string representation of key fields for logging and debugging.
    // Returns:
    //   Formatted string of transaction data
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
