/*
ECE593  : Milestone 2, Group 3
Original: https      :          //github.com/AngeloJacobo/RISC-V/blob/main/rtl/

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
*          Stalling    : Uses o_stall_from_alu to pause the memory-access stage for operations like load/store.
*          Flushing    : Responds to i_stall, i_force_stall, and i_flush signals to manage pipeline flow.


Summary:
    The rv32i_alu module in the RISC-V core's execute stage selects operands, performs arithmetic,
    logical, and comparison operations, manages branch/jump instructions,
    handles register writeback, and controls pipeline flow through stalling,
    and flushing based on the current instruction.

*/

`include "rv32i_alu_header.sv"
`include "generator.sv"
`include "transaction.sv"
`include "interface.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"


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


    //testing signals
    logic [31:0] verify_y;
    // Alu interface
    alu_if dut_if (
        .i_clk  (i_clk),
        .i_rst_n(i_rst_n)
    );

    // Create mailboxes
    mailbox #(transaction) driver_mb = new();
    mailbox #(transaction) mon_in2scb = new();
    mailbox #(transaction) mon_out2scb = new();


    // Driver, Monitors, and Scoreboard
    generator generator_inst;
    driver driver_inst;
    monitor_in mon_in_inst;
    monitor_out mon_out_inst;
    scoreboard scoreboard_inst;

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
        forever begin
            #10;
            i_clk = ~i_clk;
        end
    end

    // Initial block
    initial begin
        i_clk           = 0;
        i_rst_n         = 0;
        i_alu           = 0;
        i_rs1_addr      = 5'b0;
        i_rs1           = 32'b0;
        i_rs2           = 32'b0;
        i_imm           = 32'b0;
        i_funct3        = 3'b0;
        i_opcode        = 0;
        i_exception     = 0;
        i_pc            = 32'b0;
        i_rd_addr       = 5'b0;
        i_ce            = 1'b1;
        i_stall         = 1'b0;
        i_force_stall   = 1'b0;
        i_flush         = 1'b0;



        // Create driver and monitors
        generator_inst  = new(driver_mb);
        driver_inst     = new(dut_if, driver_mb);
        mon_in_inst     = new(dut_if, mon_in2scb);
        mon_out_inst    = new(dut_if, mon_out2scb);
        scoreboard_inst = new(mon_in2scb, mon_out2scb);



        // Fork off driver, monitors, and scoreboard
        fork
            generator_inst.generate_scenarios();
            driver_inst.run();
            mon_in_inst.main();
            mon_out_inst.main();
            scoreboard_inst.main();
        join_none


        #20 i_rst_n = 1;
        for (int i = 0; i < 14; i++) begin
            i_alu    = 0;
            i_alu[i] = 1;
            i_opcode = 2;
            i_rs1    = 4'b1100;
            i_imm    = 4'b1010;
            i_ce     = 1;
            #20 verify_y = alu_operation(i_rs1, i_imm, i_alu);
            if (verify_y !== o_y) begin
                $display("ERROR!!!!\nDUT values =\n", DUT.i_rst_n);
                $display("DUT CLK = ", DUT.i_clk);
                $display("DUT rs1_addr = ", DUT.i_rs1_addr);
                $display("DUT rs1 = ", DUT.i_rs1);
                $display("DUT rs2 = ", DUT.i_rs2);
                $display("DUT imm = ", DUT.i_imm);
                $display("DUT funct3 = ", DUT.i_funct3);
                $display("DUT opcode = ", DUT.i_opcode);
                $display("DUT exception = ", DUT.i_exception);
                $display("DUT pc = ", DUT.i_pc);
                $display("DUT rd_addr = ", DUT.i_rd_addr);
                $display("DUT ce = ", DUT.i_ce);
                $display("DUT stall = ", DUT.i_stall);
                $display("DUT force_stall = ", DUT.i_force_stall);
                $display("DUT flush = ", DUT.i_flush);
                $display("DUT stall_bit = ", DUT.stall_bit);
                $display("DUT alu ADD = ", DUT.alu_add);

            end

            $displayb("alu_op = ", i_alu);
            $displayb("rs1 = ", i_rs1);
            $displayb("imm = ", i_imm);
            $displayb("alu output =\t", o_y);
            $displayb("correct output =\t", verify_y);

        end


        // End simulation after testing
        #100 $finish;
    end

    //skeleton given by chatgpt, and then modified
    function automatic logic [31:0] alu_operation(input logic [31:0] a,
                                                  input logic [31:0] b,
                                                  input logic [`ALU_WIDTH-1:0] op  // 6-bit operation code to cover given values
);
        //because this is one hot encoded, this will return the location of the highest bit
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

            default: return 32'hDEADBEEF;  // Invalid operation
        endcase
    endfunction

endmodule
