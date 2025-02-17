// Interface and Driver for RISC-V ALU

interface rv32i_alu_if (input logic i_clk, input logic i_rst_n);
    // Input signals
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

    // Enhanced clocking block for driver with skew control
    clocking drv_cb @(posedge i_clk);
        default input #1step output #1step;  // Add setup/hold time
        output i_alu, i_rs1_addr, i_rs1, i_rs2, i_imm, i_funct3;
        output i_opcode, i_exception, i_pc, i_rd_addr;
        output i_ce, i_stall, i_force_stall, i_flush;
        input o_stall_from_alu, o_ce, o_stall, o_flush;  // Response signals
    endclocking

    // Enhanced clocking block for monitor
    clocking mon_cb @(posedge i_clk);
        default input #1step output #1step;
        input i_alu, i_rs1_addr, i_rs1, i_rs2, i_imm, i_funct3;
        input i_opcode, i_exception, i_pc, i_rd_addr;
        input i_ce, i_stall, i_force_stall, i_flush;
        input o_rs1_addr, o_rs1, o_rs2, o_imm, o_funct3;
        input o_opcode, o_exception, o_y, o_pc, o_next_pc;
        input o_change_pc, o_wr_rd, o_rd_addr, o_rd;
        input o_rd_valid, o_stall_from_alu, o_ce, o_stall, o_flush;
    endclocking

    // Modports with explicit signal directions
    modport driver (
        clocking drv_cb,
        input i_clk, i_rst_n,
        import task drive_reset()
    );

    modport monitor (
        clocking mon_cb,
        input i_clk, i_rst_n,
        import task check_protocol()
    );

    // Shared tasks for protocol checking
    task automatic drive_reset();
        i_alu <= 0;
        i_rs1_addr <= 0;
        i_rs1 <= 0;
        i_rs2 <= 0;
        i_imm <= 0;
        i_funct3 <= 0;
        i_opcode <= 0;
        i_exception <= 0;
        i_pc <= 0;
        i_rd_addr <= 0;
        i_ce <= 0;
        i_stall <= 0;
        i_force_stall <= 0;
        i_flush <= 0;
    endtask

    task automatic check_protocol();
        // Protocol checking implementations
    endtask
endinterface

