/*
ECE593: Milestone 2, Group 3
File name : generator.sv
File version : 1.2
Class name : generator
Description : 
This class generates randomized transactions for the RISC-V ALU design under verification.
*/

`include "transaction.sv"
typedef enum {
    ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, 
    SLT, SLTU, EQ, NEQ, GE, GEU
} alu_operation_e;

typedef enum {
    R_TYPE = 'b00000000000,
    I_TYPE = 'b00000000001,
    LOAD   = 'b00000000010,
    STORE  = 'b00000000011,
    BRANCH = 'b00000000100,
    JAL    = 'b00000000101,
    JALR   = 'b00000000110,
    LUI    = 'b00000000111,
    AUIPC  = 'b00000001000,
    SYSTEM = 'b00000001001,
    FENCE  = 'b00000001010
} opcode_type_e;

// First, define a typedef for the mailbox
typedef mailbox #(transaction) mail_box;

class generator;
  transaction trans;
  mail_box gen2drv_mb;  // Mailbox to communicate with driver
  int num_transactions = 50;
  event generation_complete;  // Event to signal completion
  
  function new(mail_box gen2drv_mb);
    this.gen2drv_mb = gen2drv_mb;
    trans = new();
  endfunction
  
  task generate_scenarios();
    // Predefined scenarios
    generate_predefined_scenarios();
    
    // Random scenarios with different constraint combinations
    generate_random_scenarios();
    
    -> generation_complete;  // Trigger the completion event
  endtask

task generate_predefined_scenarios();
    transaction trans_clone;
    
    test_arithmetic_scenarios();
    test_logical_scenarios();
    test_shift_scenarios();
    test_comparison_scenarios();
    
    test_memory_scenarios();
    test_branch_scenarios();
    test_jump_scenarios();
    test_upper_immediate_scenarios();
    test_system_and_fence_scenarios();
endtask


task generate_random_scenarios();
    transaction trans_clone;
    
    for(int i = 0; i < num_transactions; i++) begin
        // Disable all special constraints initially
        trans.zero_operand_c.constraint_mode(0);
        trans.max_value_c.constraint_mode(0);

        // Enable different constraint combinations based on iteration
        case(i % 3)
            0: trans.zero_operand_c.constraint_mode(1);    // Zero operand cases
            1: trans.max_value_c.constraint_mode(1);       // Maximum value cases
            2: begin end // Fully random case, no special constraints
        endcase

        void'(trans.randomize());
        trans_clone = trans.clone();
        gen2drv_mb.put(trans_clone);
        print_scenario($sformatf("Random Scenario %0d", i));
    end
endtask

task test_arithmetic_scenarios();
    // ADD: Test overflow condition
    trans.set_values(0, 11'b00000000000, 32'h7FFFFFFF, 32'h00000001, 32'h0, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("ADD: Overflow Test");

    // ADD: Test with maximum values
    trans.set_values(0, 11'b00000000000, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'h0, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("ADD: Maximum Values");

    // SUB: Test underflow condition
    trans.set_values(1, 11'b00000000000, 32'h80000000, 32'h00000001, 32'h0, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("SUB: Underflow Test");

    // SUB: Test with zero result
    trans.set_values(1, 11'b00000000000, 32'h5A5A5A5A, 32'h5A5A5A5A, 32'h0, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("SUB: Zero Result");
endtask

task test_logical_scenarios();
    // AND: Alternating bit pattern
    trans.set_values(2, 11'b00000000000, 32'hAAAAAAAA, 32'h55555555, 32'h0, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("AND: Alternating Bits");

    // OR: Complementary patterns
    trans.set_values(3, 11'b00000000000, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'h0, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("OR: Complementary Patterns");

    // XOR: Same values
    trans.set_values(4, 11'b00000000000, 32'hAAAAAAAA, 32'hAAAAAAAA, 32'h0, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("XOR: Same Values");
endtask

task test_shift_scenarios();
    // SLL: Maximum shift
    trans.set_values(5, 11'b00000000000, 32'h00000001, 32'h0000001F, 32'h0, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("SLL: Maximum Shift");

    // SRL: Sign bit test
    trans.set_values(6, 11'b00000000000, 32'h80000000, 32'h00000001, 32'h0, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("SRL: Sign Bit Test");

    // SRA: Sign preservation test
    trans.set_values(7, 11'b00000000000, 32'h80000000, 32'h0000001F, 32'h0, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("SRA: Sign Preservation");
endtask

task test_comparison_scenarios();
    // SLT: Sign boundary test
    trans.set_values(8, 11'b00000000000, 32'h80000000, 32'h7FFFFFFF, 32'h0, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("SLT: Sign Boundary");

    // SLTU: Maximum vs zero
    trans.set_values(9, 11'b00000000000, 32'hFFFFFFFF, 32'h00000000, 32'h0, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("SLTU: Maximum vs Zero");

    // EQ: Equal values
    trans.set_values(10, 11'b00000000000, 32'hAAAAAAAA, 32'hAAAAAAAA, 32'h0, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("EQ: Equal Values");

    // GE: Equal values edge case
    trans.set_values(12, 11'b00000000000, 32'h80000000, 32'h80000000, 32'h0, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("GE: Equal Values Edge Case");
endtask

// Add these new tasks to the generator class

task test_memory_scenarios();
    // Load: Test address alignment
    trans.set_values(0, `LOAD, 32'h00000004, 32'h0, 32'h00000FFF, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("LOAD: Address Alignment Test");

    // Store: Test with maximum address
    trans.set_values(0, `STORE, 32'hFFFFFFFC, 32'hAAAAAAAA, 32'h0, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("STORE: Maximum Address Test");
endtask

task test_branch_scenarios();
    // Branch: Test taken condition
    trans.set_values(10, `BRANCH, 32'h00000005, 32'h00000005, 32'h00000100, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("BRANCH: Taken Condition");

    // Branch: Test not taken condition
    trans.set_values(10, `BRANCH, 32'h00000005, 32'h00000006, 32'h00000100, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("BRANCH: Not Taken Condition");
endtask

task test_jump_scenarios();
    // JAL: Test forward jump
    trans.set_values(0, `JAL, 32'h00001000, 32'h0, 32'h00000FFF, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("JAL: Forward Jump");

    // JALR: Test return address
    trans.set_values(0, `JALR, 32'h00000100, 32'h0, 32'h00000004, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("JALR: Return Address");
endtask

task test_upper_immediate_scenarios();
    // LUI: Test maximum immediate
    trans.set_values(0, `LUI, 32'h0, 32'h0, 32'hFFFFF000, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("LUI: Maximum Immediate");

    // AUIPC: Test PC-relative addressing
    trans.set_values(0, `AUIPC, 32'h00001000, 32'h0, 32'h000FF000, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("AUIPC: PC-relative Addressing");
endtask

task test_system_and_fence_scenarios();
    // SYSTEM: Test CSR operations
    trans.set_values(0, `SYSTEM, 32'h00000FFF, 32'h0, 32'h00000001, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("SYSTEM: CSR Operation");

    // FENCE: Test memory ordering
    trans.set_values(0, `FENCE, 32'h0, 32'h0, 32'h0, 1'b1);
    gen2drv_mb.put(trans.clone());
    print_scenario("FENCE: Memory Ordering");
endtask
  
function void print_scenario(string scenario_name);
    alu_operation_e alu_op;
    string opcode_str;
    
    // Determine ALU operation based on i_alu one-hot encoding
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
        default: alu_op = ADD;
    endcase

    // Determine opcode type
    case (trans.i_opcode)
        R_TYPE: opcode_str = "R_TYPE";
        I_TYPE: opcode_str = "I_TYPE";
        LOAD:   opcode_str = "LOAD";
        STORE:  opcode_str = "STORE";
        BRANCH: opcode_str = "BRANCH";
        JAL:    opcode_str = "JAL";
        JALR:   opcode_str = "JALR";
        LUI:    opcode_str = "LUI";
        AUIPC:  opcode_str = "AUIPC";
        SYSTEM: opcode_str = "SYSTEM";
        FENCE:  opcode_str = "FENCE";
        default: opcode_str = "UNKNOWN";
    endcase

    $display("\n=== %s ===", scenario_name);
    $display("Operation Type: %s", alu_op.name());
    $display("Instruction Type: %s", opcode_str);
    $display("ALU Control: %b", trans.i_alu);
    $display("Opcode: %b", trans.i_opcode);
    $display("RS1: %h (Decimal: %0d)", trans.i_rs1, trans.i_rs1);
    $display("RS2: %h (Decimal: %0d)", trans.i_rs2, trans.i_rs2);
    $display("IMM: %h (Decimal: %0d)", trans.i_imm, trans.i_imm);
    $display("Clock Enable: %b", trans.i_ce);
    $display("Expected Result: %h (Decimal: %0d)", 
             trans.alu_operation(trans.i_rs1, trans.i_rs2, trans.i_imm, trans.i_alu),
             trans.verify_y);
    $display("--------------------");
endfunction

endclass
