`include "generator.sv"
module tb_alu_stimulus;
  generator gen;

  initial begin
    // Create generator instance
    gen = new();
    
    // Generate and print test scenarios
    gen.generate_scenarios();
    
    // End simulation
    #10 $finish;
  end
endmodule

