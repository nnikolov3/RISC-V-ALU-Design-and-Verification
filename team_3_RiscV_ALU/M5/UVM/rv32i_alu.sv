
/*
ECE593: Milestone 4, Group 3
Original: https://github.com/AngeloJacobo/RISC-V/blob/main/rtl/
#Design:
**Operand Selection**:
    * Chooses between PC or rs1 for Operand A.
    * Selects either rs2 or an immediate value for Operand B based on the opcode.
**ALU Operations**:
    * Executes operations like ADD, SUB, SLT, SLTU, XOR, OR, AND, SLL, SRL, SRA, EQ, NEQ, GE, and GEU.
    * Stores the result in the y_d register.
**Branch and Jump Handling**:
    * Calculates next PC for branches and jumps.
    * Uses o_change_pc to signal a need for PC change.
**Register Writeback**:
    * Computes value for destination register rd.
    * Manages writeback with o_wr_rd and o_rd_valid signals, disabling write for branches or stores.
**Pipeline Management**:
    * Stalling: Uses o_stall_from_alu to pause the memory-access stage for operations like load/store.
    * Flushing: Responds to i_stall, i_force_stall, and i_flush signals to manage pipeline flow.
Summary:
    The rv32i_alu module in the RISC-V core's execute stage selects operands, performs arithmetic,
    logical, and comparison operations, manages branch/jump instructions,
    handles register writeback, and controls pipeline flow through stalling,
    and flushing based on the current instruction.
*/
`timescale 1ns / 1ps `default_nettype none
`include "rv32i_alu_header.sv"
`include "uvm_macros.svh"
import uvm_pkg::*;
module rv32i_alu (
    i_clk,
    i_rst_n,
    i_alu,
    i_rs1_addr,
    i_rs1,
    i_rs2,
    i_imm,
    i_funct3,
    i_opcode,
    i_exception,
    i_pc,
    i_rd_addr,
    i_ce,
    i_stall,
    i_force_stall,
    i_flush,
    o_rs1_addr,
    o_rs1,
    o_rs2,
    o_imm,
    o_funct3,
    o_opcode,
    o_exception,
    o_y,
    o_pc,
    o_next_pc,
    o_change_pc,
    o_wr_rd,
    o_rd_addr,
    o_rd,
    o_rd_valid,
    o_stall_from_alu,
    o_ce,
    o_stall,
    o_flush
);
  input logic i_clk, i_rst_n;
  input logic [`ALU_WIDTH-1:0] i_alu;  //alu operation type from previous stage
  input logic [4:0] i_rs1_addr;  //address for logicister source 1
  input logic [31:0] i_rs1;  // Source logicister 1 value
  input logic [31:0] i_rs2;  //Source logicister 2 value
  input logic [31:0] i_imm;  //Immediate value from previous stage
  input logic [2:0] i_funct3;  //function type from previous stage
  input logic [`OPCODE_WIDTH-1:0] i_opcode;  //opcode type from previous stage
  input logic [`EXCEPTION_WIDTH-1:0] i_exception;  //exception from decoder stage
  input logic [31:0] i_pc;  //Program Counter
  input logic [4:0] i_rd_addr;  //address for destination logicister (from previous stage)
  input logic i_ce;  // input clk enable for pipeline stalling of this stage
  // coverage off
  input logic i_stall;  //informs this stage to stall
  input logic i_force_stall;  //force this stage to stall
  input logic i_flush;  //flush this stage
  // coverage on
  output logic [4:0] o_rs1_addr;  //address for logicister source 1
  output logic [31:0] o_rs1;  //Source logicister 1 value
  output logic [31:0] o_rs2;  //Source logicister 2 value
  output logic [11:0] o_imm;  //Immediate value
  output logic [2:0] o_funct3;  // function type
  output logic [`OPCODE_WIDTH-1:0] o_opcode;  //opcode type
  output logic [`EXCEPTION_WIDTH-1:0] o_exception;  //exception: illegal inst,ecall,ebreak,mret
  output logic [31:0] o_y;  //result of arithmetic operation
  output logic [31:0] o_pc;  //pc logicister in pipeline
  output logic [31:0] o_next_pc;  //new pc value
  output logic o_change_pc;  //high if PC needs to jump
  output logic o_wr_rd;  //write rd to the base logic if enabled
  output logic [4:0] o_rd_addr;  //address for destination logicister
  output logic [31:0] o_rd;  //value to be written back to destination logicister
  output logic o_rd_valid;  //high if o_rd is valid (not load nor csr instruction)
  // coverage off
  output logic o_stall_from_alu
        ;  //prepare to stall next stage(memory-access stage) for load/store instruction
  // coverage on
  output logic o_ce;  // output clk enable for pipeline stalling of next stage
  // coverage off
  output logic o_stall;  //informs pipeline to stall
  output logic o_flush;  //flush previous stages
  // coverage on
  // Internal signals
  logic        alu_add;
  logic        alu_sub;
  logic        alu_slt;
  logic        alu_sltu;
  logic        alu_xor;
  logic        alu_or;
  logic        alu_and;
  logic        alu_sll;
  logic        alu_srl;
  logic        alu_sra;
  logic        alu_eq;
  logic        alu_neq;
  logic        alu_ge;
  logic        alu_geu;
  logic        opcode_rtype;
  logic        opcode_itype;
  // coverage off
  logic        opcode_load;
  logic        opcode_store;
  logic        opcode_branch;
  logic        opcode_jal;
  logic        opcode_jalr;
  logic        opcode_lui;
  logic        opcode_auipc;
  logic        opcode_system;
  logic        opcode_fence;
  // coverage on
  logic [31:0] a;  //operand A
  logic [31:0] b;  //operand B
  logic [31:0] y_d;  //ALU output
  logic [31:0] rd_d;  //next value to be written back to destination logicister
  logic        wr_rd_d;  //write rd to baselogic if enabled
  logic        rd_valid_d;  //high if rd is valid (not load nor csr instruction)
  logic [31:0] a_pc;
  logic [31:0] sum;
  // coverage off
  logic        stall_bit;
  // coverage on
  //logicister the output of i_alu
  always_ff @(posedge i_clk, negedge i_rst_n) begin
    if (!i_rst_n) begin
      o_exception      <= 0;
      o_ce             <= 0;
      o_stall_from_alu <= 0;
    end else begin
      // coverage off -item c 1
      if (i_ce && !stall_bit) begin  //update logicister only if this stage is enabled
        o_opcode <= i_opcode;
        o_exception <= i_exception;
        o_y <= y_d;
        o_rs1_addr <= i_rs1_addr;
        o_rs1 <= i_rs1;
        o_rs2 <= i_rs2;
        o_rd_addr <= i_rd_addr;
        o_imm <= i_imm[11:0];
        o_funct3 <= i_funct3;
        o_rd <= rd_d;
        o_rd_valid <= rd_valid_d;
        o_wr_rd <= wr_rd_d;
        // coverage off
        o_stall_from_alu <= i_opcode[`STORE] || i_opcode[`LOAD]
                    ;  //stall next stage(memory-access stage) when need to store/load
        // coverage on
        o_pc <= i_pc;  //since accessing data memory always takes more than 1 cycle
      end
      // coverage off
      if (i_flush && !stall_bit) begin  //flush this stage so clock-enable of next stage is disabled at next clock cycle
        o_ce <= 0;
        // coverage on
      end else if (!stall_bit) begin  //clock-enable will change only when not stalled
        o_ce <= i_ce;
        // coverage off
      end else if (stall_bit && !i_stall)
        o_ce <= 0;  //if this stage is stalled but next stage is not, disable
      // coverage on
      //clock enable of next stage at next clock cycle (pipeline bubble)
    end
  end
  // determine operation used then compute for y output

  always_comb begin
    y_d = 0;
    // coverage off
    a   = (opcode_jal || opcode_auipc) ? i_pc : i_rs1;  // a can either be pc or rs1
    // coverage on
    // coverage off -item c 1
    b   = (opcode_rtype || opcode_branch) ? i_rs2 : i_imm;  // b can either be rs2 or imm
    if (alu_add) y_d = a + b;
    if (alu_sub) y_d = a - b;
    if (alu_slt || alu_sltu) begin
      y_d = {31'b0, (a < b)};
      if (alu_slt) y_d = (a[31] ^ b[31]) ? {31'b0, a[31]} : y_d;
    end
    if (alu_xor) y_d = a ^ b;
    if (alu_or) y_d = a | b;
    if (alu_and) y_d = a & b;
    if (alu_sll) y_d = a << b[4:0];
    if (alu_srl) y_d = a >> b[4:0];
    if (alu_sra) y_d = $signed(a) >>> b[4:0];
    if (alu_eq || alu_neq) begin
      y_d = {31'b0, (a == b)};
      if (alu_neq) y_d = {31'b0, !y_d[0]};
    end
    if (alu_ge || alu_geu) begin
      y_d = {31'b0, (a >= b)};
      if (alu_ge) y_d = (a[31] ^ b[31]) ? {31'b0, b[31]} : y_d;
    end
  end
  //determine o_rd to be saved to baseg and next value of PC
  always_comb begin
    o_flush     = i_flush;  //flush this stage along with the previous stages
    rd_d        = 0;
    rd_valid_d  = 0;
    o_change_pc = 0;
    o_next_pc   = 0;
    wr_rd_d     = 0;
    a_pc        = i_pc;
    if (!i_flush) begin
      if (opcode_rtype || opcode_itype) rd_d = y_d;
      // coverage off
      if (opcode_branch && y_d[0]) begin
        o_next_pc = sum;  //branch iff value of ALU is 1(true)
        o_change_pc = i_ce;  //change PC when ce of this stage is high (o_change_pc is valid)
        o_flush = i_ce;
      end
      if (opcode_jal || opcode_jalr) begin
        if (opcode_jalr) a_pc = i_rs1;
        o_next_pc = sum;  //jump to new PC
        o_change_pc = i_ce;  //change PC when ce of this stage is high (o_change_pc is valid)
        o_flush = i_ce;
        rd_d = i_pc + 4;  //logicister the next pc value to destination logicister
      end
      // coverage on
    end
    // coverage off
    if (opcode_lui) rd_d = i_imm;
    if (opcode_auipc) rd_d = sum;
    if (opcode_branch || opcode_store || (opcode_system && i_funct3 == 0) || opcode_fence)
      wr_rd_d = 0;  //i_funct3==0 are the non-csr system instructions
    else
      wr_rd_d = 1;  //always write to the destination logic except when instruction is BRANCH or STORE or SYSTEM(except CSR system instruction)
    if (opcode_load || (opcode_system && i_funct3 != 0))
      rd_valid_d = 0;  //value of o_rd for load and CSR write is not yet available at this stage
    else rd_valid_d = 1;
    // coverage on
    //stall logic (stall when upper stages are stalled, when forced to stall, or when needs to flush previous stages but are still stalled)
    o_stall = (i_stall || i_force_stall) && !i_flush;  //stall when alu needs wait time
  end

  assign sum = a_pc + i_imm;  //share adder for all addition operation for less resource utilization
  assign stall_bit = o_stall || i_stall;
  assign alu_add = i_alu[`ADD];
  assign alu_sub = i_alu[`SUB];
  assign alu_slt = i_alu[`SLT];
  assign alu_sltu = i_alu[`SLTU];
  assign alu_xor = i_alu[`XOR];
  assign alu_or = i_alu[`OR];
  assign alu_and = i_alu[`AND];
  assign alu_sll = i_alu[`SLL];
  assign alu_srl = i_alu[`SRL];
  assign alu_sra = i_alu[`SRA];
  assign alu_eq = i_alu[`EQ];
  assign alu_neq = i_alu[`NEQ];
  assign alu_ge = i_alu[`GE];
  assign alu_geu = i_alu[`GEU];
  assign opcode_rtype = i_opcode[`RTYPE];
  assign opcode_itype = i_opcode[`ITYPE];
  assign opcode_load = i_opcode[`LOAD];
  assign opcode_store = i_opcode[`STORE];
  assign opcode_branch = i_opcode[`BRANCH];
  assign opcode_jal = i_opcode[`JAL];
  assign opcode_jalr = i_opcode[`JALR];
  assign opcode_lui = i_opcode[`LUI];
  assign opcode_auipc = i_opcode[`AUIPC];
  assign opcode_system = i_opcode[`SYSTEM];
  assign opcode_fence = i_opcode[`FENCE];
