`include "rv32i_header.sv"

interface alu_interface (input logic i_clk, i_rst_n);
    // Input signals to DUT
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

    // Output signals from DUT
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

endinterface