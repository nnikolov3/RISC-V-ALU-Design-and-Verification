`include "rv32i_header.sv"
`include "transaction.sv"

class monitor_in;
	virtual intf vif;
	mailbox mon_in2scb;
	
	function new(virtual intf vif, mailbox mon_in2scb);
		this.vif = vif;
		this.mon_in2scb = mon_in2scb;
	endfunction
	
	task main;
		$display("monitor_in started");
		forever begin
			transaction tx = new();
			@(posedge vif.i_clk);
			if(vif.i_ce) begin
				tx.i_clk = vif.i_clk;
				tx.i_rst_n = vif.i_rst_n;
				tx.i_alu = vif.i_alu;
				tx.i_rs1_addr = vif.i_rs1_addr;
				tx.i_rs1 = vif.i_rs1;
				tx.i_rs2 = vif.i_rs2;
				tx.i_imm = vif.i_imm;
				tx.i_funct3 = vif.i_funct3;
				tx.i_opcode = vif.i_opcode;
				tx.i_exception = vif.i_exception;
				tx.i_pc = vif.i_pc;
				tx.i_rd_addr = vif.i_rd_addr;
				tx.i_ce = vif.i_ce;
				tx.i_stall = vif.i_stall;
				tx.i_force_stall = vif.i_force_stall;
				tx.i_flush = vif.i_flush;

				mon_in2scb.put(tx);
			end
		end
		$display("monitor_in finished");
	endtask
endclass
			

class monitor_out;
	int tx_count=0;
	virtual intf vif;
	mailbox mon_out2scb;
	
	function new(virtual intf vif, mailbox mon_out2scb);
		this.vif = vif;
		this.mon_out2scb = mon_out2scb;
	endfunction
			
	task main;
		$display("monitor_out started");
		forever begin
			transaction tx = new();
			@(posedge vif.i_clk);
			wait(vif.o_rd_valid)
			tx.o_rs1_addr = vif.o_rs1_addr;
			tx.o_rs1 = vif.o_rs1;
			tx.o_rs2 = vif.o_rs2;
			tx.o_imm = vif.o_imm;
			tx.o_funct3 = vif.o_funct3;
			tx.o_opcode = vif.o_opcode;
			tx.o_exception = vif.o_exception;
			tx.o_y = vif.o_y;
			tx.o_pc = vif.o_pc;
			tx.o_next_pc = vif.o_next_pc;
			tx.o_change_pc = vif.o_change_pc;
			tx.o_wr_rd = vif.o_wr_rd;
			tx.o_rd_addr = vif.o_rd_addr;
			tx.o_rd = vif.o_rd;
			tx.o_rd_valid = vif.o_rd_valid;
			tx.o_stall_from_alu = vif.o_stall_from_alu;
			tx.o_ce = vif.o_ce;
			tx.o_stall = vif.o_stall;
			tx.o_flush = vif.o_flush;
			mon_out2scb.put(tx);
			tx_count++;
		end
		$display("monitor_out finished");
	endtask
endclass