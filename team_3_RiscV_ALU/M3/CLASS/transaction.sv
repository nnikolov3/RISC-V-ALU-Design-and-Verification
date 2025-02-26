`ifndef TRANSACTION_SV
`define TRANSACTION_SV

`include "uvm_macros.svh"
`include "rv32i_alu_header.sv"
import uvm_pkg::*;

//-----------------------------------------------------------------------------
// Class: transaction
//
// Description:
//   The transaction class represents a single ALU operation, encapsulating 
//   all relevant inputs, outputs, and control signals. This class is used 
//   in UVM verification to transfer data between testbench components like 
//   the driver, monitor, and scoreboard. It also includes functions for 
//   setting values, performing ALU operations, and cloning transactions.
//-----------------------------------------------------------------------------
class transaction extends uvm_sequence_item;
    `uvm_object_utils(transaction)  // Register with UVM factory

    //--------------------------------------------------------------------------
    // ALU Input Signals (Randomized)
    //
    // Description:
    //   These signals represent the primary inputs to the ALU, including
    //   control signals (`i_alu`), source registers (`i_rs1`, `i_rs2`),
    //   immediate value (`i_imm`), opcode (`i_opcode`), and clock enable (`i_ce`).
    //--------------------------------------------------------------------------
    rand bit [13:0] i_alu;       // ALU control signal
    rand bit [31:0] i_rs1;       // First operand
    rand bit [31:0] i_rs2;       // Second operand
    rand bit [31:0] i_imm;       // Immediate value
    rand bit [10:0] i_opcode;    // Opcode
    rand bit i_ce;               // Clock enable
    
    bit [31:0] verify_y;         // Expected ALU output for verification
	
    //--------------------------------------------------------------------------
    // Additional Input Signals (Control, Addressing, and Miscellaneous)
    //
    // Description:
    //   These signals include clock and reset, source register addresses,
    //   function field, program counter, destination register details, and
    //   pipeline control signals such as stall and flush.
    //--------------------------------------------------------------------------
    bit i_clk;                   // Clock signal
    bit i_rst_n;                 // Active-low reset signal
    bit [4:0] i_rs1_addr;        // Address for source register 1
    bit [2:0] i_funct3;          // Function field
    bit [`EXCEPTION_WIDTH-1:0] i_exception; // Exception signal
    bit [31:0] i_pc;             // Program counter
    bit [4:0] i_rd_addr;         // Destination register address
    bit i_stall;                 // Stall signal
    bit i_force_stall;           // Force stall signal
    bit i_flush;                 // Flush signal

    //--------------------------------------------------------------------------
    // Output Signals (For Monitoring and Verification)
    //
    // Description:
    //   These signals represent the outputs from the ALU, including register 
    //   addresses, operand values, immediate value, function field, opcode, 
    //   exception signals, computed ALU result, and control outputs such as 
    //   stall, flush, and write enable.
    //--------------------------------------------------------------------------
    bit [4:0] o_rs1_addr;        // Output source register address
    bit [31:0] o_rs1;            // Output value of the first operand
    bit [31:0] o_rs2;            // Output value of the second operand
    bit [11:0] o_imm;            // Output immediate value
    bit [2:0] o_funct3;          // Output function field
    bit [10:0] o_opcode;         // Output opcode
    bit [`EXCEPTION_WIDTH-1:0] o_exception; // Output exception signal
    bit [31:0] o_y;              // Output ALU result
    bit [31:0] o_pc;             // Output program counter
    bit [31:0] o_next_pc;        // Output next program counter
    bit o_change_pc;             // Flag indicating a change in PC
    bit o_wr_rd;                 // Write/read flag for destination register
    bit [4:0] o_rd_addr;         // Output destination register address
    bit [31:0] o_rd;             // Output data for destination register
    bit o_rd_valid;              // Validity flag for destination register data
    bit o_stall_from_alu;        // Stall signal from the ALU
    bit o_ce;                    // Clock enable output
    bit o_stall;                 // Stall signal output
    bit o_flush;                 // Flush signal output

    //--------------------------------------------------------------------------
    // Constructor: new
    //
    // Description:
    //   Initializes all input and output signals to default values.
    //
    // Parameters:
    //   name - The name of the transaction instance.
    //--------------------------------------------------------------------------
    function new(string name = "transaction");
        super.new(name); // Call parent class constructor
        i_alu    = 0;
        i_rs1    = 0;
        i_rs2    = 0;
        i_imm    = 0;
        i_opcode = 0;
        i_ce     = 0;
        verify_y = 0;
    endfunction

    //--------------------------------------------------------------------------
    // Function: set_values
    //
    // Description:
    //   Sets the values for the transaction, including ALU control index,
    //   opcode, operands, immediate value, and clock enable.
    //
    // Parameters:
    //   alu_idx - Index of the ALU operation
    //   opcode  - Opcode value
    //   rs1     - First operand value
    //   rs2     - Second operand value
    //   imm     - Immediate value
    //   ce      - Clock enable signal
    //--------------------------------------------------------------------------
    function void set_values(int alu_idx, bit [10:0] opcode, bit [31:0] rs1,
                             bit [31:0] rs2, bit [31:0] imm, bit ce);
        i_alu          = 0;
        i_alu[alu_idx] = 1;
        i_opcode       = opcode;
        i_rs1          = rs1;
        i_rs2          = rs2;
        i_imm          = imm;
        i_ce           = ce;
    endfunction

    //--------------------------------------------------------------------------
    // Function: alu_operation
    //
    // Description:
    //   Performs a simulated ALU operation based on the provided operands,
    //   immediate value, and ALU control signal. This function is used to 
    //   calculate the expected output for verification.
    //
    // Parameters:
    //   rs1      - First operand
    //   rs2      - Second operand
    //   imm      - Immediate value
    //   alu_ctrl - ALU control signal
    //
    // Returns:
    //   The expected ALU result.
    //--------------------------------------------------------------------------
    function bit [31:0] alu_operation(bit [31:0] rs1, bit [31:0] rs2,
                                      bit [31:0] imm, bit [13:0] alu_ctrl);
        case (alu_ctrl)
            14'b00000000000001: verify_y = rs1 + (i_opcode[0] ? imm : rs2);
            14'b00000000000010: verify_y = rs1 - (i_opcode[0] ? imm : rs2);
            14'b00000000000100: verify_y = rs1 & (i_opcode[0] ? imm : rs2);
            14'b00000000001000: verify_y = rs1 | (i_opcode[0] ? imm : rs2);
            14'b00000000010000: verify_y = rs1 ^ (i_opcode[0] ? imm : rs2);
            14'b00000000100000: verify_y = rs1 << (i_opcode[0] ? imm[4:0] : rs2[4:0]);
            14'b00000001000000: verify_y = rs1 >> (i_opcode[0] ? imm[4:0] : rs2[4:0]);
            14'b00000010000000: verify_y = $signed(rs1) >>> (i_opcode[0] ? imm[4:0] : rs2[4:0]);
            14'b00000100000000: verify_y = $signed(rs1) < $signed(rs2) ? 32'h1 : 32'h0;
            14'b00001000000000: verify_y = rs1 < rs2 ? 32'h1 : 32'h0;
            default: verify_y = 0;
        endcase
        return verify_y;
    endfunction

    //--------------------------------------------------------------------------
    // Function: clone
    //
    // Description:
    //   Creates and returns a copy of the transaction object.
    //
    // Returns:
    //   A cloned transaction object.
    //--------------------------------------------------------------------------
    function transaction clone();
        transaction clone_trans;
        clone_trans = transaction::type_id::create("transaction");
        clone_trans.i_alu    = this.i_alu;
        clone_trans.i_rs1    = this.i_rs1;
        clone_trans.i_rs2    = this.i_rs2;
        clone_trans.i_imm    = this.i_imm;
        clone_trans.i_opcode = this.i_opcode;
        clone_trans.i_ce     = this.i_ce;
        clone_trans.verify_y = this.verify_y;
        return clone_trans;
    endfunction

endclass

`endif
