/*
ECE593: Milestone 1, Group 3
File name : generator.sv
File version : 1.0
Class name : generator
Description : 
This class generates randomized transactions for the RISC-V ALU design under verification.
*/

`include "transaction.sv"

class generator;

mailbox gen2drive;

rand transaction txn;
event ended;
int repeat_count;


function  new(mailbox gen2drive);
	this.gen2drive = gen2drive;
endfunction 


task main ();
	repeat (repeat_count) begin
		
	txn = new ();
	if (!txn.randomize()) $fatal ("Failed to randomize ALU transaction!");
   
	txn.display ("generator");
	gen2drive.put (txn);

end
  
-> ended;
endtask
endclass 	