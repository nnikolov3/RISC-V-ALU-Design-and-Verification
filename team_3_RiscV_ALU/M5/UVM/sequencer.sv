// ----------------------------------------------------------------------------
// Class: alu_sequence
// Description:
//   This UVM sequence generates transactions to stimulate an Arithmetic Logic
//   Unit (ALU) in a RISC-V 32I processor verification environment. It includes
//   predefined scenarios targeting arithmetic and logical operations, random
//   transactions with configurable constraints, and a clock enable deactivation
//   test. The sequence drives the ALU through a UVM sequencer to verify its
//   functionality across various operation types and pipeline conditions.
// Updated: Feb 26, 2025
// ----------------------------------------------------------------------------

`include "uvm_macros.svh"
import uvm_pkg::*;

// Include dependent files
`include "rv32i_alu_header.sv"  // Defines ALU operations, opcodes, and widths
`include "transaction.sv"  // Assumes transaction class definition

//------------------------------------------------------------------------------
// Class: alu_sequence
// Extends uvm_sequence to generate ALU test transactions
//------------------------------------------------------------------------------
class alu_sequence extends uvm_sequence #(transaction);
  `uvm_object_utils(alu_sequence)
  integer log_file;
  // Configurable number of random transactions
  int     num_transactions = 15000;

  // Constructor
  function new(string name = "alu_sequence");
    super.new(name);
  endfunction

  // Main sequence body: orchestrates the test sequence
  virtual task body();
    // Retrieve num_transactions from config DB, default to 1000 if unset
    if (!uvm_config_db#(int)::get(null, get_full_name(), "num_transactions", num_transactions))
      `uvm_info("CONFIG", "Using default num_transactions = 1000", UVM_HIGH)

    generate_predefined_scenarios();  // Run predefined test cases
    generate_random_scenarios();  // Generate random transactions
    // deactivate_ce();  // Test clock enable deactivation
  endtask

  // Generate predefined test scenarios for ALU operations
  virtual task generate_predefined_scenarios();

    test_arithmetic_scenarios();  // Test arithmetic operations (ADD, SUB)
    test_logical_scenarios();  // Test logical operations (AND, OR, XOR)
    test_reset_scenarios();
    test_shift_scenarios();
    test_comparison_scenarios();
  endtask

  // Test ALU behavior under various reset conditions
  virtual task test_reset_scenarios();
    transaction trans;

    // Scenario 0: Reset active, ADD operation (baseline)
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`ADD_BITS, `RTYPE_BITS, 32'h7FFFFFFF, 32'h00000001, 32'h0, 1'b1, 0);
    finish_item(trans);
    print_scenario("Reset: Active with ADD", trans);

    // Scenario 1: Reset deasserted, normal ADD operation (post-reset recovery)
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`ADD_BITS, `RTYPE_BITS, 32'h00000001, 32'h00000002, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("Reset: Deasserted with ADD", trans);

    // Scenario 2: Reset active during SUB operation
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SUB_BITS, `RTYPE_BITS, 32'h80000000, 32'h00000001, 32'h0, 1'b1, 0);
    finish_item(trans);
    print_scenario("Reset: Active with SUB", trans);

    // Scenario 3: Reset active with logical operation (AND)
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`AND_BITS, `RTYPE_BITS, 32'hAAAAAAAA, 32'h55555555, 32'h0, 1'b1, 0);
    finish_item(trans);
    print_scenario("Reset: Active with AND", trans);

    // Scenario 4: Reset active with shift operation (SLL)
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLL_BITS, `RTYPE_BITS, 32'h00000001, 32'h0000001F, 32'h0, 1'b1, 0);
    finish_item(trans);
    print_scenario("Reset: Active with SLL", trans);

    // Scenario 5: Reset active with comparison (SLT)
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLT_BITS, `RTYPE_BITS, 32'h80000000, 32'h00000001, 32'h0, 1'b1, 0);
    finish_item(trans);
    print_scenario("Reset: Active with SLT", trans);

    // Scenario 6: Reset active with CE disabled
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`ADD_BITS, `RTYPE_BITS, 32'h00000100, 32'h00000200, 32'h0, 1'b0, 0);
    finish_item(trans);
    print_scenario("Reset: Active with CE Disabled", trans);

    // Scenario 7: Reset active with stall asserted
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SUB_BITS, `RTYPE_BITS, 32'h00001000, 32'h00000500, 32'h0, 1'b1, 0);
    trans.i_stall = 1;
    finish_item(trans);
    print_scenario("Reset: Active with Stall", trans);

    // Scenario 8: Reset active with flush asserted
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`XOR_BITS, `RTYPE_BITS, 32'hAAAAAAAA, 32'h55555555, 32'h0, 1'b1, 0);
    trans.i_flush = 1;
    finish_item(trans);
    print_scenario("Reset: Active with Flush", trans);

    // Scenario 9: Transition from reset active to deasserted (back-to-back)
    // First transaction: Reset active
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`ADD_BITS, `RTYPE_BITS, 32'hFFFFFFFF, 32'h00000001, 32'h0, 1'b1, 0);
    finish_item(trans);
    print_scenario("Reset: Transition Active", trans);

    // Second transaction: Reset deasserted, same operation
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`ADD_BITS, `RTYPE_BITS, 32'hFFFFFFFF, 32'h00000001, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("Reset: Transition Deasserted", trans);

    // Scenario 10: Reset active with I_TYPE instruction
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`ADD_BITS, `ITYPE_BITS, 32'h000000FF, 32'h00000000, 32'h00000002, 1'b1, 0);
    finish_item(trans);
    print_scenario("Reset: Active with I_TYPE ADD", trans);
  endtask


  // Test arithmetic operations (ADD, SUB) with extensive edge cases
  virtual task test_arithmetic_scenarios();
    transaction trans;

    // --- ADD Operations ---
    // Scenario 1: ADD - Positive overflow
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`ADD_BITS, `RTYPE_BITS, 32'h7FFFFFFF, 32'h00000001, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("ADD: Positive Overflow (7FFFFFFF + 1)", trans);

    // Scenario 2: ADD - Maximum values
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`ADD_BITS, `RTYPE_BITS, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("ADD: Maximum Values (FFFFFFFF + FFFFFFFF)", trans);

    // Scenario 3: ADD - Zero plus zero
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`ADD_BITS, `RTYPE_BITS, 32'h00000000, 32'h00000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("ADD: Zero Plus Zero (0 + 0)", trans);

    // Scenario 4: ADD - Negative plus positive (crossing zero)
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`ADD_BITS, `RTYPE_BITS, 32'h80000000, 32'h80000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("ADD: Negative Plus Positive (80000000 + 80000000)", trans);

    // Scenario 5: ADD - Small positive values
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`ADD_BITS, `RTYPE_BITS, 32'h00000001, 32'h00000002, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("ADD: Small Positive Values (1 + 2)", trans);

    // Scenario 6: ADD - I_TYPE with immediate
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`ADD_BITS, `ITYPE_BITS, 32'h00000100, 32'h00000000, 32'h00000200, 1'b1, 1);
    finish_item(trans);
    print_scenario("ADD: I_TYPE with Immediate (100 + 200)", trans);

    // Scenario 7: ADD - Negative overflow
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`ADD_BITS, `RTYPE_BITS, 32'h80000000, 32'h80000001, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("ADD: Negative Overflow (80000000 + 80000001)", trans);

    // Scenario 8: ADD - Positive plus negative (no overflow)
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`ADD_BITS, `RTYPE_BITS, 32'h00001000, 32'hFFFFF000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("ADD: Positive Plus Negative (1000 + FFFFF000)", trans);

    // Scenario 9: ADD - Large positive values
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`ADD_BITS, `RTYPE_BITS, 32'h40000000, 32'h3FFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("ADD: Large Positive Values (40000000 + 3FFFFFFF)", trans);

    // Scenario 10: ADD - Zero plus negative
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`ADD_BITS, `RTYPE_BITS, 32'h00000000, 32'h80000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("ADD: Zero Plus Negative (0 + 80000000)", trans);

    // Scenario 11: ADD - Negative plus negative (no overflow)
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`ADD_BITS, `RTYPE_BITS, 32'hC0000000, 32'hC0000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("ADD: Negative Plus Negative (C0000000 + C0000000)", trans);

    // Scenario 12: ADD - Positive boundary transition
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`ADD_BITS, `RTYPE_BITS, 32'h7FFFFFFE, 32'h00000002, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("ADD: Positive Boundary Transition (7FFFFFFE + 2)", trans);

    // --- SUB Operations ---
    // Scenario 13: SUB - Negative underflow
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SUB_BITS, `RTYPE_BITS, 32'h80000000, 32'h00000001, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SUB: Negative Underflow (80000000 - 1)", trans);

    // Scenario 14: SUB - Zero result
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SUB_BITS, `RTYPE_BITS, 32'h5A5A5A5A, 32'h5A5A5A5A, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SUB: Zero Result (5A5A5A5A - 5A5A5A5A)", trans);

    // Scenario 15: SUB - Positive minus negative (overflow)
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SUB_BITS, `RTYPE_BITS, 32'h7FFFFFFF, 32'h80000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SUB: Positive Minus Negative (7FFFFFFF - 80000000)", trans);

    // Scenario 16: SUB - Maximum minus zero
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SUB_BITS, `RTYPE_BITS, 32'hFFFFFFFF, 32'h00000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SUB: Maximum Minus Zero (FFFFFFFF - 0)", trans);

    // Scenario 17: SUB - Small positive difference
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SUB_BITS, `RTYPE_BITS, 32'h00000005, 32'h00000003, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SUB: Small Positive Difference (5 - 3)", trans);

    // Scenario 18: SUB - I_TYPE with immediate
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SUB_BITS, `ITYPE_BITS, 32'h00001000, 32'h00000000, 32'h00000500, 1'b1, 1);
    finish_item(trans);
    print_scenario("SUB: I_TYPE with Immediate (1000 - 500)", trans);

    // Scenario 19: SUB - Negative minus negative
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SUB_BITS, `RTYPE_BITS, 32'h80000000, 32'h80000001, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SUB: Negative Minus Negative (80000000 - 80000001)", trans);

    // Scenario 20: SUB - Zero minus positive
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SUB_BITS, `RTYPE_BITS, 32'h00000000, 32'h00000001, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SUB: Zero Minus Positive (0 - 1)", trans);

    // Scenario 21: SUB - Positive minus positive (large difference)
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SUB_BITS, `RTYPE_BITS, 32'h7FFFFFFF, 32'h00001000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SUB: Positive Minus Positive (7FFFFFFF - 1000)", trans);

    // Scenario 22: SUB - Negative minus positive (underflow)
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SUB_BITS, `RTYPE_BITS, 32'h80000000, 32'h7FFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SUB: Negative Minus Positive (80000000 - 7FFFFFFF)", trans);

    // Scenario 23: SUB - Minimum minus maximum
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SUB_BITS, `RTYPE_BITS, 32'h80000000, 32'hFFFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SUB: Minimum Minus Maximum (80000000 - FFFFFFFF)", trans);

    // Scenario 24: SUB - Positive boundary transition
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SUB_BITS, `RTYPE_BITS, 32'h00000001, 32'h00000002, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SUB: Positive Boundary Transition (1 - 2)", trans);
  endtask


  // Test logical operations (AND, OR, XOR) with exhaustive edge cases
  virtual task test_logical_scenarios();
    transaction trans;

    // --- AND Operations ---
    // Scenario 1: AND - Alternating bits
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`AND_BITS, `RTYPE_BITS, 32'hAAAAAAAA, 32'h55555555, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("AND: Alternating Bits (AAAAAAAA & 55555555)", trans);

    // Scenario 2: AND - All ones
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`AND_BITS, `RTYPE_BITS, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("AND: All Ones (FFFFFFFF & FFFFFFFF)", trans);

    // Scenario 3: AND - All zeros
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`AND_BITS, `RTYPE_BITS, 32'h00000000, 32'h00000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("AND: All Zeros (00000000 & 00000000)", trans);

    // Scenario 4: AND - Zero and ones
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`AND_BITS, `RTYPE_BITS, 32'h00000000, 32'hFFFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("AND: Zero and Ones (00000000 & FFFFFFFF)", trans);

    // Scenario 5: AND - Single bit set
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`AND_BITS, `RTYPE_BITS, 32'h00000001, 32'h00000001, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("AND: Single Bit Set (00000001 & 00000001)", trans);

    // Scenario 6: AND - I_TYPE with immediate
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`AND_BITS, `ITYPE_BITS, 32'hF0F0F0F0, 32'h00000000, 32'h0F0F0F0F, 1'b1, 1);
    finish_item(trans);
    print_scenario("AND: I_TYPE with Immediate (F0F0F0F0 & 0F0F0F0F)", trans);

    // Scenario 7: AND - Complementary patterns
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`AND_BITS, `RTYPE_BITS, 32'hFFFF0000, 32'h0000FFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("AND: Complementary Patterns (FFFF0000 & 0000FFFF)", trans);

    // Scenario 8: AND - High bits only
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`AND_BITS, `RTYPE_BITS, 32'hFF000000, 32'hFFFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("AND: High Bits Only (FF000000 & FFFFFFFF)", trans);

    // Scenario 9: AND - Low bits only
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`AND_BITS, `RTYPE_BITS, 32'h000000FF, 32'h00000FFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("AND: Low Bits Only (000000FF & 00000FFF)", trans);

    // --- OR Operations ---
    // Scenario 10: OR - Complementary patterns
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`OR_BITS, `RTYPE_BITS, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("OR: Complementary Patterns (F0F0F0F0 | 0F0F0F0F)", trans);

    // Scenario 11: OR - All zeros
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`OR_BITS, `RTYPE_BITS, 32'h00000000, 32'h00000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("OR: All Zeros (00000000 | 00000000)", trans);

    // Scenario 12: OR - Zero with ones
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`OR_BITS, `RTYPE_BITS, 32'h00000000, 32'hFFFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("OR: Zero with Ones (00000000 | FFFFFFFF)", trans);

    // Scenario 13: OR - All ones
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`OR_BITS, `RTYPE_BITS, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("OR: All Ones (FFFFFFFF | FFFFFFFF)", trans);

    // Scenario 14: OR - Single bit set
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`OR_BITS, `RTYPE_BITS, 32'h00000001, 32'h00000002, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("OR: Single Bit Set (00000001 | 00000002)", trans);

    // Scenario 15: OR - I_TYPE with immediate
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`OR_BITS, `ITYPE_BITS, 32'hAAAA0000, 32'h00000000, 32'h0000AAAA, 1'b1, 1);
    finish_item(trans);
    print_scenario("OR: I_TYPE with Immediate (AAAA0000 | 0000AAAA)", trans);

    // Scenario 16: OR - Alternating bits
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`OR_BITS, `RTYPE_BITS, 32'h55555555, 32'hAAAAAAAA, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("OR: Alternating Bits (55555555 | AAAAAAAA)", trans);

    // Scenario 17: OR - High bits only
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`OR_BITS, `RTYPE_BITS, 32'hFF000000, 32'h00FF0000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("OR: High Bits Only (FF000000 | 00FF0000)", trans);

    // Scenario 18: OR - Low bits only
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`OR_BITS, `RTYPE_BITS, 32'h000000FF, 32'h0000000F, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("OR: Low Bits Only (000000FF | 0000000F)", trans);

    // --- XOR Operations ---
    // Scenario 19: XOR - Identical values
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`XOR_BITS, `RTYPE_BITS, 32'hAAAAAAAA, 32'hAAAAAAAA, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("XOR: Identical Values (AAAAAAAA ^ AAAAAAAA)", trans);

    // Scenario 20: XOR - Complementary values
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`XOR_BITS, `RTYPE_BITS, 32'h55555555, 32'hAAAAAAAA, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("XOR: Complementary Values (55555555 ^ AAAAAAAA)", trans);

    // Scenario 21: XOR - All zeros
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`XOR_BITS, `RTYPE_BITS, 32'h00000000, 32'h00000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("XOR: All Zeros (00000000 ^ 00000000)", trans);

    // Scenario 22: XOR - Zero with ones
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`XOR_BITS, `RTYPE_BITS, 32'h00000000, 32'hFFFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("XOR: Zero with Ones (00000000 ^ FFFFFFFF)", trans);

    // Scenario 23: XOR - All ones
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`XOR_BITS, `RTYPE_BITS, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("XOR: All Ones (FFFFFFFF ^ FFFFFFFF)", trans);

    // Scenario 24: XOR - I_TYPE with immediate
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`XOR_BITS, `ITYPE_BITS, 32'hFFFF0000, 32'h00000000, 32'h0000FFFF, 1'b1, 1);
    finish_item(trans);
    print_scenario("XOR: I_TYPE with Immediate (FFFF0000 ^ 0000FFFF)", trans);

    // Scenario 25: XOR - Single bit difference
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`XOR_BITS, `RTYPE_BITS, 32'h00000001, 32'h00000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("XOR: Single Bit Difference (00000001 ^ 00000000)", trans);

    // Scenario 26: XOR - High bits only
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`XOR_BITS, `RTYPE_BITS, 32'hFF000000, 32'hF0000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("XOR: High Bits Only (FF000000 ^ F0000000)", trans);

    // Scenario 27: XOR - Low bits only
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`XOR_BITS, `RTYPE_BITS, 32'h000000FF, 32'h0000000F, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("XOR: Low Bits Only (000000FF ^ 0000000F)", trans);
  endtask

  // Test shift operations (SLL, SRL, SRA) with exhaustive edge cases
  virtual task test_shift_scenarios();
    transaction trans;

    // --- SLL Operations (Shift Left Logical) ---
    // Scenario 1: SLL - Shift by 1
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLL_BITS, `RTYPE_BITS, 32'h00000001, 32'h00000001, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLL: Shift by 1 (00000001 << 1)", trans);

    // Scenario 2: SLL - Maximum shift (31 bits)
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLL_BITS, `RTYPE_BITS, 32'h00000001, 32'h0000001F, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLL: Maximum Shift (00000001 << 31)", trans);

    // Scenario 3: SLL - Shift beyond 31 (32 bits, uses lower 5 bits)
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLL_BITS, `RTYPE_BITS, 32'hFFFFFFFF, 32'h00000020, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLL: Shift Beyond 31 (FFFFFFFF << 32)", trans);

    // Scenario 4: SLL - Zero shift amount
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLL_BITS, `RTYPE_BITS, 32'hAAAA5555, 32'h00000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLL: Zero Shift Amount (AAAA5555 << 0)", trans);

    // Scenario 5: SLL - I_TYPE with immediate shift
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLL_BITS, `ITYPE_BITS, 32'h000000FF, 32'h00000000, 32'h00000003, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLL: I_TYPE with Immediate (000000FF << 3)", trans);

    // Scenario 6: SLL - Negative value shifted
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLL_BITS, `RTYPE_BITS, 32'h80000000, 32'h00000001, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLL: Negative Value Shifted (80000000 << 1)", trans);

    // Scenario 7: SLL - All ones shifted
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLL_BITS, `RTYPE_BITS, 32'hFFFFFFFF, 32'h00000004, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLL: All Ones Shifted (FFFFFFFF << 4)", trans);

    // Scenario 8: SLL - Small value, large shift
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLL_BITS, `RTYPE_BITS, 32'h0000000F, 32'h0000001E, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLL: Small Value Large Shift (0000000F << 30)", trans);

    // Scenario 9: SLL - Mid-range shift
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLL_BITS, `RTYPE_BITS, 32'h0000FFFF, 32'h00000010, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLL: Mid-Range Shift (0000FFFF << 16)", trans);

    // --- SRL Operations (Shift Right Logical) ---
    // Scenario 10: SRL - Shift by 2
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SRL_BITS, `RTYPE_BITS, 32'h80000000, 32'h00000002, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SRL: Shift by 2 (80000000 >> 2)", trans);

    // Scenario 11: SRL - Shift all bits out (32 bits)
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SRL_BITS, `RTYPE_BITS, 32'hFFFFFFFF, 32'h00000020, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SRL: Shift All Bits Out (FFFFFFFF >> 32)", trans);

    // Scenario 12: SRL - Zero shift amount
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SRL_BITS, `RTYPE_BITS, 32'h5555AAAA, 32'h00000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SRL: Zero Shift Amount (5555AAAA >> 0)", trans);

    // Scenario 13: SRL - I_TYPE with immediate
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SRL_BITS, `ITYPE_BITS, 32'hFF000000, 32'h00000000, 32'h00000004, 1'b1, 1);
    finish_item(trans);
    print_scenario("SRL: I_TYPE with Immediate (FF000000 >> 4)", trans);

    // Scenario 14: SRL - Negative value (logical shift)
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SRL_BITS, `RTYPE_BITS, 32'hF0000000, 32'h00000001, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SRL: Negative Value Shifted (F0000000 >> 1)", trans);

    // Scenario 15: SRL - All ones shifted
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SRL_BITS, `RTYPE_BITS, 32'hFFFFFFFF, 32'h00000004, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SRL: All Ones Shifted (FFFFFFFF >> 4)", trans);

    // Scenario 16: SRL - Small value, large shift
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SRL_BITS, `RTYPE_BITS, 32'hF0000000, 32'h0000001F, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SRL: Small Value Large Shift (F0000000 >> 31)", trans);

    // Scenario 17: SRL - Mid-range shift
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SRL_BITS, `RTYPE_BITS, 32'hFFFF0000, 32'h00000010, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SRL: Mid-Range Shift (FFFF0000 >> 16)", trans);

    // Scenario 18: SRL - Single bit shifted
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SRL_BITS, `RTYPE_BITS, 32'h80000000, 32'h0000001F, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SRL: Single Bit Shifted (80000000 >> 31)", trans);

    // --- SRA Operations (Shift Right Arithmetic) ---
    // Scenario 19: SRA - Negative shift by 1
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SRA_BITS, `RTYPE_BITS, 32'h80000000, 32'h00000001, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SRA: Negative Shift by 1 (80000000 >>> 1)", trans);

    // Scenario 20: SRA - Positive shift by 3
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SRA_BITS, `RTYPE_BITS, 32'h000000FF, 32'h00000003, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SRA: Positive Shift by 3 (000000FF >>> 3)", trans);

    // Scenario 21: SRA - Shift all bits out (32 bits)
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SRA_BITS, `RTYPE_BITS, 32'h80000000, 32'h00000020, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SRA: Shift All Bits Out (80000000 >>> 32)", trans);

    // Scenario 22: SRA - Zero shift amount
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SRA_BITS, `RTYPE_BITS, 32'hF555AAAA, 32'h00000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SRA: Zero Shift Amount (F555AAAA >>> 0)", trans);

    // Scenario 23: SRA - I_TYPE with immediate
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SRA_BITS, `ITYPE_BITS, 32'hFF000000, 32'h00000000, 32'h00000004, 1'b1, 1);
    finish_item(trans);
    print_scenario("SRA: I_TYPE with Immediate (FF000000 >>> 4)", trans);

    // Scenario 24: SRA - All ones shifted
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SRA_BITS, `RTYPE_BITS, 32'hFFFFFFFF, 32'h00000004, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SRA: All Ones Shifted (FFFFFFFF >>> 4)", trans);

    // Scenario 25: SRA - Small positive value, large shift
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SRA_BITS, `RTYPE_BITS, 32'h0000000F, 32'h0000001F, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SRA: Small Positive Value Large Shift (0000000F >>> 31)", trans);

    // Scenario 26: SRA - Negative value, mid-range shift
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SRA_BITS, `RTYPE_BITS, 32'hF0000000, 32'h00000010, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SRA: Negative Value Mid-Range Shift (F0000000 >>> 16)", trans);

    // Scenario 27: SRA - Single bit shifted
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SRA_BITS, `RTYPE_BITS, 32'h80000000, 32'h0000001F, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SRA: Single Bit Shifted (80000000 >>> 31)", trans);
  endtask

  // Test comparison operations (SLT, SLTU, EQ, NEQ, GE, GEU) with exhaustive edge cases
  virtual task test_comparison_scenarios();
    transaction trans;

    // --- SLT Operations (Set Less Than, Signed) ---
    // Scenario 1: SLT - Negative vs Positive
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLT_BITS, `RTYPE_BITS, 32'h80000000, 32'h00000001, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLT: Negative vs Positive (80000000 < 00000001)", trans);

    // Scenario 2: SLT - Positive vs Negative
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLT_BITS, `RTYPE_BITS, 32'h00000001, 32'h80000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLT: Positive vs Negative (00000001 < 80000000)", trans);

    // Scenario 3: SLT - Equal values (positive)
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLT_BITS, `RTYPE_BITS, 32'h00001000, 32'h00001000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLT: Equal Positive Values (00001000 < 00001000)", trans);

    // Scenario 4: SLT - Zero vs Positive
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLT_BITS, `RTYPE_BITS, 32'h00000000, 32'h00000001, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLT: Zero vs Positive (00000000 < 00000001)", trans);

    // Scenario 5: SLT - I_TYPE with immediate
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLT_BITS, `ITYPE_BITS, 32'h80000000, 32'h00000000, 32'h7FFFFFFF, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLT: I_TYPE with Immediate (80000000 < 7FFFFFFF)", trans);

    // Scenario 6: SLT - Maximum vs Minimum
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLT_BITS, `RTYPE_BITS, 32'h7FFFFFFF, 32'h80000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLT: Maximum vs Minimum (7FFFFFFF < 80000000)", trans);

    // Scenario 7: SLT - Negative vs Negative
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLT_BITS, `RTYPE_BITS, 32'h80000000, 32'hF0000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLT: Negative vs Negative (80000000 < F0000000)", trans);

    // Scenario 8: SLT - Zero vs Zero
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLT_BITS, `RTYPE_BITS, 32'h00000000, 32'h00000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLT: Zero vs Zero (00000000 < 00000000)", trans);

    // Scenario 9: SLT - All ones vs All ones
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLT_BITS, `RTYPE_BITS, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLT: All Ones vs All Ones (FFFFFFFF < FFFFFFFF)", trans);

    // --- SLTU Operations (Set Less Than Unsigned) ---
    // Scenario 10: SLTU - Large vs Small
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLTU_BITS, `RTYPE_BITS, 32'hFFFFFFFF, 32'h00000001, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLTU: Large vs Small (FFFFFFFF < 00000001)", trans);

    // Scenario 11: SLTU - Small vs Large
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLTU_BITS, `RTYPE_BITS, 32'h00000001, 32'hFFFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLTU: Small vs Large (00000001 < FFFFFFFF)", trans);

    // Scenario 12: SLTU - Equal values
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLTU_BITS, `RTYPE_BITS, 32'hAAAA5555, 32'hAAAA5555, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLTU: Equal Values (AAAA5555 < AAAA5555)", trans);

    // Scenario 13: SLTU - Zero vs Positive
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLTU_BITS, `RTYPE_BITS, 32'h00000000, 32'h00000001, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLTU: Zero vs Positive (00000000 < 00000001)", trans);

    // Scenario 14: SLTU - I_TYPE with immediate
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLTU_BITS, `ITYPE_BITS, 32'h80000000, 32'h00000000, 32'h7FFFFFFF, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLTU: I_TYPE with Immediate (80000000 < 7FFFFFFF)", trans);

    // Scenario 15: SLTU - Zero vs Zero
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLTU_BITS, `RTYPE_BITS, 32'h00000000, 32'h00000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLTU: Zero vs Zero (00000000 < 00000000)", trans);

    // Scenario 16: SLTU - Negative vs Positive (unsigned)
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLTU_BITS, `RTYPE_BITS, 32'hF0000000, 32'h0FFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLTU: Negative vs Positive (F0000000 < 0FFFFFFF)", trans);

    // Scenario 17: SLTU - Maximum vs Maximum
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLTU_BITS, `RTYPE_BITS, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLTU: Maximum vs Maximum (FFFFFFFF < FFFFFFFF)", trans);

    // Scenario 18: SLTU - Small vs Slightly Larger
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`SLTU_BITS, `RTYPE_BITS, 32'h00000001, 32'h00000002, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("SLTU: Small vs Slightly Larger (00000001 < 00000002)", trans);

    // --- EQ Operations (Equal) ---
    // Scenario 19: EQ - Equal values
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`EQ_BITS, `RTYPE_BITS, 32'h12345678, 32'h12345678, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("EQ: Equal Values (12345678 == 12345678)", trans);

    // Scenario 20: EQ - Different values
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`EQ_BITS, `RTYPE_BITS, 32'hAAAA5555, 32'h5555AAAA, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("EQ: Different Values (AAAA5555 == 5555AAAA)", trans);

    // Scenario 21: EQ - Zero vs Zero
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`EQ_BITS, `RTYPE_BITS, 32'h00000000, 32'h00000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("EQ: Zero vs Zero (00000000 == 00000000)", trans);

    // Scenario 22: EQ - All ones vs All ones
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`EQ_BITS, `RTYPE_BITS, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("EQ: All Ones vs All Ones (FFFFFFFF == FFFFFFFF)", trans);

    // Scenario 23: EQ - I_TYPE with immediate
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`EQ_BITS, `ITYPE_BITS, 32'h00001000, 32'h00000000, 32'h00001000, 1'b1, 1);
    finish_item(trans);
    print_scenario("EQ: I_TYPE with Immediate (00001000 == 00001000)", trans);

    // Scenario 24: EQ - Negative vs Positive
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`EQ_BITS, `RTYPE_BITS, 32'h80000000, 32'h7FFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("EQ: Negative vs Positive (80000000 == 7FFFFFFF)", trans);

    // Scenario 25: EQ - Zero vs Non-Zero
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`EQ_BITS, `RTYPE_BITS, 32'h00000000, 32'h00000001, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("EQ: Zero vs Non-Zero (00000000 == 00000001)", trans);

    // Scenario 26: EQ - Single bit difference
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`EQ_BITS, `RTYPE_BITS, 32'h00000001, 32'h00000002, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("EQ: Single Bit Difference (00000001 == 00000002)", trans);

    // Scenario 27: EQ - Large vs Large
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`EQ_BITS, `RTYPE_BITS, 32'hFFFF0000, 32'hFFFF0000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("EQ: Large vs Large (FFFF0000 == FFFF0000)", trans);

    // --- NEQ Operations (Not Equal) ---
    // Scenario 28: NEQ - Different values
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`NEQ_BITS, `RTYPE_BITS, 32'hAAAA5555, 32'h5555AAAA, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("NEQ: Different Values (AAAA5555 != 5555AAAA)", trans);

    // Scenario 29: NEQ - Equal values
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`NEQ_BITS, `RTYPE_BITS, 32'h12345678, 32'h12345678, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("NEQ: Equal Values (12345678 != 12345678)", trans);

    // Scenario 30: NEQ - Zero vs Zero
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`NEQ_BITS, `RTYPE_BITS, 32'h00000000, 32'h00000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("NEQ: Zero vs Zero (00000000 != 00000000)", trans);

    // Scenario 31: NEQ - All ones vs All ones
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`NEQ_BITS, `RTYPE_BITS, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("NEQ: All Ones vs All Ones (FFFFFFFF != FFFFFFFF)", trans);

    // Scenario 32: NEQ - I_TYPE with immediate
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`NEQ_BITS, `ITYPE_BITS, 32'h00001000, 32'h00000000, 32'h00002000, 1'b1, 1);
    finish_item(trans);
    print_scenario("NEQ: I_TYPE with Immediate (00001000 != 00002000)", trans);

    // Scenario 33: NEQ - Negative vs Positive
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`NEQ_BITS, `RTYPE_BITS, 32'h80000000, 32'h7FFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("NEQ: Negative vs Positive (80000000 != 7FFFFFFF)", trans);

    // Scenario 34: NEQ - Zero vs Non-Zero
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`NEQ_BITS, `RTYPE_BITS, 32'h00000000, 32'h00000001, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("NEQ: Zero vs Non-Zero (00000000 != 00000001)", trans);

    // Scenario 35: NEQ - Single bit difference
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`NEQ_BITS, `RTYPE_BITS, 32'h00000001, 32'h00000002, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("NEQ: Single Bit Difference (00000001 != 00000002)", trans);

    // Scenario 36: NEQ - Large vs Large
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`NEQ_BITS, `RTYPE_BITS, 32'hFFFF0000, 32'hFFFE0000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("NEQ: Large vs Large (FFFF0000 != FFFE0000)", trans);

    // --- GE Operations (Greater Than or Equal, Signed) ---
    // Scenario 37: GE - Positive vs Negative
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`GE_BITS, `RTYPE_BITS, 32'h00000001, 32'h80000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("GE: Positive vs Negative (00000001 >= 80000000)", trans);

    // Scenario 38: GE - Negative vs Positive
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`GE_BITS, `RTYPE_BITS, 32'h80000000, 32'h00000001, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("GE: Negative vs Positive (80000000 >= 00000001)", trans);

    // Scenario 39: GE - Equal values
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`GE_BITS, `RTYPE_BITS, 32'h7FFFFFFF, 32'h7FFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("GE: Equal Values (7FFFFFFF >= 7FFFFFFF)", trans);

    // Scenario 40: GE - Zero vs Positive
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`GE_BITS, `RTYPE_BITS, 32'h00000000, 32'h00000001, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("GE: Zero vs Positive (00000000 >= 00000001)", trans);

    // Scenario 41: GE - I_TYPE with immediate
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`GE_BITS, `ITYPE_BITS, 32'h00001000, 32'h00000000, 32'h00000FFF, 1'b1, 1);
    finish_item(trans);
    print_scenario("GE: I_TYPE with Immediate (00001000 >= 00000FFF)", trans);

    // Scenario 42: GE - Zero vs Zero
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`GE_BITS, `RTYPE_BITS, 32'h00000000, 32'h00000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("GE: Zero vs Zero (00000000 >= 00000000)", trans);

    // Scenario 43: GE - Negative vs Negative
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`GE_BITS, `RTYPE_BITS, 32'hF0000000, 32'h80000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("GE: Negative vs Negative (F0000000 >= 80000000)", trans);

    // Scenario 44: GE - Maximum vs Minimum
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`GE_BITS, `RTYPE_BITS, 32'h7FFFFFFF, 32'h80000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("GE: Maximum vs Minimum (7FFFFFFF >= 80000000)", trans);

    // Scenario 45: GE - Small vs Slightly Smaller
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`GE_BITS, `RTYPE_BITS, 32'h00000002, 32'h00000001, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("GE: Small vs Slightly Smaller (00000002 >= 00000001)", trans);

    // --- GEU Operations (Greater Than or Equal Unsigned) ---
    // Scenario 46: GEU - Unsigned comparison
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`GEU_BITS, `RTYPE_BITS, 32'h80000000, 32'h7FFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("GEU: Unsigned Comparison (80000000 >= 7FFFFFFF)", trans);

    // Scenario 47: GEU - Small vs Large
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`GEU_BITS, `RTYPE_BITS, 32'h00000001, 32'hFFFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("GEU: Small vs Large (00000001 >= FFFFFFFF)", trans);

    // Scenario 48: GEU - Equal values
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`GEU_BITS, `RTYPE_BITS, 32'hAAAA5555, 32'hAAAA5555, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("GEU: Equal Values (AAAA5555 >= AAAA5555)", trans);

    // Scenario 49: GEU - Zero vs Positive
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`GEU_BITS, `RTYPE_BITS, 32'h00000000, 32'h00000001, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("GEU: Zero vs Positive (00000000 >= 00000001)", trans);

    // Scenario 50: GEU - I_TYPE with immediate
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`GEU_BITS, `ITYPE_BITS, 32'hFFFF0000, 32'h00000000, 32'hFFFE0000, 1'b1, 1);
    finish_item(trans);
    print_scenario("GEU: I_TYPE with Immediate (FFFF0000 >= FFFE0000)", trans);

    // Scenario 51: GEU - Zero vs Zero
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`GEU_BITS, `RTYPE_BITS, 32'h00000000, 32'h00000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("GEU: Zero vs Zero (00000000 >= 00000000)", trans);

    // Scenario 52: GEU - Maximum vs Maximum
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`GEU_BITS, `RTYPE_BITS, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("GEU: Maximum vs Maximum (FFFFFFFF >= FFFFFFFF)", trans);

    // Scenario 53: GEU - Large vs Slightly Smaller
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`GEU_BITS, `RTYPE_BITS, 32'h80000000, 32'h7FFFFFFF, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("GEU: Large vs Slightly Smaller (80000000 >= 7FFFFFFF)", trans);

    // Scenario 54: GEU - Positive vs Negative (unsigned)
    trans = transaction::type_id::create("trans");
    start_item(trans);
    trans.set_values(`GEU_BITS, `RTYPE_BITS, 32'h0FFFFFFF, 32'hF0000000, 32'h0, 1'b1, 1);
    finish_item(trans);
    print_scenario("GEU: Positive vs Negative (0FFFFFFF >= F0000000)", trans);
  endtask

  // Generate random transactions with exhaustive constraints for maximum coverage
  virtual task generate_random_scenarios();
    transaction trans;
    int num_ops = 14; // Total ALU operations: ADD, SUB, SLT, SLTU, XOR, OR, AND, SLL, SRL, SRA, EQ, NEQ, GE, GEU
    int cycle_count = 0;

    // Define additional constraint modes in transaction.sv if not already present
    // These are assumed to be added to transaction.sv for this enhancement
    for (int i = 0; i < num_transactions; i++) begin
      trans = transaction::type_id::create("trans");
      start_item(trans);

      // Disable all special constraints by default
      trans.zero_operand_c.constraint_mode(0);  // One operand is zero
      trans.max_value_c.constraint_mode(0);  // Operands at max value (FFFFFFFF)
      trans.sign_boundary_c.constraint_mode(
          0);  // Operands near sign boundary (7FFFFFFF, 80000000)
      trans.small_value_c.constraint_mode(0);  // Small values (0 to FFFF)
      trans.large_value_c.constraint_mode(0);  // Large values (FFFF0000 to FFFFFFFF)
      trans.opposite_signs_c.constraint_mode(0);  // One positive, one negative
      trans.shift_extreme_c.constraint_mode(0);  // Shift amounts 0, 1, 31 for SLL/SRL/SRA
      trans.equal_values_c.constraint_mode(0);  // Equal operands for comparisons

      // Cycle through constraint combinations for diversity
      case (cycle_count % 10)
        0: trans.zero_operand_c.constraint_mode(1);  // Zero operand
        1: trans.max_value_c.constraint_mode(1);  // Max values
        2: trans.sign_boundary_c.constraint_mode(1);  // Sign boundary
        3: trans.small_value_c.constraint_mode(1);  // Small values
        4: trans.large_value_c.constraint_mode(1);  // Large values
        5: trans.opposite_signs_c.constraint_mode(1);  // Opposite signs
        6: trans.shift_extreme_c.constraint_mode(1);  // Extreme shift amounts
        7: trans.equal_values_c.constraint_mode(1);  // Equal values
        8: begin  // Mix of constraints
          trans.zero_operand_c.constraint_mode(1);
          trans.sign_boundary_c.constraint_mode(1);
        end
        9: ;  // Fully random (no special constraints)
      endcase
      cycle_count++;

      // Randomize with exhaustive constraints
      if (!trans.randomize() with {
            // Even distribution across all ALU operations
            i_alu dist {
              (1 << `ADD)  := 10,  // Arithmetic
              (1 << `SUB)  := 10,
              (1 << `SLT)  := 10,  // Signed comparisons
              (1 << `SLTU) := 10,  // Unsigned comparisons
              (1 << `XOR)  := 10,  // Logical
              (1 << `OR)   := 10,
              (1 << `AND)  := 10,
              (1 << `SLL)  := 10,  // Shifts
              (1 << `SRL)  := 10,
              (1 << `SRA)  := 10,
              (1 << `EQ)   := 10,  // Equality
              (1 << `NEQ)  := 10,
              (1 << `GE)   := 10,  // Greater or equal
              (1 << `GEU)  := 10
            };

            // Randomize opcode with weights for instruction types
            i_opcode dist {
              `RTYPE_BITS  := 40,  // Favor R_TYPE for register-based operations
              `ITYPE_BITS  := 40,  // Favor I_TYPE for immediate-based operations
              `BRANCH_BITS := 10,  // Less common but still tested
              `FENCE_BITS  := 5,  // Rare pipeline control
              `SYSTEM_BITS := 5  // Rare system operations
            };

            // Randomize pipeline control signals
            i_ce dist {
              1'b1 := 90,  // Mostly active
              1'b0 := 10  // Occasionally disabled
            };
            rst_n dist {
              1'b1 := 95,  // Mostly deasserted
              1'b0 := 5  // Occasionally reset
            };
            i_stall dist {
              1'b0 := 80,  // Mostly no stall
              1'b1 := 20  // Occasional stall
            };
            i_force_stall dist {
              1'b0 := 90,  // Rarely forced stall
              1'b1 := 10
            };
            i_flush dist {
              1'b0 := 85,  // Mostly no flush
              1'b1 := 15  // Occasional flush
            };

            // Additional constraints for operands
            i_rs1 dist {
              32'h00000000                  := 10,  // Zero
              [32'h00000001 : 32'h0000FFFF] := 20,  // Small positive
              [32'h7FFF0000 : 32'h7FFFFFFF] := 20,  // Near positive max
              32'h80000000                  := 10,  // Negative min
              [32'h80000001 : 32'hFFFF0000] := 20,  // Large negative
              32'hFFFFFFFF                  := 10  // Max unsigned
            };
            i_rs2 dist {
              32'h00000000                  := 10,
              [32'h00000001 : 32'h0000FFFF] := 20,
              [32'h7FFF0000 : 32'h7FFFFFFF] := 20,
              32'h80000000                  := 10,
              [32'h80000001 : 32'hFFFF0000] := 20,
              32'hFFFFFFFF                  := 10
            };
            i_imm dist {
              32'h00000000                  := 10,
              [32'h00000001 : 32'h00000FFF] := 20,  // Small immediate for I_TYPE
              [32'h7FFF0000 : 32'h7FFFFFFF] := 20,
              32'h80000000                  := 10,
              [32'h80000001 : 32'hFFFF0000] := 20,
              32'hFFFFFFFF                  := 10
            };

            // Shift-specific constraints (when i_alu is SLL, SRL, or SRA)
            (i_alu == (1 << `SLL) || i_alu == (1 << `SRL) || i_alu == (1 << `SRA)) ->
            i_rs2[31:5] == 0;  // Shift amount in lower 5 bits
            (i_alu == (1 << `SLL) || i_alu == (1 << `SRL) || i_alu == (1 << `SRA)) ->
            i_imm[31:5] == 0;  // Immediate shift amount in lower 5 bits

            // Address and funct3 randomization
            i_rs1_addr inside {[0 : 31]};  // Valid register addresses
            i_rd_addr inside {[0 : 31]};
            i_funct3 inside {[0 : 7]};  // Valid funct3 values
          }) begin
        `uvm_error("RAND_FAIL", $sformatf("Randomization failed for transaction %0d", i))
      end

      finish_item(trans);
      print_scenario($sformatf("Random Scenario %0d", i), trans);
    end
  endtask

  /*
    // Test deactivation of clock enable with a FENCE instruction
    virtual task deactivate_ce();
        transaction trans;

        // Scenario: Deactivate CE with FENCE instruction
        trans = transaction::type_id::create("trans");
        start_item(trans);
        trans.set_values(`ADD_BITS, `FENCE_BITS, 32'h0, 32'h0, 32'h0, 1'b0, 1);
        finish_item(trans);
        print_scenario("Deactivate Clock Enable", trans);
    endtask

    */

  // Print transaction details for debugging and logging
  virtual function void print_scenario(string scenario_name, transaction trans);
    string alu_op_str;
    string opcode_str;

    // Map ALU operation index to string based on rv32i_alu_header.sv
    case (1)
      trans.i_alu[`ADD]:  alu_op_str = "ADD";
      trans.i_alu[`SUB]:  alu_op_str = "SUB";
      trans.i_alu[`SLT]:  alu_op_str = "SLT";
      trans.i_alu[`SLTU]: alu_op_str = "SLTU";
      trans.i_alu[`XOR]:  alu_op_str = "XOR";
      trans.i_alu[`OR]:   alu_op_str = "OR";
      trans.i_alu[`AND]:  alu_op_str = "AND";
      trans.i_alu[`SLL]:  alu_op_str = "SLL";
      trans.i_alu[`SRL]:  alu_op_str = "SRL";
      trans.i_alu[`SRA]:  alu_op_str = "SRA";
      trans.i_alu[`EQ]:   alu_op_str = "EQ";
      trans.i_alu[`NEQ]:  alu_op_str = "NEQ";
      trans.i_alu[`GE]:   alu_op_str = "GE";
      trans.i_alu[`GEU]:  alu_op_str = "GEU";
      default:            alu_op_str = "UNKNOWN";
    endcase

    // Map opcode to string based on rv32i_alu_header.sv
    case (trans.i_opcode)
      `RTYPE_BITS:  opcode_str = "R_TYPE";
      `ITYPE_BITS:  opcode_str = "I_TYPE";
      `LOAD_BITS:   opcode_str = "LOAD";
      `STORE_BITS:  opcode_str = "STORE";
      `BRANCH_BITS: opcode_str = "BRANCH";
      `JAL_BITS:    opcode_str = "JAL";
      `JALR_BITS:   opcode_str = "JALR";
      `LUI_BITS:    opcode_str = "LUI";
      `AUIPC_BITS:  opcode_str = "AUIPC";
      `SYSTEM_BITS: opcode_str = "SYSTEM";
      `FENCE_BITS:  opcode_str = "FENCE";
      default:      opcode_str = "UNKNOWN";
    endcase

    // Log the transaction details using UVM info
    `uvm_info("SCENARIO", $sformatf(
              "\n=== %s ===\nOperation Type: %s\nInstruction Type: %s\nRS1: %h\nRS2: %h\nIMM: %h\nCE: %b\nRS1_ADDR: %h\nFUNCT3: %h\nPC: %h\nRD_ADDR: %h\nSTALL: %h\nFORCE_STALL: %h\nFLUSH: %h\nRST_N: %h"
                      ,
              scenario_name,
              alu_op_str,
              opcode_str,
              trans.i_rs1,
              trans.i_rs2,
              trans.i_imm,
              trans.i_ce,
              trans.i_rs1_addr,
              trans.i_funct3,
              trans.i_pc,
              trans.i_rd_addr,
              trans.i_stall,
              trans.i_force_stall,
              trans.i_flush,
              trans.rst_n
              ), UVM_MEDIUM)
  endfunction
endclass
