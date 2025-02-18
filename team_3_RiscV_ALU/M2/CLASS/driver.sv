// ----------------------------------------------------------------------------
// ECE544 M2 - RV32I ALU Driver
// ----------------------------------------------------------------------------
// This file implements a UVM driver for the RV32I ALU. It drives input signals
// to the DUT based on the provided transactions.
// ----------------------------------------------------------------------------

import uvm_pkg::*;
`include "rv32i_alu_header.sv"
`include "uvm_macros.svh"
`include "transaction.sv"

class driver extends uvm_driver #(transaction);

  `uvm_component_utils(driver)

  virtual rv32i_alu_if drv_if;  // Virtual interface handle

  function new(string name = "driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual rv32i_alu_if)::get(this, "", "drv_if", drv_if)) begin
      `uvm_fatal(get_type_name(), "Failed to get virtual interface!")
    end
  endfunction

  task run_phase(uvm_phase phase);
    transaction req;
    forever begin
      seq_item_port.get_next_item(req);

      // Drive the DUT signals
      drv_if.i_opcode      = req.i_opcode;
      drv_if.i_alu         = req.i_alu;
      drv_if.i_rs1         = req.i_rs1;
      drv_if.i_rs2         = req.i_rs2;
      drv_if.i_imm         = req.i_imm;
      drv_if.i_funct3      = req.i_funct3;
      drv_if.i_pc          = req.i_pc;
      drv_if.i_rs1_addr    = req.i_rs1_addr;
      drv_if.i_rd_addr     = req.i_rd_addr;
      drv_if.i_ce          = req.i_ce;
      drv_if.i_rst_n       = req.i_rst_n;
      drv_if.i_stall       = req.i_stall;
      drv_if.i_force_stall = req.i_force_stall;
      drv_if.i_flush       = req.i_flush;

      // Wait for the next clock edge
      @(posedge drv_if.i_clk);

      // Finish the transaction
      seq_item_port.item_done();
    end
  endtask

endclass
