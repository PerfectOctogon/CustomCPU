`default_nettype none

module cpu(
    input wire clk
);

    // PC wires
    wire pc_reset;
    wire pc_enable;
    wire pc_load;
    wire [15:0] pc_jump_addr;
    reg [15:0] pc_out;

    // IMEM wires
    wire imem_instr_out

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
    wire ctrl_reset;
    wire ctrl_rd_is_zero;
    wire ctrl_reg_write_en;
    wire ctrl_mem_write_en;
    wire ctrl_pc_enable;
    wire ctrl_pc_load;
    wire ctrl_out_en;
    wire ctrl_halted;

    // Register file wires
    wire reg_reset;
    wire reg_write_addr;
    wire [15:0] reg_write_data;
    wire [15:0] reg_read_data_a;
    wire [15:0] reg_read_data_b;

    // Alu wires
    wire [15:0] alu_result;
    wire alu_zero;
    wire alu_overflow;

    // Dmem wires
    wire dmem_read_data;

    pc mod_pc(
        .reset          (pc_reset),
        .enable         (pc_enable),
        .load           (pc_load),
        .clk            (clk),
        .jump_addr      (pc_jump_addr),
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
        .reset          (ctrl_reset),
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
    // write address = dec_is_load ? 
    regfile mod_regfile(
        .clk            (clk),
        .read_addr_a    (imem_instr_out[9:5]),
        .read_addr_b    (imem_instr_out[4:0]),
        .write_enable   (ctrl_reg_write_en & (~ctrl_mem_write_en)),
        .write_addr     (imem_instr_out[[9:5]]),
        // is this data from memory or is it from a register or immediate(load vs mov)
        // choose using write_sel
        .write_data     (),
        .reset          (ctrl_reset),
        .read_data_a    (reg_read_data_a),
        .read_data_b    (reg_read_data_b)
    );

    alu mod_alu(
        .a              (imem_instr_out[9:5]),
        // use write_sel to choose from immediate vs register
        .b              (),
        .op             (imem_instr_out[12:10]),
        .result         (alu_result),
        .zero           (alu_zero),
        .overflow       (alu_overflow)
    );

    dmem mod_dmem(
        .clk            (clk),
        .addr           (imem_instr_out[9:5]),
        .write_enable   (ctrl_mem_write_en & (~ctrl_reg_write_en)),
        // this will always be a register read
        .write_data     (),
        .read_data      (dmem_read_data)
    );

endmodule