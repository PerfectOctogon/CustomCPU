`default_nettype none

module cpu(
    input wire clk,
    input wire reset,
    output reg [15:0] out_val,
    output wire halted
);

    // Write selection
    localparam wb_ALU = 2'b00;
    localparam wb_IMM = 2'b01;
    localparam wb_RSC = 2'b10;
    localparam wb_MEM = 2'b11;

    // PC wires
    wire [15:0] pc_out;

    // IMEM wires
    wire [15:0] imem_instr_out;

    // Decoder wires
    wire dec_is_alu_b_imm;
    wire [3:0] dec_alu_op;
    wire dec_is_reg_write;
    wire [1:0] dec_write_sel;
    wire dec_is_mem_write;
    wire dec_is_load;
    wire dec_is_jump;
    wire dec_is_jz;
    wire dec_is_out;
    wire dec_is_halt;

    // Control unit wires
    wire ctrl_rd_is_zero;
    wire ctrl_reg_write_en;
    wire ctrl_mem_write_en;
    wire ctrl_pc_enable;
    wire ctrl_pc_load;
    wire ctrl_out_en;
    wire ctrl_halted;

    // Register file wires
    wire [15:0] reg_read_data_a;
    wire [15:0] reg_read_data_b;

    // Alu wires
    wire [15:0] alu_result;
    wire alu_zero;
    wire alu_overflow;

    // Dmem wires
    wire [15:0] dmem_read_data;

    reg [15:0] write_data;

    // assignments
    always @(*) begin
        if (dec_write_sel == wb_ALU) begin
            write_data = alu_result;
        end
        else if (dec_write_sel == wb_IMM) begin
            write_data = imem_instr_out[4:0];
        end
        else if (dec_write_sel == wb_MEM) begin
            write_data = dmem_read_data;
        end
        else begin
            write_data = reg_read_data_b;
        end
    end

    always @(posedge clk) begin
        out_val <= (ctrl_out_en) ? reg_read_data_a : out_val;
    end

    assign ctrl_rd_is_zero = (reg_read_data_a == 0) ? 1 : 0;
    assign halted = ctrl_halted;

    // module declarations

    pc mod_pc(
        .reset          (reset),
        .enable         (ctrl_pc_enable),
        .load           (ctrl_pc_load),
        .clk            (clk),
        .jump_addr      (reg_read_data_b),
        .pc_out         (pc_out)
    );

    imem mod_imem(
        .clk            (clk),
        .addr           (pc_out),
        .instr          (imem_instr_out)
    );

    decoder mod_decoder(
        .instr          (imem_instr_out),
        .alu_op         (dec_alu_op),
        .is_alu_b_imm   (dec_is_alu_b_imm),
        .is_reg_write   (dec_is_reg_write),
        .write_sel      (dec_write_sel),
        .is_mem_write   (dec_is_mem_write),
        .is_load        (dec_is_load),
        .is_jump        (dec_is_jump),
        .is_jz          (dec_is_jz),
        .is_out         (dec_is_out),
        .is_halt        (dec_is_halt)
    );

    control mod_control(
        .clk            (clk),
        .reset          (reset),
        .is_reg_write   (dec_is_reg_write),
        .is_mem_write   (dec_is_mem_write),
        .is_jump        (dec_is_jump),
        .is_jz          (dec_is_jz),
        .is_out         (dec_is_out),
        .is_halt        (dec_is_halt),
        .rd_is_zero     (ctrl_rd_is_zero),
        .reg_write_en   (ctrl_reg_write_en),
        .mem_write_en   (ctrl_mem_write_en),
        .pc_enable      (ctrl_pc_enable),
        .pc_load        (ctrl_pc_load),
        .out_en         (ctrl_out_en),
        .halted         (ctrl_halted)
    );

    // load = store into register from memory
    // store = store into memory from register
    regfile mod_regfile(
        .clk            (clk),
        .read_addr_a    (imem_instr_out[9:5]),
        .read_addr_b    (imem_instr_out[4:0]),
        .write_enable   (ctrl_reg_write_en),
        .write_addr     (imem_instr_out[9:5]),
        // is this data from memory or is it from a register or immediate(load vs mov)
        // choose using write_sel
        .write_data     (write_data),
        .reset          (reset),
        .read_data_a    (reg_read_data_a),
        .read_data_b    (reg_read_data_b)
    );

    alu mod_alu(
        .a              (reg_read_data_a),
        .b              (dec_is_alu_b_imm ? imem_instr_out[4:0] : reg_read_data_b),
        .op             (dec_alu_op),
        .result         (alu_result),
        .zero           (alu_zero),
        .overflow       (alu_overflow)
    );

    dmem mod_dmem(
        .clk            (clk),
        .addr           (reg_read_data_b),
        .write_enable   (ctrl_mem_write_en),
        // this will always be a register read
        .write_data     (reg_read_data_a),
        .read_data      (dmem_read_data)
    );

endmodule