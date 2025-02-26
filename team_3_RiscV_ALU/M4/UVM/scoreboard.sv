// ----------------------------------------------------------------------------
// ECE593 M4 - RV32I ALU Scoreboard
// ----------------------------------------------------------------------------
// This file implements a UVM scoreboard to verify the correctness of the ALU
// outputs by comparing them with expected results derived from input transactions.
// Enhanced for reset scenarios, exception handling, and detailed logging.
// ----------------------------------------------------------------------------
`ifndef ALU_SCB_SV
`define ALU_SCB_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "rv32i_alu_header.sv"
`include "transaction.sv"
class alu_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(alu_scoreboard)
    // Analysis FIFOs for input and output transactions
    uvm_tlm_analysis_fifo #(transaction) input_fifo;
    uvm_tlm_analysis_fifo #(transaction) output_fifo;
    // Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
        input_fifo  = new("input_fifo", this);
        output_fifo = new("output_fifo", this);
    endfunction
    // Build phase to initialize components
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction
    // Run phase to process transactions
    task run_phase(uvm_phase phase);
        transaction input_tx, output_tx;
        forever begin
            input_fifo.get(input_tx);
            output_fifo.get(output_tx);
            check_transaction(input_tx, output_tx);
        end
    endtask
    // Task to check the transaction
    task check_transaction(transaction input_tx, transaction output_tx);
        bit [31:0] expected_y, expected_rd, expected_next_pc, sum;
        bit expected_wr_rd, expected_rd_valid, expected_change_pc, expected_flush;
        bit expected_exception;
        bit error = 0;
        // Reset condition check
        if (input_tx.i_rst_n === 0) begin
            if (output_tx.o_exception !== 0 || output_tx.o_ce !== 0 ||
                output_tx.o_stall_from_alu !== 0 || output_tx.o_y !== 0 || output_tx.o_rd !== 0 ||
                output_tx.o_next_pc !== 0) begin
                error = 1;
                `uvm_error("SCB", "Reset condition failed: outputs not in reset state")
            end
        end else begin
            // Compute expected ALU output and predict exception
            expected_y = alu_operation(
                (input_tx.i_opcode[`JAL] || input_tx.i_opcode[`AUIPC]) ? input_tx.i_pc :
                    input_tx.i_rs1,
                (input_tx.i_opcode[`RTYPE] || input_tx.i_opcode[`BRANCH]) ? input_tx.i_rs2 :
                    input_tx.i_imm,
                input_tx.i_alu,
                expected_exception
            );
            // Handle flush condition
            if (!input_tx.i_flush) begin
                // R-type and I-type instructions
                if (input_tx.i_opcode[`RTYPE] || input_tx.i_opcode[`ITYPE]) begin
                    expected_rd = expected_y;
                end
                // Branch instructions
                if (input_tx.i_opcode[`BRANCH] && expected_y) begin
                    expected_next_pc   = input_tx.i_pc + input_tx.i_imm;
                    expected_change_pc = input_tx.i_ce;
                    expected_flush     = input_tx.i_ce;
                    if (expected_next_pc !== output_tx.o_next_pc || expected_change_pc !==
                        output_tx.o_change_pc || expected_flush !== output_tx.o_flush) begin
                        error = 1;
                        `uvm_error(
                            "SCB",
                            $sformatf(
                                "Branch mismatch: Expected next_pc=%h, Got %h; Expected change_pc=%b, Got %b",
                                expected_next_pc, output_tx.o_next_pc, expected_change_pc,
                                output_tx.o_change_pc))
                    end
                end
                // Jump instructions (JAL/JALR)
                if (input_tx.i_opcode[`JAL] || input_tx.i_opcode[`JALR]) begin
                    if (input_tx.i_opcode[`JALR]) begin
                        sum = input_tx.i_rs1 + input_tx.i_imm;
                    end else begin
                        sum = input_tx.i_pc + input_tx.i_imm;
                    end
                    expected_next_pc   = sum;
                    expected_change_pc = input_tx.i_ce;
                    expected_flush     = input_tx.i_ce;
                    expected_rd        = input_tx.i_pc + 4;
                    if (sum !== output_tx.o_next_pc || expected_change_pc !==
                        output_tx.o_change_pc || expected_flush !== output_tx.o_flush ||
                        expected_rd !== output_tx.o_rd) begin
                        error = 1;
                        `uvm_error(
                            "SCB",
                            $sformatf(
                                "Jump mismatch: Expected next_pc=%h, Got %h; Expected rd=%h, Got %h",
                                sum, output_tx.o_next_pc, expected_rd, output_tx.o_rd))
                    end
                end
                // LUI instruction
                if (input_tx.i_opcode[`LUI]) begin
                    expected_rd = input_tx.i_imm;
                end
                // AUIPC instruction
                if (input_tx.i_opcode[`AUIPC]) begin
                    expected_rd = input_tx.i_pc + input_tx.i_imm;
                end
                // Determine write and validity conditions
                expected_wr_rd = !(input_tx.i_opcode[`BRANCH] || input_tx.i_opcode[`STORE] ||
                                   (input_tx.i_opcode[`SYSTEM] && input_tx.i_funct3 == 0) ||
                                   input_tx.i_opcode[`FENCE]);
                expected_rd_valid = !(input_tx.i_opcode[`LOAD] ||
                                      (input_tx.i_opcode[`SYSTEM] && input_tx.i_funct3 != 0));
                // Stall condition
                if (output_tx.o_stall !== (input_tx.i_stall || input_tx.i_force_stall)) begin
                    error = 1;
                    `uvm_error("SCB", "Stall mismatch detected")
                end
                // Compare outputs when no stall and clock enable is asserted
                if (!(output_tx.o_stall || input_tx.i_stall) && input_tx.i_ce) begin
                    if (input_tx.i_opcode !== output_tx.o_opcode) begin
                        error = 1;
                        `uvm_error("SCB", $sformatf("Opcode mismatch: Expected %b, Got %b",
                                                    input_tx.i_opcode, output_tx.o_opcode))
                    end
                    if (expected_exception !== output_tx.o_exception) begin
                        error = 1;
                        `uvm_error("SCB", $sformatf("Exception mismatch: Expected %b, Got %b",
                                                    expected_exception, output_tx.o_exception))
                    end
                    if (expected_y !== output_tx.o_y) begin
                        error = 1;
                        `uvm_error("SCB", $sformatf("ALU result mismatch: Expected %h, Got %h",
                                                    expected_y, output_tx.o_y))
                    end
                    if (expected_rd !== output_tx.o_rd) begin
                        error = 1;
                        `uvm_error("SCB", $sformatf(
                                              "Register destination mismatch: Expected %h, Got %h",
                                              expected_rd, output_tx.o_rd))
                    end
                    if (expected_wr_rd !== output_tx.o_wr_rd) begin
                        error = 1;
                        `uvm_error("SCB", $sformatf("Write enable mismatch: Expected %b, Got %b",
                                                    expected_wr_rd, output_tx.o_wr_rd))
                    end
                    if (expected_rd_valid !== output_tx.o_rd_valid) begin
                        error = 1;
                        `uvm_error("SCB", $sformatf("Result valid mismatch: Expected %b, Got %b",
                                                    expected_rd_valid, output_tx.o_rd_valid))
                    end
                end
            end
            // Additional flush and clock enable checks
            if (input_tx.i_flush && !(output_tx.o_stall || input_tx.i_stall) &&
                output_tx.o_ce !== 0) begin
                error = 1;
                `uvm_error("SCB", "Flush condition failed: o_ce should be 0")
            end else if (!(output_tx.o_stall || input_tx.i_stall) &&
                         output_tx.o_ce !== input_tx.i_ce) begin
                error = 1;
                `uvm_error("SCB", "Clock enable mismatch")
            end else if (output_tx.o_stall && output_tx.o_ce !== 0) begin
                error = 1;
                `uvm_error("SCB", "Stall condition failed: o_ce should be 0")
            end
        end
        if (!error) begin
            `uvm_info("SCB", "Transaction passed", UVM_MEDIUM)
        end
    endtask
    // Function to compute expected ALU result and predict exception
    function bit [31:0] alu_operation(bit [31:0] a, bit [31:0] b, bit [`ALU_WIDTH-1:0] op,
                                      output bit exception);
        bit [31:0] result;
        exception = 0;
        case ($clog2(
            op
        ))
            0: begin  // ADD
                result = a + b;
                if ((a[31] == b[31]) && (result[31] != a[31])) exception = 1;  // Overflow
            end
            1: begin  // SUB
                result = a - b;
                if ((a[31] != b[31]) && (result[31] != a[31])) exception = 1;  // Underflow
            end
            2:       result = ($signed(a) < $signed(b)) ? 32'h1 : 32'h0;  // SLT
            3:       result = (a < b) ? 32'h1 : 32'h0;  // SLTU
            4:       result = a ^ b;  // XOR
            5:       result = a | b;  // OR
            6:       result = a & b;  // AND
            7:       result = a << b[4:0];  // SLL
            8:       result = a >> b[4:0];  // SRL
            9:       result = $signed(a) >>> b[4:0];  // SRA
            10:      result = (a == b) ? 32'h1 : 32'h0;  // EQ
            11:      result = (a != b) ? 32'h1 : 32'h0;  // NEQ
            12:      result = ($signed(a) >= $signed(b)) ? 32'h1 : 32'h0;  // GE
            13:      result = (a >= b) ? 32'h1 : 32'h0;  // GEU
            default: result = 0;
        endcase
        return result;
    endfunction
endclass
`endif
