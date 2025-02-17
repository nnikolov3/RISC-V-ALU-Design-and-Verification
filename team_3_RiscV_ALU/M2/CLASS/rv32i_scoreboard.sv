`include "rv32i_header.sv"
`include "transaction.sv"

class scoreboard;
	mailbox mon_in2scb;
	mailbox mon_out2scb;
	
	//bit i_clk_fifo[$];
	//bit i_rst_n_fifo[$];
	bit [`ALU_WIDTH-1:0] i_alu_fifo[$];
	bit [4:0] i_rs1_addr_fifo[$];
	bit [31:0] i_rs1_fifo[$];
	bit [31:0] i_rs2_fifo[$];
	bit [31:0] i_imm_fifo[$];
	bit [2:0] i_funct3_fifo[$];
	bit [`OPCODE_WIDTH-1:0] i_opcode_fifo[$];
	bit [`EXCEPTION_WIDTH-1:0] i_exception_fifo[$];
	bit [31:0] i_pc_fifo[$];
	bit [4:0] i_rd_addr_fifo[$];
	bit i_ce_fifo[$];
	bit i_stall_fifo[$];
	bit i_force_stall_fifo[$];
	bit i_flush_fifo[$];
	
	function new(mailbox mon_in2scb, mailbox mon_out2scb);
		this.mon_in2scb = mon_in2scb;
		this.mon_out2scb = mon_out2scb;
	endfunction
	
	task main;
		fork
			get_input();
			get_output();
		join_none;
	endtask
	
	task get_input();
		transaction tx;
		forever begin
			mon_in2scb.get(tx);
			
			//retrieve all inputs from transaction
			//i_clk_fifo.push_back(tx.i_clk);
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
	
	task get_output();
		transaction tx;
		bit rst_n;
		bit [`ALU_WIDTH-1:0] alu;
		bit [4:0] rs1_addr;
		bit [31:0] rs1;
		bit [31:0] rs2;
		bit [31:0] imm;
		bit [2:0] funct3;
		bit [`OPCODE_WIDTH-1:0] opcode;
		bit [`EXCEPTION_WIDTH-1:0] exception;
		bit [31:0] pc;
		bit [4:0] rd_addr;
		bit ce;
		bit stall;
		bit force_stall;
		bit flush;
		bit [31:0] out; 
		bit [31:0] rd_temp;
		bit [31:0] sum;
		bit error;
		bit [31:0] rd_d;
		bit wr_rd_d;
		bit rd_valid;
		
		forever begin
			mon_out2scb.get(tx);
			error = 0;
			wr_rd_d = 0;
			rd_d = 0;
			rst_n = i_rst_n.pop_front();
			alu = i_alu_fifo.pop_front();
			rs1_addr = i_rs1_addr_fifo.pop_front();
			rs1 = i_rs1_fifo.pop_front();
			rs2 = i_rs2_fifo.pop_front();
			imm = i_imm_fifo.pop_front();
			funct3 = i_funct3_fifo.pop_front();
			opcode = i_opcode_fifo.pop_front();
			exception = i_exception_fifo.pop_front();
			pc = i_pc_fifo.pop_front();
			rd_addr = i_rd_addr_fifo.pop_front();
			ce = i_ce_fifo.pop_front();
			stall = i_stall_fifo.pop_front();
			force_stall = i_force_stall_fifo.pop_front();
			flush = i_flush_fifo.pop_front();
			
			if(rst_n === 0				&&
				tx.o_exception !== 0	&&
				tx.o_ce !== 0			&&
				tx.o_stall_from_alu !== 0) begin
				
				error = 1;
			end
				
			else begin
				out = alu_operation( ((opcode[`JAL] || opcode[`AUIPC]) ? pc : rs1),
										((opcode[`RTYPE] || opcode[`BRANCH]) ? rs2 : imm),
										alu
										);
				
				
				if(!flush) begin
					if(opcode[`RTYPE] || opcode[`ITYPE]) begin
						rd_temp = out;
					end
					
					if(opcode[`BRANCH] && out			&&
						(pc + imm !== tx.o_next_pc 	||
						ce !== tx.o_change_pc		||
						ce !== tx.o_flush)
						) begin
							error = 1;
					end
					
					if(opcode[`JAL] || opcode[`JALR]) begin
						if(opcode[`JALR] === 1) begin
							sum = rs1 + imm;
						end
						if(sum !== tx.o_next_pc 	||
							ce !== tx.o_change_pc	||
							ce !== tx.o_flush
							) begin
							error = 1;
						end
						
						rd_d = pc + 4;
						
					end
				end
				
				if(opcode[`LUI]) begin
					rd_d = imm;
				end
				
				if(opcode[`AUIPC]) begin
					rd_d = pc + imm;
				end
				
				wr_rd_d = (opcode[`BRANCH] 	|| 
							opcode[`STORE] 	|| 
							(opcode[`SYSTEM]&&
							funct3 == 0)	||
							opcode[`FENCE]
							) ?
							0 : 1;
				
				rd_valid = (opcode[`LOAD] 	|| 
							(opcode[`SYSTEM]&&
							funct3 != 0)	
							) ?
							0 : 1;
				
				if(tx.o_stall !== (stall || force_stall) && !flush) begin
					error = 1;
				end
				
				if( !(tx.o_stall || stall) &&
					ce === 1
				) begin
					
					if( opcode !== tx.o_opcode 			||
						exception !== tx.o_exception 	||
						out !== tx.o_y					||
						rs1_addr !== tx.o_rs1_addr		||
						rs1 !== tx.o_rs1				||
						rs2 !== tx.o_rs2				||
						rd_addr !== tx.o_rd_addr		||
						imm !== tx.o_imm				||
						funct3 !== tx.o_funct3			||
						rd_d !== tx.o_rd				||
						rd_valid !== tx.o_rd_valid		||
						wr_rd_d !== tx.o_wr_rd			||
						(opcode[`STORE] || opcode[`LOAD]) == tx.o_stall_from_alu ||
						pc !== tx.o_pc
					
					) begin
						error = 1;
					end	
				end
				
				if(flush && !(tx.o_stall || stall) &&
					tx.o_ce !== 0) begin
					error = 1;
				end
				
				else if (!(tx.o_stall || stall) &&
						tx.o_ce !== ce) begin
					
					error = 1;
				end
				
				else if (tx.o_stall &&
						tx.o_ce !== 0) begin
					error = 1;
				end
				
			end
				
			
			if(error == 1) begin
				$displayh("**********ERROR**********",
						"\ni_rst_n = ", rst_n,
						"\ni_alu = ", i_alu,
						"\ni_rs1_addr = ", i_rs1_addr,
						"\ni_rs1 = ", i_rs1,
						"\ni_rs2 = ", i_rs2,
						"\ni_imm = ", i_imm,
						"\ni_funct3 = ", i_funct3,
						"\ni_opcode = ", i_opcode,
						"\ni_exception = ", i_exception,
						"\ni_pc = ", i_pc,
						"\ni_rd_addr = ", i_rd_addr,
						"\ni_ce = ", i_ce,
						"\ni_stall = ", i_stall,
						"\ni_force_stall = ", i_force_stall,
						"\ni_flush = ", i_flush,
						"\no_rs1_addr = ", tx.o_rs1_addr,
						"\no_rs1 = ", tx.o_rs1,
						"\no_rs2 = ", tx.o_rs2,
						"\no_imm = ", tx.o_imm,
						"\no_funct3 = ", tx.o_funct3,
						"\no_opcode = ", tx.o_opcode,
						"\no_exception = ", tx.o_exception,
						"\no_y = ", tx.o_y,
						"\no_pc = ", tx.o_pc,
						"\no_next_pc = ", tx.o_next_pc,
						"\no_change_pc = ", tx.o_change_pc,
						"\no_wr_rd = ", tx.o_wr_rd,
						"\no_rd_addr = ", tx.o_rd_addr,
						"\no_rd = ", tx.o_rd,
						"\no_rd_valid = ", o_rd_valid,
						"\no_stall_from_alu = ", tx.o_stall_from_alu,
						"\no_ce = ", tx.o_ce,
						"\no_stall = ", tx.o_stall,
						"\no_flush = ", tx.o_flush
						);
			end
			
		end
		
	endtask
	
	function automatic logic [31:0] alu_operation(
		input logic [31:0] a, input logic [31:0] b,
		input logic [`ALU_WIDTH-1:0] op // 6-bit operation code to cover given values
);
		//because this is one hot encoded, this will return the location of the highest bit
		case ($clog2(op))
			0:  return a + b;  // ADD
			1:  return a - b;  // SUB
			2:  return (a < b) ? 1 : 0;  // SLT (Signed Less Than)
			3:  return (unsigned'(a) < unsigned'(b)) ? 1 : 0;  // SLTU (Unsigned Less Than)
			4:  return a ^ b;  // XOR
			5:  return a | b;  // OR
			6:  return a & b;  // AND
			7:  return a << b[4:0];  // SLL
			8:  return a >> b[4:0];  // SRL
			9:  return $signed(a) >>> b[4:0];  // SRA
			10: return (a == b) ? 1 : 0;  // EQ
			11: return (a != b) ? 1 : 0;  // NEQ
			12: return (a >= b) ? 1 : 0;  // GE
			13: return (unsigned'(a) >= unsigned'(b)) ? 1 : 0;  // GEU

			default: return 0;  // Invalid operation
		endcase
	endfunction
	
endclass
			
			
			
			
			
			




