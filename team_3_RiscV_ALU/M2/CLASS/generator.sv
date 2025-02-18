/*
ECE593: Milestone 2, Group 3
File: generator.sv (Version: 1.2)
Class: generator

Description:
  This class is responsible for generating both predefined and randomized transactions
  to verify the RISC-V ALU design. It creates test scenarios for arithmetic, logical,
  shift, comparison, memory, branch, jump, upper immediate, system, and fence operations.
  Each generated transaction is sent to the driver via a mailbox.
*/

`include "transaction.sv"

//------------------------------------------------------------------------------
// Enumeration for ALU operations used during transaction generation.
//------------------------------------------------------------------------------
typedef enum {
    ADD,   // Addition
    SUB,   // Subtraction
    AND,   // Logical AND
    OR,    // Logical OR
    XOR,   // Logical XOR
    SLL,   // Logical Shift Left
    SRL,   // Logical Shift Right
    SRA,   // Arithmetic Shift Right
    SLT,   // Set Less Than (signed)
    SLTU,  // Set Less Than (unsigned)
    EQ,    // Equality check
    NEQ,   // Inequality check
    GE,    // Greater than or Equal (signed)
    GEU    // Greater than or Equal (unsigned)
} alu_operation_e;

//------------------------------------------------------------------------------
// Enumeration for opcode types corresponding to different RISC-V instruction formats.
//------------------------------------------------------------------------------
typedef enum {
    R_TYPE = 'b00000000000,  // Register-type instruction
    I_TYPE = 'b00000000001,  // Immediate-type instruction
    LOAD   = 'b00000000010,  // Load instruction
    STORE  = 'b00000000011,  // Store instruction
    BRANCH = 'b00000000100,  // Branch instruction
    JAL    = 'b00000000101,  // Jump and Link
    JALR   = 'b00000000110,  // Jump and Link Register
    LUI    = 'b00000000111,  // Load Upper Immediate
    AUIPC  = 'b00000001000,  // Add Upper Immediate to PC
    SYSTEM = 'b00000001001,  // System instructions (e.g., CSR)
    FENCE  = 'b00000001010   // Fence instructions (memory ordering)
} opcode_type_e;

//------------------------------------------------------------------------------
// Define a mailbox type for communication between the generator and driver.
//------------------------------------------------------------------------------
typedef mailbox#(transaction) mail_box;

class generator;
    transaction trans;  // Transaction object used for scenario generation.
    mail_box gen2drv_mb;  // Mailbox to send transactions to the driver.
    int num_transactions = 50;  // Number of random transactions to generate.
    event       generation_complete;    // Event to signal completion of scenario generation.

    //-------------------------------------------------------------------------
    // Constructor: Initialize the generator with a mailbox reference.
    //-------------------------------------------------------------------------
    function new(mail_box gen2drv_mb);
        this.gen2drv_mb = gen2drv_mb;
        trans           = new();
    endfunction

    //-------------------------------------------------------------------------
    // Task: generate_scenarios
    // Generates all test scenarios (predefined and random) and signals when done.
    //-------------------------------------------------------------------------
    task generate_scenarios();
        // Generate scenarios with predetermined test cases.
        generate_predefined_scenarios();

        // Generate scenarios with random values and varying constraints.
        generate_random_scenarios();

        // Signal that the generation process is complete.
        ->generation_complete;
    endtask

    //-------------------------------------------------------------------------
    // Task: generate_predefined_scenarios
    // Generates a suite of test scenarios covering a variety of instruction types.
    //-------------------------------------------------------------------------
    task generate_predefined_scenarios();
        transaction trans_clone;

        // Arithmetic operations tests (ADD and SUB)
        test_arithmetic_scenarios();

        // Logical operations tests (AND, OR, XOR)
        test_logical_scenarios();

        // Shift operations tests (SLL, SRL, SRA)
        test_shift_scenarios();

        // Comparison operations tests (SLT, SLTU, EQ, GE)
        test_comparison_scenarios();

        // Memory operations tests (LOAD, STORE)
        test_memory_scenarios();

        // Branch instruction tests
        test_branch_scenarios();

        // Jump instruction tests (JAL and JALR)
        test_jump_scenarios();

        // Upper immediate instruction tests (LUI and AUIPC)
        test_upper_immediate_scenarios();

        // System and fence instruction tests
        test_system_and_fence_scenarios();
    endtask

    //-------------------------------------------------------------------------
    // Task: generate_random_scenarios
    // Generates random test scenarios with different constraint combinations.
    //-------------------------------------------------------------------------
    task generate_random_scenarios();
        transaction trans_clone;

        for (int i = 0; i < num_transactions; i++) begin
            // Reset special constraint modes for a clean start.
            trans.zero_operand_c.constraint_mode(0);
            trans.max_value_c.constraint_mode(0);

            // Enable specific constraints based on the iteration index.
            case (i % 3)
                0: begin
                    // Enable zero operand constraint for testing edge cases.
                    trans.zero_operand_c.constraint_mode(1);
                end
                1: begin
                    // Enable maximum value constraint for upper-bound testing.
                    trans.max_value_c.constraint_mode(1);
                end
                2: begin
                    // Fully random case: no special constraints enabled.
                end
            endcase

            // Randomize transaction parameters.
            trans.randomize();
            trans_clone = trans.clone();

            // Send the generated transaction to the driver.
            gen2drv_mb.put(trans_clone);

            // Display details of the generated random scenario.
            print_scenario($sformatf("Random Scenario %0d", i));
        end
    endtask

    //-------------------------------------------------------------------------
    // Task: test_arithmetic_scenarios
    // Creates test cases for arithmetic operations (ADD and SUB) including edge cases.
    //-------------------------------------------------------------------------
    task test_arithmetic_scenarios();
        // ADD: Test overflow condition.
        trans.set_values(0, 11'b00000000000, 32'h7FFFFFFF, 32'h00000001, 32'h0,
                         1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("ADD: Overflow Test");

        // ADD: Test using maximum operand values.
        trans.set_values(0, 11'b00000000000, 32'hFFFFFFFF, 32'hFFFFFFFF, 32'h0,
                         1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("ADD: Maximum Values");

        // SUB: Test underflow condition.
        trans.set_values(1, 11'b00000000000, 32'h80000000, 32'h00000001, 32'h0,
                         1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("SUB: Underflow Test");

        // SUB: Test resulting in zero.
        trans.set_values(1, 11'b00000000000, 32'h5A5A5A5A, 32'h5A5A5A5A, 32'h0,
                         1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("SUB: Zero Result");
    endtask

    //-------------------------------------------------------------------------
    // Task: test_logical_scenarios
    // Creates test cases for logical operations (AND, OR, XOR) with specific bit patterns.
    //-------------------------------------------------------------------------
    task test_logical_scenarios();
        // AND: Test with alternating bit pattern operands.
        trans.set_values(2, 11'b00000000000, 32'hAAAAAAAA, 32'h55555555, 32'h0,
                         1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("AND: Alternating Bits");

        // OR: Test with complementary bit patterns.
        trans.set_values(3, 11'b00000000000, 32'hF0F0F0F0, 32'h0F0F0F0F, 32'h0,
                         1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("OR: Complementary Patterns");

        // XOR: Test with identical operands.
        trans.set_values(4, 11'b00000000000, 32'hAAAAAAAA, 32'hAAAAAAAA, 32'h0,
                         1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("XOR: Same Values");
    endtask

    //-------------------------------------------------------------------------
    // Task: test_shift_scenarios
    // Creates test cases for shift operations (SLL, SRL, SRA) covering edge conditions.
    //-------------------------------------------------------------------------
    task test_shift_scenarios();
        // SLL: Test with maximum shift amount.
        trans.set_values(5, 11'b00000000000, 32'h00000001, 32'h0000001F, 32'h0,
                         1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("SLL: Maximum Shift");

        // SRL: Test shifting a sign bit value.
        trans.set_values(6, 11'b00000000000, 32'h80000000, 32'h00000001, 32'h0,
                         1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("SRL: Sign Bit Test");

        // SRA: Test preserving the sign during arithmetic right shift.
        trans.set_values(7, 11'b00000000000, 32'h80000000, 32'h0000001F, 32'h0,
                         1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("SRA: Sign Preservation");
    endtask

    //-------------------------------------------------------------------------
    // Task: test_comparison_scenarios
    // Creates test cases for comparison operations (SLT, SLTU, EQ, GE) including boundary cases.
    //-------------------------------------------------------------------------
    task test_comparison_scenarios();
        // SLT: Test with operands at the sign boundary.
        trans.set_values(8, 11'b00000000000, 32'h80000000, 32'h7FFFFFFF, 32'h0,
                         1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("SLT: Sign Boundary");

        // SLTU: Test comparing maximum unsigned value with zero.
        trans.set_values(9, 11'b00000000000, 32'hFFFFFFFF, 32'h00000000, 32'h0,
                         1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("SLTU: Maximum vs Zero");

        // EQ: Test for equality with identical operands.
        trans.set_values(10, 11'b00000000000, 32'hAAAAAAAA, 32'hAAAAAAAA, 32'h0,
                         1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("EQ: Equal Values");

        // GE: Test equality edge case using equal operands.
        trans.set_values(12, 11'b00000000000, 32'h80000000, 32'h80000000, 32'h0,
                         1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("GE: Equal Values Edge Case");
    endtask

    //-------------------------------------------------------------------------
    // Task: test_memory_scenarios
    // Creates test cases for memory operations (LOAD, STORE) to verify address handling.
    //-------------------------------------------------------------------------
    task test_memory_scenarios();
        // LOAD: Test with properly aligned address.
        trans.set_values(0, `LOAD, 32'h00000004, 32'h0, 32'h00000FFF, 1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("LOAD: Address Alignment Test");

        // STORE: Test with an address at the upper boundary.
        trans.set_values(0, `STORE, 32'hFFFFFFFC, 32'hAAAAAAAA, 32'h0, 1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("STORE: Maximum Address Test");
    endtask

    //-------------------------------------------------------------------------
    // Task: test_branch_scenarios
    // Creates test cases for branch instructions to validate taken and not taken conditions.
    //-------------------------------------------------------------------------
    task test_branch_scenarios();
        // BRANCH: Test scenario where branch condition is met (taken).
        trans.set_values(10, `BRANCH, 32'h00000005, 32'h00000005, 32'h00000100,
                         1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("BRANCH: Taken Condition");

        // BRANCH: Test scenario where branch condition is not met (not taken).
        trans.set_values(10, `BRANCH, 32'h00000005, 32'h00000006, 32'h00000100,
                         1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("BRANCH: Not Taken Condition");
    endtask

    //-------------------------------------------------------------------------
    // Task: test_jump_scenarios
    // Creates test cases for jump instructions (JAL and JALR).
    //-------------------------------------------------------------------------
    task test_jump_scenarios();
        // JAL: Test a forward jump with a large immediate offset.
        trans.set_values(0, `JAL, 32'h00001000, 32'h0, 32'h00000FFF, 1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("JAL: Forward Jump");

        // JALR: Test jump with a return address.
        trans.set_values(0, `JALR, 32'h00000100, 32'h0, 32'h00000004, 1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("JALR: Return Address");
    endtask

    //-------------------------------------------------------------------------
    // Task: test_upper_immediate_scenarios
    // Creates test cases for upper immediate instructions (LUI and AUIPC).
    //-------------------------------------------------------------------------
    task test_upper_immediate_scenarios();
        // LUI: Test using the maximum immediate value.
        trans.set_values(0, `LUI, 32'h0, 32'h0, 32'hFFFFF000, 1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("LUI: Maximum Immediate");

        // AUIPC: Test PC-relative addressing using an upper immediate value.
        trans.set_values(0, `AUIPC, 32'h00001000, 32'h0, 32'h000FF000, 1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("AUIPC: PC-relative Addressing");
    endtask

    //-------------------------------------------------------------------------
    // Task: test_system_and_fence_scenarios
    // Creates test cases for system (CSR) and fence (memory ordering) instructions.
    //-------------------------------------------------------------------------
    task test_system_and_fence_scenarios();
        // SYSTEM: Test a CSR operation (e.g., read/write).
        trans.set_values(0, `SYSTEM, 32'h00000FFF, 32'h0, 32'h00000001, 1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("SYSTEM: CSR Operation");

        // FENCE: Test memory ordering constraints.
        trans.set_values(0, `FENCE, 32'h0, 32'h0, 32'h0, 1'b1);
        gen2drv_mb.put(trans.clone());
        print_scenario("FENCE: Memory Ordering");
    endtask

    //-------------------------------------------------------------------------
    // Function: print_scenario
    // Prints detailed information about a test scenario including operation type,
    // instruction type, operands, immediate value, and expected result.
    //-------------------------------------------------------------------------
    function void print_scenario(string scenario_name);
        alu_operation_e alu_op;
        string          opcode_str;

        // Map the one-hot encoded ALU control signal to its corresponding operation.
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
            default: alu_op = ADD;  // Default to ADD if no match.
        endcase

        // Determine the instruction opcode string.
        case (trans.i_opcode)
            R_TYPE:  opcode_str = "R_TYPE";
            I_TYPE:  opcode_str = "I_TYPE";
            LOAD:    opcode_str = "LOAD";
            STORE:   opcode_str = "STORE";
            BRANCH:  opcode_str = "BRANCH";
            JAL:     opcode_str = "JAL";
            JALR:    opcode_str = "JALR";
            LUI:     opcode_str = "LUI";
            AUIPC:   opcode_str = "AUIPC";
            SYSTEM:  opcode_str = "SYSTEM";
            FENCE:   opcode_str = "FENCE";
            default: opcode_str = "UNKNOWN";
        endcase

        // Display scenario details.

        $display("\n=== %s ===", scenario_name);
        $display("Operation Type: %s", alu_op.name());
        $display("Instruction Type: %s", opcode_str);
        $display("ALU Control: %b", trans.i_alu);
        $display("Opcode: %b", trans.i_opcode);
        $display("RS1: %h (Decimal: %0d)", trans.i_rs1, trans.i_rs1);
        $display("RS2: %h (Decimal: %0d)", trans.i_rs2, trans.i_rs2);
        $display("IMM: %h (Decimal: %0d)", trans.i_imm, trans.i_imm);
        $display("Clock Enable: %b", trans.i_ce);
        $display("Expected Result: %h (Decimal: %0d)", trans.alu_operation(
                 trans.i_rs1, trans.i_rs2, trans.i_imm, trans.i_alu),
                 trans.verify_y);
        $display("--------------------");
    endfunction

endclass
