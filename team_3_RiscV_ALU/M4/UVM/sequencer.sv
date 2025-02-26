`include "uvm_macros.svh"
import uvm_pkg::*;

// Include the provided transaction.sv
`include "transaction.sv"

// Define ALU operations to match transaction.sv
typedef enum {
    ADD,
    SUB,
    AND,
    OR,
    XOR,
    SLL,
    SRL,
    SRA,
    SLT,
    SLTU,
    EQ,
    NEQ,
    GE,
    GEU
} alu_operation_e;

class alu_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(alu_sequence)

    int num_transactions = 1000;  // Number of random transactions, configurable

    function new(string name = "alu_sequence");
        super.new(name);
    endfunction

    virtual task body();
        if (!uvm_config_db#(int)::get(null, get_full_name(), "num_transactions", num_transactions))
            `uvm_info("CONFIG", "Using default num_transactions = 1000", UVM_HIGH)

        generate_predefined_scenarios();
        generate_random_scenarios();
        deactivate_ce();
    endtask

    virtual task generate_predefined_scenarios();
        test_arithmetic_scenarios();
        test_logical_scenarios();
    endtask

    virtual task generate_random_scenarios();
        transaction trans;
        for (int i = 0; i < num_transactions; i++) begin
            trans = transaction::type_id::create("trans");
            start_item(trans);
            trans.zero_operand_c.constraint_mode(0);
            trans.max_value_c.constraint_mode(0);
            case (i % 3)
                0: trans.zero_operand_c.constraint_mode(1);
                1: trans.max_value_c.constraint_mode(1);
                2: ;  // No additional constraint
            endcase
            if (!trans.randomize()) `uvm_error("RAND_FAIL", "Randomization failed")
            finish_item(trans);
            print_scenario($sformatf("Random Scenario %0d", i), trans);
        end
    endtask

    virtual task test_arithmetic_scenarios();
        transaction trans;

        trans = transaction::type_id::create("trans");
        start_item(trans);
        trans.set_values(0, 11'b00000000000, 32'h7FFFFFFF, 32'h00000001, 32'h0,
                         1'b1);  // ADD (R-type)
        finish_item(trans);
        print_scenario("ADD: Overflow Test", trans);

        trans = transaction::type_id::create("trans");
        start_item(trans);
        trans.set_values(0, 11'b00000000000, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'h0,
                         1'b1);  // ADD (R-type)
        finish_item(trans);
        print_scenario("ADD: Maximum Values", trans);

        trans = transaction::type_id::create("trans");
        start_item(trans);
        trans.set_values(1, 11'b00000000000, 32'h80000000, 32'h00000001, 32'h0,
                         1'b1);  // SUB (R-type)
        finish_item(trans);
        print_scenario("SUB: Underflow Test", trans);

        trans = transaction::type_id::create("trans");
        start_item(trans);
        trans.set_values(1, 11'b00000000000, 32'h5A5A5A5A, 32'h5A5A5A5A, 32'h0,
                         1'b1);  // SUB (R-type)
        finish_item(trans);
        print_scenario("SUB: Zero Result", trans);
    endtask

    virtual task test_logical_scenarios();
        transaction trans;

        trans = transaction::type_id::create("trans");
        start_item(trans);
        trans.set_values(2, 11'b00000000000, 32'hAAAAAAAA, 32'h55555555, 32'h0,
                         1'b1);  // AND (R-type)
        finish_item(trans);
        print_scenario("AND: Alternating Bits", trans);

        trans = transaction::type_id::create("trans");
        start_item(trans);
        trans.set_values(3, 11'b00000000000, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'h0,
                         1'b1);  // OR (R-type)
        finish_item(trans);
        print_scenario("OR: Complementary Patterns", trans);

        trans = transaction::type_id::create("trans");
        start_item(trans);
        trans.set_values(4, 11'b00000000000, 32'hAAAAAAAA, 32'hAAAAAAAA, 32'h0,
                         1'b1);  // XOR (R-type)
        finish_item(trans);
        print_scenario("XOR: Same Values", trans);
    endtask

    virtual task deactivate_ce();
        transaction trans;

        trans = transaction::type_id::create("trans");
        start_item(trans);
        trans.set_values(0, 11'b01000000000, 32'h0, 32'h0, 32'h0, 1'b0);  // Fence, CE off
        finish_item(trans);
        print_scenario("Deactivate Clock Enable", trans);
    endtask

    virtual function void print_scenario(string scenario_name, transaction trans);
        alu_operation_e alu_op;
        string          opcode_str;

        case (trans.i_alu)
            14'b00000000000001: alu_op = ADD;
            14'b00000000000010: alu_op = SUB;
            14'b00000000000100: alu_op = AND;
            14'b00000000001000: alu_op = OR;
            14'b00000000010000: alu_op = XOR;
            14'b00000000100000: alu_op = SLL;
            14'b00000001000000: alu_op = SRL;
            14'b00000010000000: alu_op = SRA;
            14'b00000100000000: alu_op = SLT;
            14'b00001000000000: alu_op = SLTU;
            14'b00010000000000: alu_op = EQ;
            14'b00100000000000: alu_op = NEQ;
            14'b01000000000000: alu_op = GE;
            14'b10000000000000: alu_op = GEU;
            default:            alu_op = ADD;
        endcase

        case (trans.i_opcode)
            11'b00000000000: opcode_str = "R_TYPE";
            11'b00000000001: opcode_str = "I_TYPE";
            11'b00000000010: opcode_str = "LOAD";
            11'b00000000100: opcode_str = "STORE";
            11'b00000001000: opcode_str = "BRANCH";
            11'b00000010000: opcode_str = "JAL";
            11'b00000100000: opcode_str = "JALR";
            11'b00001000000: opcode_str = "LUI";
            11'b00010000000: opcode_str = "AUIPC";
            11'b00100000000: opcode_str = "SYSTEM";
            11'b01000000000: opcode_str = "FENCE";
            default:         opcode_str = "UNKNOWN";
        endcase

        `uvm_info("SCENARIO", $sformatf(
                  "\n=== %s ===\nOperation Type: %s\nInstruction Type: %s\nRS1: %h\nRS2: %h\nIMM: %h\nCE: %b"
                      ,
                  scenario_name,
                  alu_op.name(),
                  opcode_str,
                  trans.i_rs1,
                  trans.i_rs2,
                  trans.i_imm,
                  trans.i_ce
                  ), UVM_MEDIUM)
    endfunction
endclass
