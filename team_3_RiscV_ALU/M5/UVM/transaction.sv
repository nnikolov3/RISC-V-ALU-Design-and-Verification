// ----------------------------------------------------------------------------
// Class: transaction
// Description:
//   This class defines the transaction object for the RV32I ALU verification
//   environment. It extends uvm_sequence_item to generate stimulus via UVM
//   sequencers and drivers, and includes fields for input signals, output signals,
//   and expected results. Constraints ensure valid ALU operations and RISC-V
//   instruction types, with additional controls for randomization scenarios.
// File: transaction.sv
// Updated: Mar 08, 2025
// ----------------------------------------------------------------------------
// Guard against multiple inclusions of this file in the compilation process.
// If TRANSACTION_SV is already defined elsewhere, this file won’t be reprocessed.
`ifndef TRANSACTION_SV
`define TRANSACTION_SV 

// Include UVM macro definitions for utility functions and reporting mechanisms.
`include "uvm_macros.svh"

// Import the UVM package to access its classes, methods, and infrastructure.
import uvm_pkg::*;

// Include ALU-specific constants and types defined in the header file.
`include "rv32i_alu_header.sv"

// Define the transaction class, inheriting from uvm_sequence_item for UVM compatibility.
class transaction extends uvm_sequence_item;
  // Register the class with UVM’s factory, enabling type registration for dynamic
  // instantiation and overrides. This allows the factory to create or replace this
  // object during simulation setup, enhancing test flexibility.
  `uvm_object_utils(transaction)

  // Unique transaction identifier, incremented post-randomization or manually set.
  int tx_id = 0;

  //--------------------------------------------------------------------------
  // Randomized Input Signals (for stimulus generation)
  //--------------------------------------------------------------------------
  // Input fields are randomized unless explicitly set by predefined scenarios.
  rand bit [13:0] i_alu;  // 14-bit one-hot encoded ALU operation selector.
  rand bit [31:0] i_rs1;  // 32-bit first operand (source register 1 value).
  rand bit [31:0] i_rs2;  // 32-bit second operand (source register 2 value).
  rand bit [31:0] i_imm;  // 32-bit immediate value from instruction.
  rand
  bit [`OPCODE_WIDTH-1:0]
  i_opcode;  // Opcode, width defined in rv32i_alu_header.sv (default 7-bit).
  rand bit i_ce;  // Clock enable signal (1 = enabled, 0 = disabled).
  rand bit [4:0] i_rs1_addr;  // 5-bit address for source register 1 (0-31).
  rand bit [2:0] i_funct3;  // 3-bit function field from instruction.
  rand bit [31:0] i_pc;  // 32-bit program counter value.
  rand bit [4:0] i_rd_addr;  // 5-bit destination register address (0-31).
  rand bit rst_n;  // Active-low reset signal (1 = normal, 0 = reset).

  // Non-randomized input fields (set externally or in specific cases).
  bit i_stall;  // Pipeline stall signal (1 = stall).
  bit i_force_stall;  // Debug-specific forced stall signal (1 = stall).
  bit i_flush;  // Pipeline flush signal (1 = flush).
  bit [`EXCEPTION_WIDTH-1:0]
      i_exception;  // Exception status input, width from header (default 2-bit).

  //--------------------------------------------------------------------------
  // Output Signals (for monitoring and verification, not driven to DUT)
  //--------------------------------------------------------------------------
  // Output fields are populated by the monitor or DUT for verification.
  bit [4:0] o_rs1_addr;  // 5-bit bypassed source register 1 address.
  bit [31:0] o_rs1;  // 32-bit bypassed source register 1 value.
  bit [31:0] o_rs2;  // 32-bit bypassed source register 2 value.
  bit [11:0] o_imm;  // 12-bit bypassed immediate value (subset of i_imm).
  bit [2:0] o_funct3;  // 3-bit bypassed function field.
  bit [`OPCODE_WIDTH-1:0] o_opcode;  // Bypassed opcode, width from header (default 7-bit).
  bit [`EXCEPTION_WIDTH-1:0] o_exception;  // Propagated exception status, width from header.
  bit [31:0] o_y;  // 32-bit ALU computation result.
  bit [31:0] o_pc;  // 32-bit current program counter output.
  bit [31:0] o_next_pc;  // 32-bit next program counter value.
  bit o_change_pc;  // Flag indicating a PC change request (1 = change).
  bit o_wr_rd;  // Write enable for destination register (1 = write).
  bit [4:0] o_rd_addr;  // 5-bit destination register address.
  bit [31:0] o_rd;  // 32-bit data for destination register.
  bit o_rd_valid;  // Validity flag for destination register data (1 = valid).
  bit o_stall_from_alu;  // Stall request from ALU (1 = stall).
  bit o_ce;  // Propagated clock enable signal (1 = enabled).
  bit o_stall;  // Combined stall signal output (1 = stall).
  bit o_flush;  // Propagated flush signal output (1 = flush).

  // Expected output for verification, computed by alu_operation().
  bit [31:0] verify_y;  // 32-bit expected ALU result.

  //--------------------------------------------------------------------------
  // Constraints
  //--------------------------------------------------------------------------
  // Ensure i_alu is one-hot and restricted to valid ALU operations (14 operations).
  constraint alu_ctrl_c {
    $onehot(i_alu);  // Enforces one-hot encoding (exactly one bit set).
    i_alu inside {(1 << `ADD),  // ADD
    (1 << `SUB),  // SUB
    (1 << `SLT),  // SLT
    (1 << `SLTU),  // SLTU
    (1 << `XOR),  // XOR
    (1 << `OR),  // OR
    (1 << `AND),  // AND
    (1 << `SLL),  // SLL
    (1 << `SRL),  // SRL
    (1 << `SRA),  // SRA
    (1 << `EQ),  // EQ
    (1 << `NEQ),  // NEQ
    (1 << `GE),  // GE
    (1 << `GEU)  // GEU
    };
  }

  // Constraint for opcode: valid RISC-V instruction types.
  // Original constraint used 11-bit one-hot; corrected to match 7-bit width from header.
  constraint opcode_c {
    i_opcode inside {`RTYPE_BITS,  // R-type instructions
    `ITYPE_BITS/*,  // I-type instructions
    `LOAD_BITS,  // Load instructions
    `STORE_BITS,  // Store instructions
    `BRANCH_BITS,  // Branch instructions
    `JAL_BITS,  // Jump and link
    `JALR_BITS,  // Jump and link register
    `LUI_BITS,  // Load upper immediate
    `AUIPC_BITS,  // Add upper immediate to PC
    `SYSTEM_BITS,  // System instructions
    `FENCE_BITS*/  // Fence instructions
    };
  }

  // Constraint for small operand values (0 to 0xFFFF).
  constraint small_value_c {
    i_rs1 inside {[0 : 32'hFFFF]};
    i_rs2 inside {[0 : 32'hFFFF]};
    i_imm inside {[0 : 32'hFFFF]};
  }

  // Constraint for large operand values (0xFFFF0000 to 0xFFFFFFFF).
  constraint large_value_c {
    i_rs1 inside {[32'hFFFF0000 : 32'hFFFFFFFF]};
    i_rs2 inside {[32'hFFFF0000 : 32'hFFFFFFFF]};
    i_imm inside {[32'hFFFF0000 : 32'hFFFFFFFF]};
  }

  // Constraint for opposite signs between operands.
  constraint opposite_signs_c {
    (i_rs1[31] == 0 && i_rs2[31] == 1) || (i_rs1[31] == 1 && i_rs2[31] == 0);
  }

  // Constraint for extreme shift amounts (0, 1, 31) when ALU operation is a shift.
  constraint shift_extreme_c {
    (i_alu inside {(1 << `SLL), (1 << `SRL), (1 << `SRA)}) ->
    (i_rs2 inside {0, 1, 31} && i_imm inside {0, 1, 31});
  }

  // Constraint for equal operands in comparison operations.
  constraint equal_values_c {
    (i_alu inside {(1 << `SLT), (1 << `SLTU), (1 << `EQ), (1 << `NEQ), (1 << `GE), (1 << `GEU)}) ->
    i_rs1 == i_rs2;
  }

  // Constraint for clock enable: 100% enabled by default (adjusted from 90%).
  constraint ce_c {
    i_ce dist {
      1 := 100,  // Always enabled unless overridden.
      0 := 0
    };
  }

  // Constraint for reset: 95% deasserted (1), 5% asserted (0).
  constraint reset_c {
    rst_n dist {
      1 := 95,  // Mostly deasserted for normal operation.
      0 := 5  // Occasionally asserted to test reset behavior.
    };
  }

  // Constraint for operand ranges: Full 32-bit range.
  constraint operand_ranges {
    i_rs1 inside {[0 : (1 << 32) - 1]};
    i_rs2 inside {[0 : (1 << 32) - 1]};
    i_imm inside {[0 : (1 << 32) - 1]};
  }

  // Special constraints (disabled by default, activated externally).
  constraint zero_operand_c {
    (i_rs1 == 0) || (i_rs2 == 0) || (i_imm == 0);  // At least one operand is zero.
  }
  constraint max_value_c {
    (i_rs1 == 32'hFFFFFFFF) || (i_rs2 == 32'hFFFFFFFF) ||
        (i_imm == 32'hFFFFFFFF);  // At least one operand is max value.
  }
  constraint sign_boundary_c {
    (i_rs1 inside {32'h7FFFFFFF, 32'h80000000}) ||
        (i_rs2 inside {32'h7FFFFFFF, 32'h80000000});  // Operands near sign boundary.
  }

  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  function new(string name = "transaction");
    super.new(name);  // Call the parent class (uvm_sequence_item) constructor.
    i_exception = 0;  // Initialize exception field to 0 (no exception).
  endfunction

  //--------------------------------------------------------------------------
  // Function: set_values
  // Description:
  //   Manually sets transaction fields for predefined test scenarios, overriding
  //   randomization. Increments tx_id for tracking.
  // Parameters:
  //   - alu_val: One-hot ALU operation (14-bit).
  //   - opcode: Opcode value (width from header, default 7-bit).
  //   - rs1, rs2, imm: 32-bit operand values.
  //   - ce: Clock enable (1-bit).
  //   - rst: Reset signal (1-bit).
  //--------------------------------------------------------------------------
  function void set_values(int alu_val, bit [`OPCODE_WIDTH-1:0] opcode, bit [31:0] rs1,
                           bit [31:0] rs2, bit [31:0] imm, bit ce, bit rst);
    i_alu    = alu_val;  // Set ALU operation.
    i_opcode = opcode;  // Set opcode.
    i_rs1    = rs1;  // Set first operand.
    i_rs2    = rs2;  // Set second operand.
    i_imm    = imm;  // Set immediate value.
    i_ce     = ce;  // Set clock enable.
    rst_n    = rst;  // Set reset signal.
    tx_id    = tx_id + 1;  // Increment transaction ID.
  endfunction

  //--------------------------------------------------------------------------
  // Function: alu_operation
  // Description:
  //   Computes the expected ALU result (verify_y) based on input fields.
  //   Uses i_imm for I-type instructions and i_rs2 otherwise.
  // Returns:
  //   - 32-bit expected result.
  //--------------------------------------------------------------------------
  function bit [31:0] alu_operation();
    bit [31:0] operand_b = (i_opcode == `ITYPE_BITS) ? i_imm :
        i_rs2;  // Select operand B based on opcode.
    case (i_alu)
      (1 << `ADD): verify_y = i_rs1 + operand_b;  // Addition.
      (1 << `SUB): verify_y = i_rs1 - operand_b;  // Subtraction.
      (1 << `AND): verify_y = i_rs1 & operand_b;  // Bitwise AND.
      (1 << `OR): verify_y = i_rs1 | operand_b;  // Bitwise OR.
      (1 << `XOR): verify_y = i_rs1 ^ operand_b;  // Bitwise XOR.
      (1 << `SLL): verify_y = i_rs1 << (operand_b[4:0]);  // Shift left logical (5-bit shift).
      (1 << `SRL): verify_y = i_rs1 >> (operand_b[4:0]);  // Shift right logical (5-bit shift).
      (1 << `SRA):
      verify_y = $signed(i_rs1) >>> (operand_b[4:0]);  // Shift right arithmetic (5-bit shift).
      (1 << `SLT):
      verify_y = ($signed(i_rs1) < $signed(operand_b)) ? 32'h1 : 32'h0;  // Signed less than.
      (1 << `SLTU): verify_y = (i_rs1 < operand_b) ? 32'h1 : 32'h0;  // Unsigned less than.
      (1 << `EQ): verify_y = (i_rs1 == operand_b) ? 32'h1 : 32'h0;  // Equality.
      (1 << `NEQ): verify_y = (i_rs1 != operand_b) ? 32'h1 : 32'h0;  // Inequality.
      (1 << `GE):
      verify_y = ($signed(i_rs1) >= $signed(operand_b)) ? 32'h1 :
          32'h0;  // Signed greater or equal.
      (1 << `GEU): verify_y = (i_rs1 >= operand_b) ? 32'h1 : 32'h0;  // Unsigned greater or equal.
      default: verify_y = 32'h0;  // Default to 0 for invalid operations.
    endcase
    return verify_y;
  endfunction

  //--------------------------------------------------------------------------
  // Function: do_copy
  // Description:
  //   Implements UVM copy functionality to duplicate the transaction object.
  //   Copies all input, output, and expected fields.
  // Parameters:
  //   - rhs: The source object to copy from.
  //--------------------------------------------------------------------------
  function void do_copy(uvm_object rhs);
    transaction rhs_;
    if (!$cast(rhs_, rhs)) begin
      `uvm_fatal("COPY_ERROR", "Cannot cast rhs to transaction type")
    end
    super.do_copy(rhs);  // Call parent class copy method.
    // Copy input fields.
    i_alu            = rhs_.i_alu;
    i_rs1            = rhs_.i_rs1;
    i_rs2            = rhs_.i_rs2;
    i_imm            = rhs_.i_imm;
    i_opcode         = rhs_.i_opcode;
    i_ce             = rhs_.i_ce;
    i_rs1_addr       = rhs_.i_rs1_addr;
    i_funct3         = rhs_.i_funct3;
    i_pc             = rhs_.i_pc;
    i_rd_addr        = rhs_.i_rd_addr;
    i_stall          = rhs_.i_stall;
    i_force_stall    = rhs_.i_force_stall;
    i_flush          = rhs_.i_flush;
    rst_n            = rhs_.rst_n;
    i_exception      = rhs_.i_exception;
    tx_id            = rhs_.tx_id;
    // Copy output fields.
    o_rs1_addr       = rhs_.o_rs1_addr;
    o_rs1            = rhs_.o_rs1;
    o_rs2            = rhs_.o_rs2;
    o_imm            = rhs_.o_imm;
    o_funct3         = rhs_.o_funct3;
    o_opcode         = rhs_.o_opcode;
    o_exception      = rhs_.o_exception;
    o_y              = rhs_.o_y;
    o_pc             = rhs_.o_pc;
    o_next_pc        = rhs_.o_next_pc;
    o_change_pc      = rhs_.o_change_pc;
    o_wr_rd          = rhs_.o_wr_rd;
    o_rd_addr        = rhs_.o_rd_addr;
    o_rd             = rhs_.o_rd;
    o_rd_valid       = rhs_.o_rd_valid;
    o_stall_from_alu = rhs_.o_stall_from_alu;
    o_ce             = rhs_.o_ce;
    o_stall          = rhs_.o_stall;
    o_flush          = rhs_.o_flush;
    // Copy expected output.
    verify_y         = rhs_.verify_y;
  endfunction

  //--------------------------------------------------------------------------
  // Function: do_compare
  // Description:
  //   Implements UVM comparison functionality for scoreboard verification.
  //   Compares key fields (inputs and expected output) between two transactions.
  // Parameters:
  //   - rhs: The object to compare against.
  //   - comparer: UVM comparer object for customization (unused here).
  // Returns:
  //   - 1 if equal, 0 if not.
  //--------------------------------------------------------------------------
  function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    transaction rhs_;
    if (!$cast(rhs_, rhs)) return 0;  // Fail if casting to transaction type fails.
    return super.do_compare(
        rhs, comparer
    ) && (i_alu == rhs_.i_alu) && (i_rs1 == rhs_.i_rs1) && (i_rs2 == rhs_.i_rs2) &&
        (i_imm == rhs_.i_imm) && (i_opcode == rhs_.i_opcode) && (i_ce == rhs_.i_ce) &&
        (verify_y == rhs_.verify_y);
  endfunction

  //--------------------------------------------------------------------------
  // Function: convert2string
  // Description:
  //   Converts the transaction to a string for debugging and logging purposes.
  // Returns:
  //   - Formatted string with key fields.
  //--------------------------------------------------------------------------
  function string convert2string();
    return $sformatf(
        "tx_id=%0d, i_alu=%b, i_opcode=%b, i_rs1=%h, i_rs2=%h, i_imm=%h, i_ce=%b, rst_n=%b, verify_y=%h"
            ,
        tx_id,
        i_alu,
        i_opcode,
        i_rs1,
        i_rs2,
        i_imm,
        i_ce,
        rst_n,
        verify_y
    );
  endfunction

  //--------------------------------------------------------------------------
  // Function: post_randomize
  // Description:
  //   Called after randomization to increment the transaction ID.
  //--------------------------------------------------------------------------
  function void post_randomize();
    tx_id = tx_id + 1;  // Increment tx_id for each randomized transaction.
  endfunction

endclass

// End the inclusion guard, ensuring this file is processed only once.
`endif
