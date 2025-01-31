module rv32i_alu_tb;

  // Input
  logic i_clk;
  logic i_rst_n;
  logic [`ALU_WIDTH-1:0] i_alu;
  logic [4:0] i_rs1_addr;
  logic [31:0] i_rs1;
  logic [31:0] i_rs2;
  logic [31:0] i_imm;
  logic [2:0] i_funct3;
  logic [`OPCODE_WIDTH-1:0] i_opcode;
  logic [`EXCEPTION_WIDTH-1:0] i_exception;
  logic [31:0] i_pc;
  logic [4:0] i_rd_addr;
  logic i_ce;
  logic i_stall;
  logic i_force_stall;
  logic i_flush;

  // Output signals
  logic [4:0] o_rs1_addr;
  logic [31:0] o_rs1;
  logic [31:0] o_rs2;
  logic [11:0] o_imm;
  logic [2:0] o_funct3;
  logic [`OPCODE_WIDTH-1:0] o_opcode;
  logic [`EXCEPTION_WIDTH-1:0] o_exception;
  logic [31:0] o_y;
  logic [31:0] o_pc;
  logic [31:0] o_next_pc;
  logic o_change_pc;
  logic o_wr_rd;
  logic [4:0] o_rd_addr;
  logic [31:0] o_rd;
  logic o_rd_valid;
  logic o_stall_from_alu;
  logic o_ce;
  logic o_stall;
  logic o_flush;


  alu DUT (
      .i_clk(i_clk),
      .i_rst_n(i_rst_n),
      .i_alu(i_alu),
      .i_rs1_addr(i_rs1_addr),
      .i_rs1(i_rs1),
      .i_rs2(i_rs2),
      .i_imm(i_imm),
      .i_funct3(i_funct3),
      .i_opcode(i_opcode),
      .i_exception(i_exception),
      .i_pc(i_pc),
      .i_rd_addr(i_rd_addr),
      .i_ce(i_ce),
      .i_stall(i_stall),
      .i_force_stall(i_force_stall),
      .i_flush(i_flush),
      .o_rs1_addr(o_rs1_addr),
      .o_rs1(o_rs1),
      .o_rs2(o_rs2),
      .o_imm(o_imm),
      .o_funct3(o_funct3),
      .o_opcode(o_opcode),
      .o_exception(o_exception),
      .o_y(o_y),
      .o_pc(o_pc),
      .o_next_pc(o_next_pc),
      .o_change_pc(o_change_pc),
      .o_wr_rd(o_wr_rd),
      .o_rd_addr(o_rd_addr),
      .o_rd(o_rd),
      .o_rd_valid(o_rd_valid),
      .o_stall_from_alu(o_stall_from_alu),
      .o_ce(o_ce),
      .o_stall(o_stall),
      .o_flush(o_flush)
  );

  // Clock generation
  initial begin
    i_clk = 0;
    forever #5 i_clk = ~i_clk;
  end

  // Initial block
  initial begin

    i_clk = 0;
    i_rst_n = 0;
    i_alu = 0;
    i_rs1_addr = 5'b0;
    i_rs1 = 32'b0;
    i_rs2 = 32'b0;
    i_imm = 32'b0;
    i_funct3 = 3'b0;
    i_opcode = 0;
    i_exception = 0;
    i_pc = 32'b0;
    i_rd_addr = 5'b0;
    i_ce = 1'b1;
    i_stall = 1'b0;
    i_force_stall = 1'b0;
    i_flush = 1'b0;




    // End simulation after testing
    #100 $finish;
  end

endmodule