`include "transaction.sv"

// First, define a typedef for the mailbox
typedef mailbox #(transaction) mail_box;

class generator;
  transaction trans;
  mail_box gen2drv_mb;  // Mailbox to communicate with driver
  int num_transactions = 20;
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
    
    // Scenario 1: Addition with zero operand
    trans.set_values(0, 3'b000, 4'h5, 4'h0, 1'b1);
    trans_clone = trans.clone();  // Create a clone of the transaction
    gen2drv_mb.put(trans_clone);  // Put into mailbox
    print_scenario("Addition with zero operand");
    
    // Scenario 2: Subtraction with negative result
    trans.set_values(1, 3'b001, 4'h3, 4'h8, 1'b1);
    trans_clone = trans.clone();
    gen2drv_mb.put(trans_clone);
    print_scenario("Subtraction with negative result");
    
    // Scenario 3: Maximum value addition
    trans.set_values(0, 3'b000, 4'hF, 4'hF, 1'b1);
    trans_clone = trans.clone();
    gen2drv_mb.put(trans_clone);
    print_scenario("Maximum value addition");
    
    // Scenario 4: Subtraction with same operands
    trans.set_values(1, 3'b001, 4'h7, 4'h7, 1'b1);
    trans_clone = trans.clone();
    gen2drv_mb.put(trans_clone);
    print_scenario("Subtraction with same operands");
    
    // Scenario 5: Edge case - all zeros
    trans.set_values(0, 3'b000, 4'h0, 4'h0, 1'b1);
    trans_clone = trans.clone();
    gen2drv_mb.put(trans_clone);
    print_scenario("Edge case - all zeros");
  endtask

  task generate_random_scenarios();
    transaction trans_clone;
    
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
      trans_clone = trans.clone();  // Create a clone of the transaction
      gen2drv_mb.put(trans_clone);  // Put into mailbox
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
