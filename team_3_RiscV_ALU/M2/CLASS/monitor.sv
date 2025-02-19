//-----------------------------------------------------------------------------
// Class: monitor_in
//
// Description:
//   This monitor samples input signals from the DUT through the virtual
//   interface (vif) and packages them into a transaction object. The
//   transaction is then sent to the scoreboard via the mon_in2scb mailbox.
//-----------------------------------------------------------------------------

`include "rv32i_alu_header.sv"
`include "transaction.sv"
class monitor_in;
    // Virtual interface instance to access DUT input signals.
    virtual alu_if vif;
    // Mailbox to send captured input transactions to the scoreboard.
    mailbox #(transaction) mon_in2scb = new();

    //-------------------------------------------------------------------------
    // Constructor: new
    //
    // Description:
    //   Initializes the monitor_in with a virtual interface and mailbox.
    //
    // Parameters:
    //   vif        - Virtual interface instance connected to the DUT.
    //   mon_in2scb - Mailbox to send transactions to the scoreboard.
    //-------------------------------------------------------------------------
    function new(virtual alu_if vif, mailbox#(transaction) mon_in2scb);
        this.vif        = vif;
        this.mon_in2scb = mon_in2scb;
    endfunction

    //-------------------------------------------------------------------------
    // Task: main
    //
    // Description:
    //   Continuously samples the input signals on every positive clock edge.
    //   If the clock enable signal (i_ce) is asserted, it captures the inputs,
    //   populates a transaction, and sends it via the mailbox.
    //-------------------------------------------------------------------------
    task main;
        $display("monitor_in started");
        forever begin
            // Create a new transaction object for each sample.
            transaction tx = new();
            // Wait for the next positive clock edge.
            @(posedge vif.i_clk);
            // Sample the inputs only if clock enable is asserted.
            if (vif.i_ce) begin
                tx.i_clk         = vif.i_clk;
                tx.i_rst_n       = vif.i_rst_n;
                tx.i_alu         = vif.i_alu;
                tx.i_rs1_addr    = vif.i_rs1_addr;
                tx.i_rs1         = vif.i_rs1;
                tx.i_rs2         = vif.i_rs2;
                tx.i_imm         = vif.i_imm;
                tx.i_funct3      = vif.i_funct3;
                tx.i_opcode      = vif.i_opcode;
                tx.i_exception   = vif.i_exception;
                tx.i_pc          = vif.i_pc;
                tx.i_rd_addr     = vif.i_rd_addr;
                tx.i_ce          = vif.i_ce;
                tx.i_stall       = vif.i_stall;
                tx.i_force_stall = vif.i_force_stall;
                tx.i_flush       = vif.i_flush;

                // Send the populated transaction to the scoreboard.
                mon_in2scb.put(tx);
            end
        end
        $display("monitor_in finished");
    endtask
endclass

//-----------------------------------------------------------------------------
// Class: monitor_out
//
// Description:
//   This monitor samples the output signals from the DUT via the virtual
//   interface (vif), packages them into a transaction object, and sends the
//   transaction to the scoreboard through the mon_out2scb mailbox. It also
//   keeps a count of the output transactions processed.
//-----------------------------------------------------------------------------
class monitor_out;
    // Counter for the number of output transactions captured.
    int tx_count = 0;
    // Virtual interface instance to access DUT output signals.
    virtual alu_if vif;
    // Mailbox to send captured output transactions to the scoreboard.
    mailbox #(transaction) mon_out2scb = new();

    //-------------------------------------------------------------------------
    // Constructor: new
    //
    // Description:
    //   Initializes the monitor_out with a virtual interface and mailbox.
    //
    // Parameters:
    //   vif         - Virtual interface instance connected to the DUT.
    //   mon_out2scb - Mailbox to send transactions to the scoreboard.
    //-------------------------------------------------------------------------
    function new(virtual alu_if vif, mailbox#(transaction) mon_out2scb);
        this.vif         = vif;
        this.mon_out2scb = mon_out2scb;
    endfunction

    //-------------------------------------------------------------------------
    // Task: main
    //
    // Description:
    //   Continuously samples the output signals from the DUT on every positive
    //   clock edge. It waits until the output valid signal (o_rd_valid) is asserted,
    //   then captures the outputs into a transaction, sends it via the mailbox,
    //   and increments the transaction count.
    //-------------------------------------------------------------------------
    task main;
        $display("monitor_out started");
        forever begin
            // Create a new transaction object for each output sample.
            transaction tx = new();
            // Wait for the next positive clock edge.
            @(posedge vif.i_clk);
            // Wait until the output valid signal is asserted.
            wait (vif.o_ce);

            // Capture DUT output signals into the transaction.
            tx.o_rs1_addr       = vif.o_rs1_addr;
            tx.o_rs1            = vif.o_rs1;
            tx.o_rs2            = vif.o_rs2;
            tx.o_imm            = vif.o_imm;
            tx.o_funct3         = vif.o_funct3;
            tx.o_opcode         = vif.o_opcode;
            tx.o_exception      = vif.o_exception;
            tx.o_y              = vif.o_y;
            tx.o_pc             = vif.o_pc;
            tx.o_next_pc        = vif.o_next_pc;
            tx.o_change_pc      = vif.o_change_pc;
            tx.o_wr_rd          = vif.o_wr_rd;
            tx.o_rd_addr        = vif.o_rd_addr;
            tx.o_rd             = vif.o_rd;
            tx.o_rd_valid       = vif.o_rd_valid;
            tx.o_stall_from_alu = vif.o_stall_from_alu;
            tx.o_ce             = vif.o_ce;
            tx.o_stall          = vif.o_stall;
            tx.o_flush          = vif.o_flush;

            // Send the populated transaction to the scoreboard.
            mon_out2scb.put(tx);
            // Increment the transaction count.
            tx_count++;
        end
        $display("monitor_out finished");
    endtask
endclass
