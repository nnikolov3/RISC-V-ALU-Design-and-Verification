// ----------------------------------------------------------------------------
// Class: alu_scoreboard
// Description:
//   This UVM scoreboard verifies the functionality of an Arithmetic Logic Unit
//   (ALU) in a RISC-V 32I processor verification environment. It receives
//   transactions via an analysis port, computes expected ALU outputs, and
//   compares them against the Device Under Test (DUT) outputs. The scoreboard
//   handles arithmetic and logical operations, branch and jump conditions,
//   reset states, and exceptions, ensuring correct behavior across various
//   instruction types and pipeline scenarios.
// Updated: Feb 26, 2025
// ----------------------------------------------------------------------------

`ifndef ALU_SCOREBOARD_SV
`define ALU_SCOREBOARD_SV
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "rv32i_alu_header.sv"
`include "transaction.sv"

class alu_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(alu_scoreboard)

    // ------------------------------------------------------------------------
    // Member: ap
    // Description:
    //   Analysis import port to receive transactions from the monitor or driver
    //   for comparison against expected ALU behavior.
    // ------------------------------------------------------------------------
    uvm_analysis_imp #(transaction, alu_scoreboard) ap;

    // ------------------------------------------------------------------------
    // Constructor: new
    // Description:
    //   Instantiates the scoreboard and initializes the analysis port.
    // Arguments:
    //   - name: String identifier for the scoreboard instance
    //   - parent: Parent UVM component in the hierarchy
    // ------------------------------------------------------------------------
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    // ------------------------------------------------------------------------
    // Function: write
    // Description:
    //   Callback function triggered by the analysis port to process incoming
    //   transactions. It delegates the checking logic to check_transaction.
    // Arguments:
    //   - tx: Transaction object received from the DUT
    // ------------------------------------------------------------------------
    function void write(transaction tx);
        check_transaction(tx);
    endfunction

    // ------------------------------------------------------------------------
    // Task: check_transaction
    // Description:
    //   Validates the DUT's outputs against expected values based on the RISC-V
    //   instruction type and ALU operation. It checks reset conditions, ALU
    //   results, register writes, program counter updates, and exceptions.
    // Arguments:
    //   - tx: Transaction object containing inputs and outputs to verify
    // ------------------------------------------------------------------------
    task check_transaction(transaction tx);
        bit [31:0] expected_y, expected_rd, expected_next_pc, sum;  // Expected ALU and PC values
        bit
            expected_wr_rd,
            expected_rd_valid,
            expected_change_pc,
            expected_flush;  // Control signals
        bit expected_exception;  // Exception flag
        bit error = 0;  // Error flag for mismatch detection

        // ------------------------------------------------------------------------
        // Reset Check
        // Description:
        //   When i_rst_n is low, all DUT outputs should be zero to indicate a reset state.
        // ------------------------------------------------------------------------
        if (tx.i_rst_n === 0) begin
            if (tx.o_exception !== 0 || tx.o_ce !== 0 || tx.o_stall_from_alu !== 0 ||
                tx.o_y !== 0 || tx.o_rd !== 0 || tx.o_next_pc !== 0 || tx.o_flush !== 0 ||
                tx.o_change_pc !== 0 || tx.o_wr_rd !== 0 || tx.o_rd_valid !== 0) begin
                error = 1;
                `uvm_error("SCB", "Reset condition failed: outputs not in reset state")
            end

        end else if (tx.i_ce) begin  // Process only if clock enable is active
            // ------------------------------------------------------------------------
            // ALU Operation Computation
            // Description:
            //   Calculate the expected ALU output (y) and exception based on the opcode
            //   and operands. Operand A is PC for JAL/AUIPC, rs1 otherwise; operand B
            //   is rs2 for RTYPE/BRANCH, imm otherwise.
            // ------------------------------------------------------------------------
            expected_y = alu_operation(
                (tx.i_opcode[`JAL] || tx.i_opcode[`AUIPC]) ? tx.i_pc : tx.i_rs1,
                (tx.i_opcode[`RTYPE] || tx.i_opcode[`BRANCH]) ? tx.i_rs2 : tx.i_imm,
                tx.i_alu,
                expected_exception
            );

            if (!tx.i_flush) begin  // Normal operation (not flushing)
                // ------------------------------------------------------------------------
                // R-type and I-type Instructions
                // Description:
                //   For R-type and I-type instructions, the destination register (rd)
                //   should receive the ALU result.
                // ------------------------------------------------------------------------
                if (tx.i_opcode[`RTYPE] || tx.i_opcode[`ITYPE]) begin
                    expected_rd = expected_y;
                end

                // ------------------------------------------------------------------------
                // Branch Instructions
                // Description:
                //   For branch instructions, if the condition (expected_y) is true,
                //   update the next PC, set change_pc, and flush the pipeline.
                // ------------------------------------------------------------------------
                if (tx.i_opcode[`BRANCH] && expected_y) begin
                    expected_next_pc   = tx.i_pc + tx.i_imm;
                    expected_change_pc = 1;
                    expected_flush     = 1;
                end else if (tx.i_opcode[`BRANCH]) begin
                    expected_change_pc = 0;
                    expected_flush     = 0;
                end

                // ------------------------------------------------------------------------
                // Jump Instructions (JAL/JALR)
                // Description:
                //   For JAL, next PC is PC + imm; for JALR, it’s rs1 + imm. Store return
                //   address (PC + 4) in rd and set control signals.
                // ------------------------------------------------------------------------
                if (tx.i_opcode[`JAL] || tx.i_opcode[`JALR]) begin
                    if (tx.i_opcode[`JALR]) sum = tx.i_rs1 + tx.i_imm;
                    else sum = tx.i_pc + tx.i_imm;
                    expected_next_pc   = sum;
                    expected_change_pc = 1;
                    expected_flush     = 1;
                    expected_rd        = tx.i_pc + 4;  // Return address
                end

                // ------------------------------------------------------------------------
                // LUI and AUIPC Instructions
                // Description:
                //   LUI: rd = imm; AUIPC: rd = PC + imm.
                // ------------------------------------------------------------------------
                if (tx.i_opcode[`LUI]) expected_rd = tx.i_imm;
                if (tx.i_opcode[`AUIPC]) expected_rd = tx.i_pc + tx.i_imm;

                // ------------------------------------------------------------------------
                // Control Signal Expectations
                // Description:
                //   Define when rd should be written (wr_rd) and when rd is valid (rd_valid)
                //   based on instruction type.
                // ------------------------------------------------------------------------
                expected_wr_rd                  =
                    !(tx.i_opcode[`BRANCH] || tx.i_opcode[`STORE] ||
                      (tx.i_opcode[`SYSTEM] && tx.i_funct3 == 0) || tx.i_opcode[`FENCE]);
                expected_rd_valid = !(tx.i_opcode[`LOAD] || (tx.i_opcode[`SYSTEM] && tx.i_funct3 != 0));

                // ------------------------------------------------------------------------
                // Output Comparisons
                // Description:
                //   Compare DUT outputs with expected values, logging errors if mismatches occur.
                // ------------------------------------------------------------------------
                if (tx.o_y !== expected_y) begin
                    error = 1;
                    `uvm_error("SCB", $sformatf("ALU result mismatch: Expected %h, Got %h",
                                                expected_y, tx.o_y))
                end

                if (expected_wr_rd && tx.o_rd !== expected_rd) begin
                    error = 1;
                    `uvm_error("SCB", $sformatf("RD mismatch: Expected %h, Got %h", expected_rd,
                                                tx.o_rd))
                end

                if (tx.o_wr_rd !== expected_wr_rd) begin
                    error = 1;
                    `uvm_error("SCB", $sformatf("Write enable mismatch: Expected %b, Got %b",
                                                expected_wr_rd, tx.o_wr_rd))
                end

                if (tx.o_rd_valid !== expected_rd_valid) begin
                    error = 1;
                    `uvm_error("SCB", $sformatf("RD valid mismatch: Expected %b, Got %b",
                                                expected_rd_valid, tx.o_rd_valid))
                end

                if ((tx.i_opcode[`BRANCH] || tx.i_opcode[`JAL] || tx.i_opcode[`JALR]) &&
                    (tx.o_next_pc !== expected_next_pc ||
                     tx.o_change_pc !== expected_change_pc)) begin
                    error = 1;
                    `uvm_error("SCB",
                               $sformatf(
                                   "PC mismatch: Expected next_pc=%h, change_pc=%b; Got %h, %b",
                                   expected_next_pc, expected_change_pc, tx.o_next_pc,
                                   tx.o_change_pc))
                end

                if (tx.o_exception !== expected_exception) begin
                    error = 1;
                    `uvm_error("SCB", $sformatf("Exception mismatch: Expected %b, Got %b",
                                                expected_exception, tx.o_exception))
                end

                if (tx.o_flush !== expected_flush) begin
                    error = 1;
                    `uvm_error("SCB", $sformatf("Flush mismatch: Expected %b, Got %b",
                                                expected_flush, tx.o_flush))
                end

            end else begin  // Flush case
                // ------------------------------------------------------------------------
                // Flush Check
                // Description:
                //   During flush, expect o_flush to be active and other control signals inactive.
                // ------------------------------------------------------------------------
                if (tx.o_flush !== 1 || tx.o_change_pc !== 0 || tx.o_wr_rd !== 0 ||
                    tx.o_rd_valid !== 0) begin
                    error = 1;
                    `uvm_error("SCB", "Flush condition failed: unexpected output states")
                end

            end

        end

        // ------------------------------------------------------------------------
        // Pass Confirmation
        // Description:
        //   Log a passing message if no errors were detected during the transaction check.
        // ------------------------------------------------------------------------
        if (!error) `uvm_info("SCB", "Transaction passed", UVM_MEDIUM)
    endtask

    // ------------------------------------------------------------------------
    // Function: alu_operation
    // Description:
    //   Computes the ALU result and sets the exception flag based on the operation
    //   type. Supports arithmetic (ADD, SUB), comparison (SLT, SLTU, etc.), and
    //   logical/shift operations (AND, OR, XOR, SLL, SRL, SRA).
    // Arguments:
    //   - a: First operand
    //   - b: Second operand
    //   - op: ALU operation code
    //   - exception: Output flag for overflow/underflow conditions
    // Returns:
    //   32-bit result of the ALU operation
    // ------------------------------------------------------------------------
    function bit [31:0] alu_operation(bit [31:0] a, bit [31:0] b, bit [`ALU_WIDTH-1:0] op,
                                      output bit exception);
        bit [31:0] result;
        exception = 0;
        case ($clog2(
            op
        ))
            0: begin  // ADD
                result = a + b;
                if ((a[31] == b[31]) && (result[31] != a[31])) exception = 1;  // Overflow check
            end

            1: begin  // SUB
                result = a - b;
                if ((a[31] != b[31]) && (result[31] != a[31])) exception = 1;  // Underflow check
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
