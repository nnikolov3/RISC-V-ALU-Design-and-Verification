// ----------------------------------------------------------------------------
// ECE544 M2 - RV32I ALU Scoreboard
// ----------------------------------------------------------------------------
// This file implements a scoreboard to verify the correctness of the ALU
// outputs by comparing them with expected results.
// ----------------------------------------------------------------------------

`include "rv32i_alu_header.sv"
`include "transaction.sv"

class scoreboard;
    //-------------------------------------------------------------------------
    // Mailboxes for communication between the monitor and scoreboard.
    //-------------------------------------------------------------------------
    mailbox #(transaction) mon_in2scb = new();
    mailbox #(transaction) mon_out2scb = new();



    //-------------------------------------------------------------------------
    // FIFO Arrays to Store Input Signals
    // These arrays buffer the input signals from incoming transactions,
    // so they can be matched later with the corresponding output transaction.
    //-------------------------------------------------------------------------
    bit i_clk_fifo[$];  // (Optional) FIFO for clock signals (currently commented out)
    bit i_rst_n_fifo[$];  // (Optional) FIFO for reset signals if needed.
    bit [`ALU_WIDTH-1:0] i_alu_fifo[$];  // FIFO for ALU control signals.
    bit [4:0] i_rs1_addr_fifo[$];  // FIFO for RS1 register addresses.
    bit [31:0] i_rs1_fifo[$];  // FIFO for RS1 data.
    bit [31:0] i_rs2_fifo[$];  // FIFO for RS2 data.
    bit [31:0] i_imm_fifo[$];  // FIFO for immediate values.
    bit [2:0] i_funct3_fifo[$];  // FIFO for funct3 fields.
    bit [`OPCODE_WIDTH-1:0] i_opcode_fifo[$];  // FIFO for opcode signals.
    bit [`EXCEPTION_WIDTH-1:0] i_exception_fifo[$];  // FIFO for exception signals.
    bit [31:0] i_pc_fifo[$];  // FIFO for program counter values.
    bit [4:0] i_rd_addr_fifo[$];  // FIFO for destination register addresses.
    bit i_ce_fifo[$];  // FIFO for clock enable signals.
    bit i_stall_fifo[$];  // FIFO for stall signals.
    bit i_force_stall_fifo[$];  // FIFO for force stall signals.
    bit i_flush_fifo[$];  // FIFO for flush signals.

    //-------------------------------------------------------------------------
    // Constructor: Initializes the scoreboard with the provided mailboxes.
    //-------------------------------------------------------------------------
    function new(mailbox#(transaction) mon_in2scb,
                 mailbox#(transaction) mon_out2scb);
        this.mon_in2scb  = mon_in2scb;
        this.mon_out2scb = mon_out2scb;
    endfunction

    //-------------------------------------------------------------------------
    // Task: main
    // Launches the concurrent tasks to collect input and output transactions.
    //-------------------------------------------------------------------------
    task main;
        fork
            get_input();  // Continuously gather input transactions.
            get_output();  // Continuously gather output transactions and perform checking.
        join_none
        ;
    endtask

    //-------------------------------------------------------------------------
    // Task: get_input
    // Continuously retrieves transactions from the input mailbox and pushes
    // the individual signal fields into their respective FIFO arrays.
    //-------------------------------------------------------------------------
    task get_input();
        transaction tx;
        forever begin
            mon_in2scb.get(tx);

            // Store input signals from the transaction into FIFOs.

            i_clk_fifo.push_back(tx.i_clk);
            i_rst_n_fifo.push_back(tx.i_rst_n);
            i_alu_fifo.push_back(tx.i_alu);
            i_rs1_addr_fifo.push_back(tx.i_rs1_addr);
            i_rs1_fifo.push_back(tx.i_rs1);
            i_rs2_fifo.push_back(tx.i_rs2);
            i_imm_fifo.push_back(tx.i_imm);
            i_funct3_fifo.push_back(tx.i_funct3);
            i_opcode_fifo.push_back(tx.i_opcode);
            i_exception_fifo.push_back(tx.i_exception);
            i_pc_fifo.push_back(tx.i_pc);
            i_rd_addr_fifo.push_back(tx.i_rd_addr);
            i_ce_fifo.push_back(tx.i_ce);
            i_stall_fifo.push_back(tx.i_stall);
            i_force_stall_fifo.push_back(tx.i_force_stall);
            i_flush_fifo.push_back(tx.i_flush);
        end
    endtask

    //-------------------------------------------------------------------------
    // Task: get_output
    // Continuously retrieves transactions from the output mailbox,
    // compares the output against expected results derived from the buffered inputs,
    // and flags errors if mismatches are detected.
    //-------------------------------------------------------------------------
    task get_output();
        transaction                        tx;
        // Local signal declarations for input data retrieved from FIFOs.
        bit                                rst_n;
        bit         [      `ALU_WIDTH-1:0] alu;
        bit         [                 4:0] rs1_addr;
        bit         [                31:0] rs1;
        bit         [                31:0] rs2;
        bit         [                31:0] imm;
        bit         [                 2:0] funct3;
        bit         [   `OPCODE_WIDTH-1:0] opcode;
        bit         [`EXCEPTION_WIDTH-1:0] exception;
        bit         [                31:0] pc;
        bit         [                 4:0] rd_addr;
        bit                                ce;
        bit                                stall;
        bit                                force_stall;
        bit                                flush;
        bit         [                31:0] out;
        bit         [                31:0] rd_temp;
        bit         [                31:0] sum;
        bit                                error;
        bit         [                31:0] rd_d;
        bit                                wr_rd_d;
        bit                                rd_valid;

        forever begin
            mon_out2scb.get(tx);
            error       = 0;
            wr_rd_d     = 0;
            rd_d        = 0;

            // Pop the corresponding stored input signals from the FIFOs.
            rst_n       = i_rst_n_fifo.pop_front();
            alu         = i_alu_fifo.pop_front();
            rs1_addr    = i_rs1_addr_fifo.pop_front();
            rs1         = i_rs1_fifo.pop_front();
            rs2         = i_rs2_fifo.pop_front();
            imm         = i_imm_fifo.pop_front();
            funct3      = i_funct3_fifo.pop_front();
            opcode      = i_opcode_fifo.pop_front();
            exception   = i_exception_fifo.pop_front();
            pc          = i_pc_fifo.pop_front();
            rd_addr     = i_rd_addr_fifo.pop_front();
            ce          = i_ce_fifo.pop_front();
            stall       = i_stall_fifo.pop_front();
            force_stall = i_force_stall_fifo.pop_front();
            flush       = i_flush_fifo.pop_front();

            //-------------------------------------------------------------------------
            // Check for errors based on reset conditions and expected output.
            // mailbox #(transaction) mon_in2scb;
            // mailbox #(transaction) mon_out2scb;
            if (rst_n === 0 && tx.o_exception !== 0 && tx.o_ce !== 0 && tx.o_stall_from_alu !== 0) begin
                error = 1;
            end else begin
                // Compute the expected ALU output based on the opcode.
                out = alu_operation(
                    ((opcode[`JAL] || opcode[`AUIPC]) ? pc : rs1),
                    ((opcode[`RTYPE] || opcode[`BRANCH]) ? rs2 : imm),
                    alu
                );

                if (!flush) begin
                    // For R-type and I-type instructions, set the temporary result.
                    if (opcode[`RTYPE] || opcode[`ITYPE]) begin
                        rd_temp = out;
                    end

                    // For branch instructions, verify that the next PC and control signals match.
                    if (opcode[`BRANCH] && out &&
              ((pc + imm !== tx.o_next_pc) ||
               (ce !== tx.o_change_pc) ||
               (ce !== tx.o_flush)
              )
          ) begin
                        error = 1;
                    end

                    // For jump instructions (JAL/JALR), calculate expected next PC.
                    if (opcode[`JAL] || opcode[`JALR]) begin
                        if (opcode[`JALR] === 1) begin
                            sum = rs1 + imm;
                        end
                        if (sum !== tx.o_next_pc || ce !== tx.o_change_pc || ce !== tx.o_flush) begin
                            error = 1;
                        end

                        // For jump instructions, the destination register typically holds PC+4.
                        rd_d = pc + 4;
                    end
                end

                // For LUI instructions, the immediate is loaded directly.
                if (opcode[`LUI]) begin
                    rd_d = imm;
                end

                // For AUIPC instructions, the destination is computed as PC + immediate.
                if (opcode[`AUIPC]) begin
                    rd_d = pc + imm;
                end

                // Determine whether the destination register should be written.
                wr_rd_d = (opcode[`BRANCH]   ||
                   opcode[`STORE]    ||
                   (opcode[`SYSTEM] && (funct3 == 0)) ||
                   opcode[`FENCE]
                  ) ? 0 : 1;

                // Determine if the destination register data is valid.
                rd_valid = (opcode[`LOAD] || (opcode[`SYSTEM] && (funct3 != 0))) ? 0 : 1;

                // Verify stall conditions.
                if (tx.o_stall !== (stall || force_stall) && !flush) begin
                    error = 1;
                end

                // If no stall and clock enable is asserted, compare expected and actual outputs.
                if (!(tx.o_stall || stall) && ce === 1) begin
                    if (opcode !== tx.o_opcode             ||
              exception !== tx.o_exception        ||
              out !== tx.o_y                      ||
              rs1_addr !== tx.o_rs1_addr          ||
              rs1 !== tx.o_rs1                    ||
              rs2 !== tx.o_rs2                    ||
              rd_addr !== tx.o_rd_addr            ||
              imm !== tx.o_imm                    ||
              funct3 !== tx.o_funct3              ||
              rd_d !== tx.o_rd                   ||
              rd_valid !== tx.o_rd_valid           ||
              wr_rd_d !== tx.o_wr_rd              ||
              ((opcode[`STORE] || opcode[`LOAD]) == tx.o_stall_from_alu) ||
              pc !== tx.o_pc
          ) begin
                        error = 1;
                    end
                end

                // Additional checks for flush and clock enable conditions.
                if (flush && !(tx.o_stall || stall) && tx.o_ce !== 0) begin
                    error = 1;
                end else if (!(tx.o_stall || stall) && tx.o_ce !== ce) begin
                    error = 1;
                end else if (tx.o_stall && tx.o_ce !== 0) begin
                    error = 1;
                end
            end

            // If an error is detected, display detailed information about the inputs and outputs.
            if (error == 1) begin
                $displayh(
                    "**********ERROR**********", "\ni_rst_n = ", rst_n,
                    "\ni_alu = ",
                    i_alu_fifo,  // Displaying the entire FIFO content might be useful for debugging.
                    "\ni_rs1_addr = ", i_rs1_addr_fifo, "\ni_rs1 = ",
                    i_rs1_fifo, "\ni_rs2 = ", i_rs2_fifo, "\ni_imm = ",
                    i_imm_fifo, "\ni_funct3 = ", i_funct3_fifo, "\ni_opcode = ",
                    i_opcode_fifo, "\ni_exception = ", i_exception_fifo,
                    "\ni_pc = ", i_pc_fifo, "\ni_rd_addr = ", i_rd_addr_fifo,
                    "\ni_ce = ", i_ce_fifo, "\ni_stall = ", i_stall_fifo,
                    "\ni_force_stall = ", i_force_stall_fifo, "\ni_flush = ",
                    i_flush_fifo, "\no_rs1_addr = ", tx.o_rs1_addr,
                    "\no_rs1 = ", tx.o_rs1, "\no_rs2 = ", tx.o_rs2,
                    "\no_imm = ", tx.o_imm, "\no_funct3 = ", tx.o_funct3,
                    "\no_opcode = ", tx.o_opcode, "\no_exception = ",
                    tx.o_exception, "\no_y = ", tx.o_y, "\no_pc = ", tx.o_pc,
                    "\no_next_pc = ", tx.o_next_pc, "\no_change_pc = ",
                    tx.o_change_pc, "\no_wr_rd = ", tx.o_wr_rd,
                    "\no_rd_addr = ", tx.o_rd_addr, "\no_rd = ", tx.o_rd,
                    "\no_rd_valid = ", tx.o_rd_valid, "\no_stall_from_alu = ",
                    tx.o_stall_from_alu, "\no_ce = ", tx.o_ce, "\no_stall = ",
                    tx.o_stall, "\no_flush = ", tx.o_flush);
            end

        end
    endtask

    //-------------------------------------------------------------------------
    // Function: alu_operation
    // Computes the expected ALU result based on the provided operands and the
    // one-hot encoded operation signal.
    //
    // Parameters:
    //  a  - First operand.
    //  b  - Second operand.
    //  op - One-hot encoded ALU operation signal (of width `ALU_WIDTH).
    //
    // Returns:
    //  The computed result as a 32-bit value.
    //
    // Note:
    //  The operation code is derived using $clog2, which returns the index of the
    //  highest set bit, assuming op is one-hot encoded.
    //-------------------------------------------------------------------------
    function automatic logic [31:0] alu_operation(
        input logic [31:0] a, input logic [31:0] b,
        input logic [`ALU_WIDTH-1:0] op);
        case ($clog2(
            op
        ))
            0: return a + b;  // ADD
            1: return a - b;  // SUB
            2: return (a < b) ? 1 : 0;  // SLT (Signed Less Than)
            3:
            return (unsigned'(a) < unsigned'(b)) ? 1 : 0;  // SLTU (Unsigned Less Than)
            4: return a ^ b;  // XOR
            5: return a | b;  // OR
            6: return a & b;  // AND
            7: return a << b[4:0];  // SLL
            8: return a >> b[4:0];  // SRL
            9: return $signed(a) >>> b[4:0];  // SRA
            10: return (a == b) ? 1 : 0;  // EQ
            11: return (a != b) ? 1 : 0;  // NEQ
            12: return (a >= b) ? 1 : 0;  // GE
            13: return (unsigned'(a) >= unsigned'(b)) ? 1 : 0;  // GEU
            default: return 0;  // Default case for invalid operation.
        endcase
    endfunction

endclass
