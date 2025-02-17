

`ifndef RV32I_ALU_TRANSACTION_SV
`define RV32I_ALU_TRANSACTION_SV


import uvm_pkg::*;
`include "rv32i_header.sv"
`include "uvm_macros.svh"

class rv32i_alu_transaction extends uvm_sequence_item;

  `uvm_object_utils(rv32i_alu_transaction)

  rand bit [6:0] opcode;
  rand bit [31:0] alu_input1, alu_input2;
  rand bit [3:0] alu_control;
  bit [31:0] alu_result;

  constraint valid_opcode_c { opcode inside {7'h33, 7'h13, 7'h03, 7'h23}; } // Example opcodes

  function new(string name = "rv32i_alu_transaction");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("Opcode: %0h, ALU In1: %0h, ALU In2: %0h, Control: %0h, Result: %0h",
                     opcode, alu_input1, alu_input2, alu_control, alu_result);
  endfunction

endclass

`endif


class rv32i_alu_driver extends uvm_driver #(rv32i_alu_transaction);

  `uvm_component_utils(rv32i_alu_driver)

  virtual rv32i_alu_if drv_if;  // Virtual interface

  function new(string name = "rv32i_alu_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual rv32i_alu_if)::get(this, "", "drv_if", drv_if)) begin
      `uvm_fatal(get_type_name(), "Failed to get virtual interface!")
    end
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);

      // Drive signals to the DUT
      drv_if.opcode      = req.opcode;
      drv_if.alu_input1  = req.alu_input1;
      drv_if.alu_input2  = req.alu_input2;
      drv_if.alu_control = req.alu_control;

      // Wait for DUT response
      @(posedge drv_if.clk);

      seq_item_port.item_done();
    end
  endtask

endclass