`ifdef FORMAL
  // assumption on inputs(not more than one opcode and alu operation is high)
  logic [4:0] f_alu = i_alu[`ADD] + i_alu[`SUB] + i_alu[`SLT] + i_alu[`SLTU] + i_alu[`XOR] +
        i_alu[`OR] + i_alu[`AND] + i_alu[`SLL] + i_alu[`SRL] + i_alu[`SRA] + i_alu[`EQ] +
        i_alu[`NEQ] + i_alu[`GE] + i_alu[`GEU] + 0;
  logic [4:0] f_opcode = i_opcode[`RTYPE] + i_opcode[`ITYPE] + i_opcode[`LOAD] +
        i_opcode[`STORE] + i_opcode[`BRANCH] + i_opcode[`JAL] + i_opcode[`JALR] + i_opcode[`LUI] +
        i_opcode[`AUIPC] + i_opcode[`SYSTEM] + i_opcode[`FENCE];
  always_comb begin
    assume (f_alu <= 1);
    assume (f_opcode <= 1);
  end
  // verify all operations with $signed/$unsigned distinctions
  always_comb begin
    if (i_alu[`SLTU]) assert (y_d[0] == $unsigned(a) < $unsigned(b));
    if (i_alu[`SLT]) assert (y_d[0] == $signed(a) < $signed(b));
    if (i_alu[`SLL]) assert ($unsigned(y_d) == $unsigned(a) << $unsigned(b[4:0]));
    if (i_alu[`SRL]) assert ($unsigned(y_d) == $unsigned(a) >> $unsigned(b[4:0]));
    if (i_alu[`SRA]) assert ($signed(y_d) == ($signed(a) >>> $unsigned(b[4:0])));
    if (i_alu[`GEU]) assert (y_d[0] == ($unsigned(a) >= $unsigned(b)));
    if (i_alu[`GE]) assert (y_d[0] == ($signed(a) >= $signed(b)));
  end
`endif
endmodule


module rv32i_alu2 (
    i_clk,
    i_rst_n,
    i_alu,
    i_rs1_addr,
    i_rs1,
    i_rs2,
    i_imm,
    i_funct3,
    i_opcode,
    i_exception,
    i_pc,
    i_rd_addr,
    i_ce,
    i_stall,
    i_force_stall,
    i_flush,
    o_rs1_addr,
    o_rs1,
    o_rs2,
    o_imm,
    o_funct3,
    o_opcode,
    o_exception,
    o_y,
    o_pc,
    o_next_pc,
    o_change_pc,
    o_wr_rd,
    o_rd_addr,
    o_rd,
    o_rd_valid,
    o_stall_from_alu,
    o_ce,
    o_stall,
    o_flush
);
  input logic i_clk, i_rst_n;
  input logic [`ALU_WIDTH-1:0] i_alu;  //alu operation type from previous stage
  input logic [4:0] i_rs1_addr;  //address for logicister source 1
  input logic [31:0] i_rs1;  // Source logicister 1 value
  input logic [31:0] i_rs2;  //Source logicister 2 value
  input logic [31:0] i_imm;  //Immediate value from previous stage
  input logic [2:0] i_funct3;  //function type from previous stage
  input logic [`OPCODE_WIDTH-1:0] i_opcode;  //opcode type from previous stage
  input logic [`EXCEPTION_WIDTH-1:0] i_exception;  //exception from decoder stage
  input logic [31:0] i_pc;  //Program Counter
  input logic [4:0] i_rd_addr;  //address for destination logicister (from previous stage)
  input logic i_ce;  // input clk enable for pipeline stalling of this stage
  input logic i_stall;  //informs this stage to stall
  input logic i_force_stall;  //force this stage to stall
  input logic i_flush;  //flush this stage
  output logic [4:0] o_rs1_addr;  //address for logicister source 1
  output logic [31:0] o_rs1;  //Source logicister 1 value
  output logic [31:0] o_rs2;  //Source logicister 2 value
  output logic [11:0] o_imm;  //Immediate value
  output logic [2:0] o_funct3;  // function type
  output logic [`OPCODE_WIDTH-1:0] o_opcode;  //opcode type
  output logic [`EXCEPTION_WIDTH-1:0] o_exception;  //exception: illegal inst,ecall,ebreak,mret
  output logic [31:0] o_y;  //result of arithmetic operation
  output logic [31:0] o_pc;  //pc logicister in pipeline
  output logic [31:0] o_next_pc;  //new pc value
  output logic o_change_pc;  //high if PC needs to jump
  output logic o_wr_rd;  //write rd to the base logic if enabled
  output logic [4:0] o_rd_addr;  //address for destination logicister
  output logic [31:0] o_rd;  //value to be written back to destination logicister
  output logic o_rd_valid;  //high if o_rd is valid (not load nor csr instruction)
  output logic o_stall_from_alu
        ;  //prepare to stall next stage(memory-access stage) for load/store instruction
  output logic o_ce;  // output clk enable for pipeline stalling of next stage
  output logic o_stall;  //informs pipeline to stall
  output logic o_flush;  //flush previous stages
  // Internal signals
  logic        alu_add;
  logic        alu_sub;
  logic        alu_slt;
  logic        alu_sltu;
  logic        alu_xor;
  logic        alu_or;
  logic        alu_and;
  logic        alu_sll;
  logic        alu_srl;
  logic        alu_sra;
  logic        alu_eq;
  logic        alu_neq;
  logic        alu_ge;
  logic        alu_geu;
  logic        opcode_rtype;
  logic        opcode_itype;
  logic        opcode_load;
  logic        opcode_store;
  logic        opcode_branch;
  logic        opcode_jal;
  logic        opcode_jalr;
  logic        opcode_lui;
  logic        opcode_auipc;
  logic        opcode_system;
  logic        opcode_fence;
  logic [31:0] a;  //operand A
  logic [31:0] b;  //operand B
  logic [31:0] y_d;  //ALU output
  logic [31:0] rd_d;  //next value to be written back to destination logicister
  logic        wr_rd_d;  //write rd to baselogic if enabled
  logic        rd_valid_d;  //high if rd is valid (not load nor csr instruction)
  logic [31:0] a_pc;
  logic [31:0] sum;
  logic        stall_bit;
  //logicister the output of i_alu
  always_ff @(posedge i_clk, negedge i_rst_n) begin
    if (!i_rst_n) begin
      o_exception      <= 0;
      o_ce             <= 0;
      o_stall_from_alu <= 0;
    end else begin
      if (i_ce && !stall_bit) begin  //update logicister only if this stage is enabled
        o_opcode <= i_opcode;
        o_exception <= i_exception;
        o_y <= y_d;
        o_rs1_addr <= i_rs1_addr;
        o_rs1 <= i_rs1;
        o_rs2 <= i_rs2;
        o_rd_addr <= i_rd_addr;
        o_imm <= i_imm[11:0];
        o_funct3 <= i_funct3;
        o_rd <= rd_d;
        o_rd_valid <= rd_valid_d;
        o_wr_rd <= wr_rd_d;
        o_stall_from_alu <= i_opcode[`STORE] || i_opcode[`LOAD]
                    ;  //stall next stage(memory-access stage) when need to store/load
        o_pc <= i_pc;  //since accessing data memory always takes more than 1 cycle
      end
      if (i_flush && !stall_bit) begin  //flush this stage so clock-enable of next stage is disabled at next clock cycle
        o_ce <= 0;
      end else if (!stall_bit) begin  //clock-enable will change only when not stalled
        o_ce <= i_ce;
      end else if (stall_bit && !i_stall)
        o_ce <= 0;  //if this stage is stalled but next stage is not, disable
      //clock enable of next stage at next clock cycle (pipeline bubble)
    end
  end
  // determine operation used then compute for y output

  always_comb begin
    y_d = 0;
    a   = (opcode_jal || opcode_auipc) ? i_pc : i_rs1;  // a can either be pc or rs1
    b   = (opcode_rtype || opcode_branch) ? i_rs2 : i_imm;  // b can either be rs2 or imm
    if (alu_add) y_d = a + b;
    if (alu_sub) y_d = a + b;
    if (alu_slt || alu_sltu) begin
      y_d = {31'b0, (a < b)};
      if (alu_slt) y_d = (a[31] ^ b[31]) ? {31'b0, a[31]} : y_d;
    end
    if (alu_xor) y_d = a ^ b;
    if (alu_or) y_d = a | b;
    if (alu_and) y_d = a & b;
    if (alu_sll) y_d = a << b[4:0];
    if (alu_srl) y_d = a >> b[4:0];
    if (alu_sra) y_d = $signed(a) >>> b[4:0];
    if (alu_eq || alu_neq) begin
      y_d = {31'b0, (a == b)};
      if (alu_neq) y_d = {31'b0, !y_d[0]};
    end
    if (alu_ge || alu_geu) begin
      y_d = {31'b0, (a >= b)};
      if (alu_ge) y_d = (a[31] ^ b[31]) ? {31'b0, b[31]} : y_d;
    end
  end

  //determine o_rd to be saved to baseg and next value of PC
  always_comb begin
    o_flush     = i_flush;  //flush this stage along with the previous stages
    rd_d        = 0;
    rd_valid_d  = 0;
    o_change_pc = 0;
    o_next_pc   = 0;
    wr_rd_d     = 0;
    a_pc        = i_pc;
    if (!i_flush) begin
      if (opcode_rtype || opcode_itype) rd_d = y_d;
      if (opcode_branch && y_d[0]) begin
        o_next_pc = sum;  //branch iff value of ALU is 1(true)
        o_change_pc = i_ce;  //change PC when ce of this stage is high (o_change_pc is valid)
        o_flush = i_ce;
      end
      if (opcode_jal || opcode_jalr) begin
        if (opcode_jalr) a_pc = i_rs1;
        o_next_pc = sum;  //jump to new PC
        o_change_pc = i_ce;  //change PC when ce of this stage is high (o_change_pc is valid)
        o_flush = i_ce;
        rd_d = i_pc + 4;  //logicister the next pc value to destination logicister
      end
    end
    if (opcode_lui) rd_d = i_imm;
    if (opcode_auipc) rd_d = sum;
    if (opcode_branch || opcode_store || (opcode_system && i_funct3 == 0) || opcode_fence)
      wr_rd_d = 0;  //i_funct3==0 are the non-csr system instructions
    else
      wr_rd_d = 1;  //always write to the destination logic except when instruction is BRANCH or STORE or SYSTEM(except CSR system instruction)
    if (opcode_load || (opcode_system && i_funct3 != 0))
      rd_valid_d = 0;  //value of o_rd for load and CSR write is not yet available at this stage
    else rd_valid_d = 1;
    //stall logic (stall when upper stages are stalled, when forced to stall, or when needs to flush previous stages but are still stalled)
    o_stall = (i_stall || i_force_stall) && !i_flush;  //stall when alu needs wait time
  end
  assign sum = a_pc + i_imm;  //share adder for all addition operation for less resource utilization
  assign stall_bit = o_stall || i_stall;
  assign alu_add = i_alu[`ADD];
  assign alu_sub = i_alu[`SUB];
  assign alu_slt = i_alu[`SLT];
  assign alu_sltu = i_alu[`SLTU];
  assign alu_xor = i_alu[`XOR];
  assign alu_or = i_alu[`OR];
  assign alu_and = i_alu[`AND];
  assign alu_sll = i_alu[`SLL];
  assign alu_srl = i_alu[`SRL];
  assign alu_sra = i_alu[`SRA];
  assign alu_eq = i_alu[`EQ];
  assign alu_neq = i_alu[`NEQ];
  assign alu_ge = i_alu[`GE];
  assign alu_geu = i_alu[`GEU];
  assign opcode_rtype = i_opcode[`RTYPE];
  assign opcode_itype = i_opcode[`ITYPE];
  assign opcode_load = i_opcode[`LOAD];
  assign opcode_store = i_opcode[`STORE];
  assign opcode_branch = i_opcode[`BRANCH];
  assign opcode_jal = i_opcode[`JAL];
  assign opcode_jalr = i_opcode[`JALR];
  assign opcode_lui = i_opcode[`LUI];
  assign opcode_auipc = i_opcode[`AUIPC];
  assign opcode_system = i_opcode[`SYSTEM];
  assign opcode_fence = i_opcode[`FENCE];


`ifdef FORMAL
  // assumption on inputs(not more than one opcode and alu operation is high)
  logic [4:0] f_alu = i_alu[`ADD] + i_alu[`SUB] + i_alu[`SLT] + i_alu[`SLTU] + i_alu[`XOR] +
        i_alu[`OR] + i_alu[`AND] + i_alu[`SLL] + i_alu[`SRL] + i_alu[`SRA] + i_alu[`EQ] +
        i_alu[`NEQ] + i_alu[`GE] + i_alu[`GEU] + 0;
  logic [4:0] f_opcode = i_opcode[`RTYPE] + i_opcode[`ITYPE] + i_opcode[`LOAD] +
        i_opcode[`STORE] + i_opcode[`BRANCH] + i_opcode[`JAL] + i_opcode[`JALR] + i_opcode[`LUI] +
        i_opcode[`AUIPC] + i_opcode[`SYSTEM] + i_opcode[`FENCE];
  always_comb begin
    assume (f_alu <= 1);
    assume (f_opcode <= 1);
  end
  // verify all operations with $signed/$unsigned distinctions
  always_comb begin
    if (i_alu[`SLTU]) assert (y_d[0] == $unsigned(a) < $unsigned(b));
    if (i_alu[`SLT]) assert (y_d[0] == $signed(a) < $signed(b));
    if (i_alu[`SLL]) assert ($unsigned(y_d) == $unsigned(a) << $unsigned(b[4:0]));
    if (i_alu[`SRL]) assert ($unsigned(y_d) == $unsigned(a) >> $unsigned(b[4:0]));
    if (i_alu[`SRA]) assert ($signed(y_d) == ($signed(a) >>> $unsigned(b[4:0])));
    if (i_alu[`GEU]) assert (y_d[0] == ($unsigned(a) >= $unsigned(b)));
    if (i_alu[`GE]) assert (y_d[0] == ($signed(a) >= $signed(b)));
  end
`endif
endmodule

module rv32i_alu3 (
    i_clk,
    i_rst_n,
    i_alu,
    i_rs1_addr,
    i_rs1,
    i_rs2,
    i_imm,
    i_funct3,
    i_opcode,
    i_exception,
    i_pc,
    i_rd_addr,
    i_ce,
    i_stall,
    i_force_stall,
    i_flush,
    o_rs1_addr,
    o_rs1,
    o_rs2,
    o_imm,
    o_funct3,
    o_opcode,
    o_exception,
    o_y,
    o_pc,
    o_next_pc,
    o_change_pc,
    o_wr_rd,
    o_rd_addr,
    o_rd,
    o_rd_valid,
    o_stall_from_alu,
    o_ce,
    o_stall,
    o_flush
);
  input logic i_clk, i_rst_n;
  input logic [`ALU_WIDTH-1:0] i_alu;  //alu operation type from previous stage
  input logic [4:0] i_rs1_addr;  //address for logicister source 1
  input logic [31:0] i_rs1;  // Source logicister 1 value
  input logic [31:0] i_rs2;  //Source logicister 2 value
  input logic [31:0] i_imm;  //Immediate value from previous stage
  input logic [2:0] i_funct3;  //function type from previous stage
  input logic [`OPCODE_WIDTH-1:0] i_opcode;  //opcode type from previous stage
  input logic [`EXCEPTION_WIDTH-1:0] i_exception;  //exception from decoder stage
  input logic [31:0] i_pc;  //Program Counter
  input logic [4:0] i_rd_addr;  //address for destination logicister (from previous stage)
  input logic i_ce;  // input clk enable for pipeline stalling of this stage
  input logic i_stall;  //informs this stage to stall
  input logic i_force_stall;  //force this stage to stall
  input logic i_flush;  //flush this stage
  output logic [4:0] o_rs1_addr;  //address for logicister source 1
  output logic [31:0] o_rs1;  //Source logicister 1 value
  output logic [31:0] o_rs2;  //Source logicister 2 value
  output logic [11:0] o_imm;  //Immediate value
  output logic [2:0] o_funct3;  // function type
  output logic [`OPCODE_WIDTH-1:0] o_opcode;  //opcode type
  output logic [`EXCEPTION_WIDTH-1:0] o_exception;  //exception: illegal inst,ecall,ebreak,mret
  output logic [31:0] o_y;  //result of arithmetic operation
  output logic [31:0] o_pc;  //pc logicister in pipeline
  output logic [31:0] o_next_pc;  //new pc value
  output logic o_change_pc;  //high if PC needs to jump
  output logic o_wr_rd;  //write rd to the base logic if enabled
  output logic [4:0] o_rd_addr;  //address for destination logicister
  output logic [31:0] o_rd;  //value to be written back to destination logicister
  output logic o_rd_valid;  //high if o_rd is valid (not load nor csr instruction)
  output logic o_stall_from_alu
        ;  //prepare to stall next stage(memory-access stage) for load/store instruction
  output logic o_ce;  // output clk enable for pipeline stalling of next stage
  output logic o_stall;  //informs pipeline to stall
  output logic o_flush;  //flush previous stages
  // Internal signals
  logic        alu_add;
  logic        alu_sub;
  logic        alu_slt;
  logic        alu_sltu;
  logic        alu_xor;
  logic        alu_or;
  logic        alu_and;
  logic        alu_sll;
  logic        alu_srl;
  logic        alu_sra;
  logic        alu_eq;
  logic        alu_neq;
  logic        alu_ge;
  logic        alu_geu;
  logic        opcode_rtype;
  logic        opcode_itype;
  logic        opcode_load;
  logic        opcode_store;
  logic        opcode_branch;
  logic        opcode_jal;
  logic        opcode_jalr;
  logic        opcode_lui;
  logic        opcode_auipc;
  logic        opcode_system;
  logic        opcode_fence;
  logic [31:0] a;  //operand A
  logic [31:0] b;  //operand B
  logic [31:0] y_d;  //ALU output
  logic [31:0] rd_d;  //next value to be written back to destination logicister
  logic        wr_rd_d;  //write rd to baselogic if enabled
  logic        rd_valid_d;  //high if rd is valid (not load nor csr instruction)
  logic [31:0] a_pc;
  logic [31:0] sum;
  logic        stall_bit;
  //logicister the output of i_alu
  always_ff @(posedge i_clk, negedge i_rst_n) begin
    if (!i_rst_n) begin
      o_exception      <= 0;
      o_ce             <= 0;
      o_stall_from_alu <= 0;
    end else begin
      if (i_ce && !stall_bit) begin  //update logicister only if this stage is enabled
        o_opcode <= i_opcode;
        o_exception <= i_exception;
        o_y <= y_d;
        o_rs1_addr <= i_rs1_addr;
        o_rs1 <= i_rs1;
        o_rs2 <= i_rs2;
        o_rd_addr <= i_rd_addr;
        o_imm <= i_imm[11:0];
        o_funct3 <= i_funct3;
        o_rd <= rd_d;
        o_rd_valid <= rd_valid_d;
        o_wr_rd <= wr_rd_d;
        o_stall_from_alu <= i_opcode[`STORE] || i_opcode[`LOAD]
                    ;  //stall next stage(memory-access stage) when need to store/load
        o_pc <= i_pc;  //since accessing data memory always takes more than 1 cycle
      end
      if (i_flush && !stall_bit) begin  //flush this stage so clock-enable of next stage is disabled at next clock cycle
        o_ce <= 0;
      end else if (!stall_bit) begin  //clock-enable will change only when not stalled
        o_ce <= i_ce;
      end else if (stall_bit && !i_stall)
        o_ce <= 0;  //if this stage is stalled but next stage is not, disable
      //clock enable of next stage at next clock cycle (pipeline bubble)
    end
  end
  // determine operation used then compute for y output
  always_comb begin
    y_d = 0;
    a   = (opcode_jal || opcode_auipc) ? i_pc : i_rs1;  // a can either be pc or rs1
    b   = (opcode_rtype || opcode_branch) ? i_rs2 : i_imm;  // b can either be rs2 or imm
    if (alu_add) y_d = a + b;
    if (alu_sub) y_d = a - b;
    if (alu_slt || alu_sltu) begin
      y_d = {31'b0, (a > b)};
      if (alu_slt) y_d = (a[31] ^ b[31]) ? {31'b0, a[31]} : y_d;
    end
    if (alu_xor) y_d = a ^ b;
    if (alu_or) y_d = a | b;
    if (alu_and) y_d = a & b;
    if (alu_sll) y_d = a << b[4:0];
    if (alu_srl) y_d = a >> b[4:0];
    if (alu_sra) y_d = $signed(a) >>> b[4:0];
    if (alu_eq || alu_neq) begin
      y_d = {31'b0, (a == b)};
      if (alu_neq) y_d = {31'b0, !y_d[0]};
    end
    if (alu_ge || alu_geu) begin
      y_d = {31'b0, (a >= b)};
      if (alu_ge) y_d = (a[31] ^ b[31]) ? {31'b0, b[31]} : y_d;
    end
  end
  //determine o_rd to be saved to baseg and next value of PC
  always_comb begin
    o_flush     = i_flush;  //flush this stage along with the previous stages
    rd_d        = 0;
    rd_valid_d  = 0;
    o_change_pc = 0;
    o_next_pc   = 0;
    wr_rd_d     = 0;
    a_pc        = i_pc;
    if (!i_flush) begin
      if (opcode_rtype || opcode_itype) rd_d = y_d;
      if (opcode_branch && y_d[0]) begin
        o_next_pc = sum;  //branch iff value of ALU is 1(true)
        o_change_pc = i_ce;  //change PC when ce of this stage is high (o_change_pc is valid)
        o_flush = i_ce;
      end
      if (opcode_jal || opcode_jalr) begin
        if (opcode_jalr) a_pc = i_rs1;
        o_next_pc = sum;  //jump to new PC
        o_change_pc = i_ce;  //change PC when ce of this stage is high (o_change_pc is valid)
        o_flush = i_ce;
        rd_d = i_pc + 4;  //logicister the next pc value to destination logicister
      end
    end
    if (opcode_lui) rd_d = i_imm;
    if (opcode_auipc) rd_d = sum;
    if (opcode_branch || opcode_store || (opcode_system && i_funct3 == 0) || opcode_fence)
      wr_rd_d = 0;  //i_funct3==0 are the non-csr system instructions
    else
      wr_rd_d = 1;  //always write to the destination logic except when instruction is BRANCH or STORE or SYSTEM(except CSR system instruction)
    if (opcode_load || (opcode_system && i_funct3 != 0))
      rd_valid_d = 0;  //value of o_rd for load and CSR write is not yet available at this stage
    else rd_valid_d = 1;
    //stall logic (stall when upper stages are stalled, when forced to stall, or when needs to flush previous stages but are still stalled)
    o_stall = (i_stall || i_force_stall) && !i_flush;  //stall when alu needs wait time
  end
  assign sum = a_pc + i_imm;  //share adder for all addition operation for less resource utilization
  assign stall_bit = o_stall || i_stall;
  assign alu_add = i_alu[`ADD];
  assign alu_sub = i_alu[`SUB];
  assign alu_slt = i_alu[`SLT];
  assign alu_sltu = i_alu[`SLTU];
  assign alu_xor = i_alu[`XOR];
  assign alu_or = i_alu[`OR];
  assign alu_and = i_alu[`AND];
  assign alu_sll = i_alu[`SLL];
  assign alu_srl = i_alu[`SRL];
  assign alu_sra = i_alu[`SRA];
  assign alu_eq = i_alu[`EQ];
  assign alu_neq = i_alu[`NEQ];
  assign alu_ge = i_alu[`GE];
  assign alu_geu = i_alu[`GEU];
  assign opcode_rtype = i_opcode[`RTYPE];
  assign opcode_itype = i_opcode[`ITYPE];
  assign opcode_load = i_opcode[`LOAD];
  assign opcode_store = i_opcode[`STORE];
  assign opcode_branch = i_opcode[`BRANCH];
  assign opcode_jal = i_opcode[`JAL];
  assign opcode_jalr = i_opcode[`JALR];
  assign opcode_lui = i_opcode[`LUI];
  assign opcode_auipc = i_opcode[`AUIPC];
  assign opcode_system = i_opcode[`SYSTEM];
  assign opcode_fence = i_opcode[`FENCE];
`ifdef FORMAL
  // assumption on inputs(not more than one opcode and alu operation is high)
  logic [4:0] f_alu = i_alu[`ADD] + i_alu[`SUB] + i_alu[`SLT] + i_alu[`SLTU] + i_alu[`XOR] +
        i_alu[`OR] + i_alu[`AND] + i_alu[`SLL] + i_alu[`SRL] + i_alu[`SRA] + i_alu[`EQ] +
        i_alu[`NEQ] + i_alu[`GE] + i_alu[`GEU] + 0;
  logic [4:0] f_opcode = i_opcode[`RTYPE] + i_opcode[`ITYPE] + i_opcode[`LOAD] +
        i_opcode[`STORE] + i_opcode[`BRANCH] + i_opcode[`JAL] + i_opcode[`JALR] + i_opcode[`LUI] +
        i_opcode[`AUIPC] + i_opcode[`SYSTEM] + i_opcode[`FENCE];
  always_comb begin
    assume (f_alu <= 1);
    assume (f_opcode <= 1);
  end
  // verify all operations with $signed/$unsigned distinctions
  always_comb begin
    if (i_alu[`SLTU]) assert (y_d[0] == $unsigned(a) < $unsigned(b));
    if (i_alu[`SLT]) assert (y_d[0] == $signed(a) < $signed(b));
    if (i_alu[`SLL]) assert ($unsigned(y_d) == $unsigned(a) << $unsigned(b[4:0]));
    if (i_alu[`SRL]) assert ($unsigned(y_d) == $unsigned(a) >> $unsigned(b[4:0]));
    if (i_alu[`SRA]) assert ($signed(y_d) == ($signed(a) >>> $unsigned(b[4:0])));
    if (i_alu[`GEU]) assert (y_d[0] == ($unsigned(a) >= $unsigned(b)));
    if (i_alu[`GE]) assert (y_d[0] == ($signed(a) >= $signed(b)));
  end
`endif
endmodule
