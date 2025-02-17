`include "transaction.sv"
class generator;
  transaction trans;
  int num_transactions = 20; // Increased number of transactions
  
  function new();
    trans = new();
  endfunction
  
  task generate_scenarios();
    // Predefined scenarios
    generate_predefined_scenarios();
    
    // Random scenarios with different constraint combinations
    generate_random_scenarios();
  endtask

  task generate_predefined_scenarios();
    // Scenario 1: Addition with zero operand
    trans.set_values(0, 3'b000, 4'h5, 4'h0, 1'b1);
    print_scenario("Addition with zero operand");
    
    // Scenario 2: Subtraction with negative result
    trans.set_values(1, 3'b001, 4'h3, 4'h8, 1'b1);
    print_scenario("Subtraction with negative result");
    
    // Scenario 3: Maximum value addition
    trans.set_values(0, 3'b000, 4'hF, 4'hF, 1'b1);
    print_scenario("Maximum value addition");
    
    // Scenario 4: Subtraction with same operands
    trans.set_values(1, 3'b001, 4'h7, 4'h7, 1'b1);
    print_scenario("Subtraction with same operands");
    
    // Scenario 5: Edge case - all zeros
    trans.set_values(0, 3'b000, 4'h0, 4'h0, 1'b1);
    print_scenario("Edge case - all zeros");
  endtask

  task generate_random_scenarios();
    for(int i = 0; i < num_transactions; i++) begin
      // Disable all special constraints initially
      trans.zero_operand_c.constraint_mode(0);
      trans.max_value_c.constraint_mode(0);
      trans.negative_result_c.constraint_mode(0);

      // Enable different constraint combinations based on iteration
      case(i % 4)
        0: trans.zero_operand_c.constraint_mode(1);      // Zero operand cases
        1: trans.max_value_c.constraint_mode(1);         // Maximum value cases
        2: trans.negative_result_c.constraint_mode(1);   // Negative result cases
        3: begin end // Fully random case, no special constraints
      endcase

      void'(trans.randomize());
      print_scenario($sformatf("Random Scenario %0d", i));
    end
  endtask
  
  function void print_scenario(string scenario_name);
    $display("\n=== %s ===", scenario_name);
    $display("ALU Control: %b", trans.i_alu);
    $display("Opcode: %b", trans.i_opcode);
    $display("RS1: %h (Decimal: %0d)", trans.i_rs1, trans.i_rs1);
    $display("IMM: %h (Decimal: %0d)", trans.i_imm, trans.i_imm);
    $display("Clock Enable: %b", trans.i_ce);
    $display("Expected Result: %h (Decimal: %0d)", 
             trans.alu_operation(trans.i_rs1, trans.i_imm, trans.i_alu),
             trans.verify_y);
    $display("--------------------");
  endfunction
endclass

