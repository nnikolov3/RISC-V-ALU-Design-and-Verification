// driver.sv

`ifndef DRIVER_SV
`define DRIVER_SV

`include "uvm_macros.svh"
`include "rv32i_header.sv"

class alu_driver extends uvm_driver #(alu_transaction);
  `uvm_component_utils(alu_driver)

  // Virtual interface for connecting to the DUT
  virtual alu_interface vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  // Build phase to get the interface handle
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual alu_interface)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "Failed to get virtual interface 'vif' from uvm_config_db")
    end
  endfunction

  // Run phase where the driver drives the interface signals
  task run_phase(uvm_phase phase);
    alu_transaction req;
    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask

  // Task to drive the item onto the interface
  task drive_item(alu_transaction req);
    @(posedge vif.i_clk);
    if (vif.i_rst_n == 1'b1) begin
      // Drive signals based on the transaction
      vif.i_alu         = req.alu_op;
      vif.i_rs1_addr    = req.rs1_addr;
      vif.i_rs1         = req.rs1;
      vif.i_rs2         = req.rs2;
      vif.i_imm         = req.imm;
      vif.i_funct3      = req.funct3;
      vif.i_opcode      = req.opcode;
      vif.i_exception   = req.exception;
      vif.i_pc          = req.pc;
      vif.i_rd_addr     = req.rd_addr;
      vif.i_ce          = req.ce;
      vif.i_stall       = req.stall;
      vif.i_force_stall = req.force_stall;
      vif.i_flush       = req.flush;

      // Wait for one clock cycle for the operation to take effect
      @(posedge vif.i_clk);
    end else begin
      // Reset condition; drive all inputs to default or reset values
      vif.i_alu         = '0;
      vif.i_rs1_addr    = '0;
      vif.i_rs1         = '0;
      vif.i_rs2         = '0;
      vif.i_imm         = '0;
      vif.i_funct3      = '0;
      vif.i_opcode      = '0;
      vif.i_exception   = '0;
      vif.i_pc          = '0;
      vif.i_rd_addr     = '0;
      vif.i_ce          = '0;
      vif.i_stall       = '0;
      vif.i_force_stall = '0;
      vif.i_flush       = '0;
    end
  endtask

endclass : alu_driver

`endif  // DRIVER_SV
