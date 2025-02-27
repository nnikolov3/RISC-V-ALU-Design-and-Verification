`include "uvm_macros.svh"
import uvm_pkg::*;
`timescale 1ns / 1ps `default_nettype none
module top;
    // Clock and reset signals
    logic i_clk;
    logic i_rst_n;
    // Interface instantiation
    alu_if dut_if (
        .i_clk  (i_clk),
        .i_rst_n(i_rst_n)
    );
    // DUT instantiation
    rv32i_alu DUT (
        .i_clk           (dut_if.i_clk),
        .i_rst_n         (dut_if.i_rst_n),
        .i_alu           (dut_if.i_alu),
        .i_rs1_addr      (dut_if.i_rs1_addr),
        .i_rs1           (dut_if.i_rs1),
        .i_rs2           (dut_if.i_rs2),
        .i_imm           (dut_if.i_imm),
        .i_funct3        (dut_if.i_funct3),
        .i_opcode        (dut_if.i_opcode),
        .i_exception     (dut_if.i_exception),
        .i_pc            (dut_if.i_pc),
        .i_rd_addr       (dut_if.i_rd_addr),
        .i_ce            (dut_if.i_ce),
        .i_stall         (dut_if.i_stall),
        .i_force_stall   (dut_if.i_force_stall),
        .i_flush         (dut_if.i_flush),
        .o_rs1_addr      (dut_if.o_rs1_addr),
        .o_rs1           (dut_if.o_rs1),
        .o_rs2           (dut_if.o_rs2),
        .o_imm           (dut_if.o_imm),
        .o_funct3        (dut_if.o_funct3),
        .o_opcode        (dut_if.o_opcode),
        .o_exception     (dut_if.o_exception),
        .o_y             (dut_if.o_y),
        .o_pc            (dut_if.o_pc),
        .o_next_pc       (dut_if.o_next_pc),
        .o_change_pc     (dut_if.o_change_pc),
        .o_wr_rd         (dut_if.o_wr_rd),
        .o_rd_addr       (dut_if.o_rd_addr),
        .o_rd            (dut_if.o_rd),
        .o_rd_valid      (dut_if.o_rd_valid),
        .o_stall_from_alu(dut_if.o_stall_from_alu),
        .o_ce            (dut_if.o_ce),
        .o_stall         (dut_if.o_stall),
        .o_flush         (dut_if.o_flush)
    );
    // Clock generation
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk;  // 10ns period
    end
    // Reset assertion
    initial begin
        i_rst_n = 0;
        #20;
        i_rst_n = 1;
    end
    // Set virtual interface in UVM configuration database with updated key
    initial begin
        uvm_config_db#(virtual alu_if)::set(null, "*", "alu_vif", dut_if);
    end
    // Run the UVM test
    initial begin
		run_test("alu_base_test");
    end
endmodule
