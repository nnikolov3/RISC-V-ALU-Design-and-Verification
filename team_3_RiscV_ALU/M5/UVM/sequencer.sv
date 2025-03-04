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
    int num_transactions = 5;

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
        deactivate_ce();  // Test clock enable deactivation
    endtask

    // Generate predefined test scenarios for ALU operations
    virtual task generate_predefined_scenarios();
		reset_signals();
        test_arithmetic_scenarios();  // Test arithmetic operations (ADD, SUB)
        test_logical_scenarios();  // Test logical operations (AND, OR, XOR)
    endtask

    // Generate random transactions with varying constraints
    virtual task generate_random_scenarios();
        transaction trans;
        // Loop to generate the specified number of random transactions
        for (int i = 0; i < num_transactions; i++) begin
            trans = transaction::type_id::create("trans");
            start_item(trans);
            // Disable default constraints for flexibility
            trans.zero_operand_c.constraint_mode(0);
            trans.max_value_c.constraint_mode(0);
            // Apply constraints cyclically for variety
            case (i % 3)
                0: trans.zero_operand_c.constraint_mode(1);  // Force zero operands
                1: trans.max_value_c.constraint_mode(1);  // Force maximum values
                2: ;  // No additional constraint (fully random)
            endcase
            if (!trans.randomize()) `uvm_error("RAND_FAIL", "Randomization failed")
            finish_item(trans);
            print_scenario($sformatf("Random Scenario %0d", i), trans);
        end
    endtask
	
	virtual task reset_signals();
        transaction trans;

        // Scenario 0: Reset
        trans = transaction::type_id::create("trans");
        start_item(trans);
        trans.set_values(`ADD_BITS, `RTYPE_BITS, 32'h7FFFFFFF, 32'h00000001, 32'h0, 1'b1, 0);
        finish_item(trans);
        print_scenario("Reset", trans);		
	endtask

    // Test arithmetic operations with specific edge cases
    virtual task test_arithmetic_scenarios();
        transaction trans;

        // Scenario 1: ADD with potential overflow
        trans = transaction::type_id::create("trans");
        start_item(trans);
        trans.set_values(`ADD_BITS, `RTYPE_BITS, 32'h7FFFFFFF, 32'h00000001, 32'h0, 1'b1, 1);
        finish_item(trans);
        print_scenario("ADD: Overflow Test", trans);
	
        // Scenario 2: ADD with maximum values
        trans = transaction::type_id::create("trans");
        start_item(trans);
        trans.set_values(`ADD_BITS, `RTYPE_BITS, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'h0, 1'b1, 1);
        finish_item(trans);
        print_scenario("ADD: Maximum Values", trans);

        // Scenario 3: SUB with potential underflow
        trans = transaction::type_id::create("trans");
        start_item(trans);
        trans.set_values(`SUB_BITS, `RTYPE_BITS, 32'h80000000, 32'h00000001, 32'h0, 1'b1, 1);
        finish_item(trans);
        print_scenario("SUB: Underflow Test", trans);

        // Scenario 4: SUB resulting in zero
        trans = transaction::type_id::create("trans");
        start_item(trans);
        trans.set_values(`SUB_BITS, `RTYPE_BITS, 32'h5A5A5A5A, 32'h5A5A5A5A, 32'h0, 1'b1, 1);
        finish_item(trans);
        print_scenario("SUB: Zero Result", trans);
    endtask

    // Test logical operations with specific patterns
    virtual task test_logical_scenarios();
        transaction trans;

        // Scenario 1: AND with alternating bits
        trans = transaction::type_id::create("trans");
        start_item(trans);
        trans.set_values(`AND_BITS, `RTYPE_BITS, 32'hAAAAAAAA, 32'h55555555, 32'h0, 1'b1, 1);
        finish_item(trans);
        print_scenario("AND: Alternating Bits", trans);

        // Scenario 2: OR with complementary patterns
        trans = transaction::type_id::create("trans");
        start_item(trans);
        trans.set_values(`OR_BITS, `RTYPE_BITS, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'h0, 1'b1, 1);
        finish_item(trans);
        print_scenario("OR: Complementary Patterns", trans);

        // Scenario 3: XOR with identical values
        trans = transaction::type_id::create("trans");
        start_item(trans);
        trans.set_values(`XOR_BITS, `RTYPE_BITS, 32'hAAAAAAAA, 32'hAAAAAAAA, 32'h0, 1'b1, 1);
        finish_item(trans);
        print_scenario("XOR: Same Values", trans);
    endtask

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