// Enhanced Driver with Response Handling and Timing Control
class rv32i_alu_driver extends uvm_driver #(rv32i_alu_transaction);
    `uvm_component_utils(rv32i_alu_driver)

    virtual rv32i_alu_if vif;
    rv32i_alu_config cfg;  // Configuration object
    uvm_analysis_port #(rv32i_alu_response) rsp_port;  // For response handling

    // Timing control parameters
    protected int min_delay = 0;
    protected int max_delay = 5;
    protected bit enable_delays = 1;

    // Response handling
    typedef enum {
        RESP_OK,
        RESP_STALL,
        RESP_ERROR
    } response_type_e;

    // Constructor
    function new(string name = "rv32i_alu_driver", uvm_component parent = null);
        super.new(name, parent);
        rsp_port = new("rsp_port", this);
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual rv32i_alu_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not found")
        if (!uvm_config_db#(rv32i_alu_config)::get(this, "", "cfg", cfg))
            `uvm_warning("NOCFG", "Configuration not found, using defaults")
    endfunction

    // Enhanced run phase with response handling
    virtual task run_phase(uvm_phase phase);
        rv32i_alu_response rsp;

        // Initial reset
        @(negedge vif.i_rst_n);
        reset_signals();
        @(posedge vif.i_rst_n);

        forever begin
            seq_item_port.get_next_item(req);

            // Pre-drive checks
            if (!check_transaction_validity(req)) begin
                `uvm_error("INVALID_TRANS", "Invalid transaction received")
                send_error_response(req);
                seq_item_port.item_done();
                continue;
            }

            // Drive the transaction
            fork
                begin
                    drive_transaction(req);
                    collect_response(rsp);
                    rsp_port.write(rsp);
                end
                begin
                    protocol_checker();
                end
            join_any

            seq_item_port.item_done();
        end
    endtask

    // Enhanced drive transaction with timing control
    protected virtual task drive_transaction(rv32i_alu_transaction trans);
        int delay;

        if (enable_delays) begin
            if (!std::randomize(delay) with {
                delay inside {[min_delay:max_delay]};
            }) begin
                `uvm_error("RANDOMIZATION", "Failed to randomize delay")
            end
            repeat(delay) @(posedge vif.i_clk);
        end

        // Drive control signals
        vif.drv_cb.i_ce <= trans.ce;
        vif.drv_cb.i_stall <= trans.stall;
        vif.drv_cb.i_force_stall <= trans.force_stall;
        vif.drv_cb.i_flush <= trans.flush;

        // Drive ALU operation and opcode
        vif.drv_cb.i_alu <= trans.alu;
        vif.drv_cb.i_opcode <= trans.opcode;

        // Drive operands
        vif.drv_cb.i_rs1_addr <= trans.rs1_addr;
        vif.drv_cb.i_rs1 <= trans.rs1;
        vif.drv_cb.i_rs2 <= trans.rs2;
        vif.drv_cb.i_imm <= trans.imm;

        // Drive other control signals
        vif.drv_cb.i_funct3 <= trans.funct3;
        vif.drv_cb.i_exception <= trans.exception;
        vif.drv_cb.i_pc <= trans.pc;
        vif.drv_cb.i_rd_addr <= trans.rd_addr;

        // Wait for response
        @(posedge vif.i_clk);
        while (vif.drv_cb.o_stall === 1'b1) begin
            @(posedge vif.i_clk);
        end
    endtask

    // Enhanced protocol checker
    protected virtual task protocol_checker();
        fork
            // Check 1: ALU operation one-hot
            forever begin
                @(posedge vif.i_clk);
                if (vif.drv_cb.i_ce === 1'b1 && $onehot(vif.drv_cb.i_alu) !== 1'b1) begin
                    `uvm_error("PROTOCOL", "Multiple ALU operations selected")
                end
            end

            // Check 2: Opcode one-hot
            forever begin
                @(posedge vif.i_clk);
                if (vif.drv_cb.i_ce === 1'b1 && $onehot(vif.drv_cb.i_opcode) !== 1'b1) begin
                    `uvm_error("PROTOCOL", "Multiple opcodes selected")
                end
            end

            // Check 3: Stall-flush interaction
            forever begin
                @(posedge vif.i_clk);
                if (vif.drv_cb.i_stall === 1'b1 && vif.drv_cb.i_flush === 1'b1) begin
                    `uvm_warning("PROTOCOL", "Simultaneous stall and flush")
                end
            end

            // Check 4: Clock enable stability
            forever begin
                @(posedge vif.i_clk);
                if ($isunknown(vif.drv_cb.i_ce)) begin
                    `uvm_error("PROTOCOL", "Clock enable is unknown")
                end
            end

            // Check 5: Reset behavior
            forever begin
                @(negedge vif.i_rst_n);
                if (vif.drv_cb.i_ce !== 1'b0) begin
                    `uvm_error("PROTOCOL", "CE not cleared on reset")
                end
            end
        join_none
    endtask

    // Response collection and handling
    protected virtual task collect_response(ref rv32i_alu_response rsp);
        rsp = rv32i_alu_response::type_id::create("rsp");
        rsp.set_id_info(req);

        case ({vif.drv_cb.o_stall, vif.drv_cb.o_exception})
            2'b00: rsp.status = RESP_OK;
            2'b10: rsp.status = RESP_STALL;
            default: rsp.status = RESP_ERROR;
        endcase

        rsp.result = vif.drv_cb.o_y;
        rsp.next_pc = vif.drv_cb.o_next_pc;
        rsp.rd_value = vif.drv_cb.o_rd;
    endtask

    // Helper functions
    protected function bit check_transaction_validity(rv32i_alu_transaction trans);
        // Add comprehensive transaction checking
        if (trans == null) return 0;
        if (!$onehot(trans.alu)) return 0;
        if (!$onehot(trans.opcode)) return 0;
        // Add more checks as needed
        return 1;
    endfunction

    protected task send_error_response(rv32i_alu_transaction trans);
        rv32i_alu_response rsp;
        rsp = rv32i_alu_response::type_id::create("rsp");
        rsp.set_id_info(trans);
        rsp.status = RESP_ERROR;
        rsp_port.write(rsp);
    endtask
endclass