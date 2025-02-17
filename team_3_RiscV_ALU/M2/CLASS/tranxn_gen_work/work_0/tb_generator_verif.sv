`include "generator.sv"

module tb_generator_verif;
  // Declare generator instance and mailbox
  generator gen;
  mailbox #(transaction) gen2drv_mb;
  
  initial begin
    // Create mailbox first
    gen2drv_mb = new();
    
    // Create generator instance with mailbox
    gen = new(gen2drv_mb);
    
    // Generate and print test scenarios
    gen.generate_scenarios();
    
    // Wait for generation to complete
    @(gen.generation_complete);
    
    // Print summary
    $display("\n=== Generator Test Complete ===");
    $display("Predefined Scenarios: 5");
    $display("Random Scenarios: %0d", gen.num_transactions);
    $display("===========================\n");
    
    // End simulation
    #100 $finish;
  end
  
endmodule
