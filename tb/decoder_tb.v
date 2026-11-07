`default_nettype none

module decoder_tb;

    reg  [15:0] instr;
    wire [3:0]  alu_op;
    wire        is_alu_b_imm, is_reg_write;
    wire [1:0]  write_sel;
    wire        is_mem_write, is_load, is_jump, is_jz, is_out, is_halt;

    integer errors = 0;
    integer tests  = 0;

    decoder dut (
        .instr(instr),
        .alu_op(alu_op), .is_alu_b_imm(is_alu_b_imm), .is_reg_write(is_reg_write),
        .write_sel(write_sel), .is_mem_write(is_mem_write), .is_load(is_load),
        .is_jump(is_jump), .is_jz(is_jz), .is_out(is_out), .is_halt(is_halt)
    );

    // write_sel codes, matching the decoder
    localparam WB_ALU = 2'b00;
    localparam WB_IMM = 2'b01;
    localparam WB_RS  = 2'b10;
    localparam WB_MEM = 2'b11;

    // Apply an instruction and check ALL ten outputs, not just the ones expected to be 1
    task check;
        input [15:0]     t_instr;
        input [3:0]      e_alu_op;
        input            e_b_imm, e_reg_write;
        input [1:0]      e_write_sel;
        input            e_mem_write, e_load, e_jump, e_jz, e_out, e_halt;
        input [8*24-1:0] label;
        begin
            instr = t_instr;
            #1;
            tests = tests + 1;
            if ({alu_op, is_alu_b_imm, is_reg_write, write_sel, is_mem_write,
                 is_load, is_jump, is_jz, is_out, is_halt}
                !==
                {e_alu_op, e_b_imm, e_reg_write, e_write_sel, e_mem_write,
                 e_load, e_jump, e_jz, e_out, e_halt}) begin
                $display("FAIL  %0s (instr=%h)", label, t_instr);
                $display("        got:      alu_op=%b b_imm=%b reg_write=%b write_sel=%b mem_write=%b load=%b jump=%b jz=%b out=%b halt=%b",
                         alu_op, is_alu_b_imm, is_reg_write, write_sel, is_mem_write,
                         is_load, is_jump, is_jz, is_out, is_halt);
                $display("        expected: alu_op=%b b_imm=%b reg_write=%b write_sel=%b mem_write=%b load=%b jump=%b jz=%b out=%b halt=%b",
                         e_alu_op, e_b_imm, e_reg_write, e_write_sel, e_mem_write,
                         e_load, e_jump, e_jz, e_out, e_halt);
                errors = errors + 1;
            end else begin
                $display("pass  %0s (instr=%h)", label, t_instr);
            end
        end
    endtask

    initial begin
        //                                             alu_op   b_imm reg_w write_sel mem_w load jump jz   out  halt
        // HALT: opcode 000000, whatever the other bits are
        check({6'b000000, 5'd0, 5'd0}, 4'b0000, 0, 0, WB_ALU, 0, 0, 0, 0, 0, 1, "HALT");
        check(16'h0021,                4'b0000, 0, 0, WB_ALU, 0, 0, 0, 0, 0, 1, "HALT, nonzero reg bits");

        // ALU, R-format: alu_op = low 4 bits of the opcode, write back the ALU result
        check({6'b000001, 5'd1, 5'd2}, 4'b0001, 0, 1, WB_ALU, 0, 0, 0, 0, 0, 0, "ADD r1, r2");
        check({6'b000010, 5'd1, 5'd2}, 4'b0010, 0, 1, WB_ALU, 0, 0, 0, 0, 0, 0, "SUB r1, r2");
        check({6'b000011, 5'd1, 5'd2}, 4'b0011, 0, 1, WB_ALU, 0, 0, 0, 0, 0, 0, "MUL r1, r2");
        check({6'b000100, 5'd1, 5'd2}, 4'b0100, 0, 1, WB_ALU, 0, 0, 0, 0, 0, 0, "AND r1, r2");
        check({6'b000101, 5'd1, 5'd2}, 4'b0101, 0, 1, WB_ALU, 0, 0, 0, 0, 0, 0, "OR r1, r2");
        check({6'b000110, 5'd1, 5'd2}, 4'b0110, 0, 1, WB_ALU, 0, 0, 0, 0, 0, 0, "XOR r1, r2");
        check({6'b000111, 5'd1, 5'd2}, 4'b0111, 0, 1, WB_ALU, 0, 0, 0, 0, 0, 0, "NOT r1, r2");

        // Immediate, I-format
        check({6'b010000, 5'd3, 5'd11}, 4'b0000, 0, 1, WB_IMM, 0, 0, 0, 0, 0, 0, "LI r3, 11");
        check({6'b010001, 5'd3, 5'd7},  4'b0001, 1, 1, WB_ALU, 0, 0, 0, 0, 0, 0, "ADDI r3, 7");
        check({6'b011000, 5'd3, 5'd4},  4'b1000, 1, 1, WB_ALU, 0, 0, 0, 0, 0, 0, "SHL r3, 4");
        check({6'b011001, 5'd3, 5'd4},  4'b1001, 1, 1, WB_ALU, 0, 0, 0, 0, 0, 0, "SRL r3, 4");
        check({6'b011010, 5'd3, 5'd4},  4'b1010, 1, 1, WB_ALU, 0, 0, 0, 0, 0, 0, "SRA r3, 4");

        // Memory and moves
        check({6'b100000, 5'd4, 5'd5}, 4'b0000, 0, 1, WB_RS,  0, 0, 0, 0, 0, 0, "MOV r4, r5");
        check({6'b100001, 5'd4, 5'd5}, 4'b0000, 0, 1, WB_MEM, 0, 1, 0, 0, 0, 0, "LOAD r4, [r5]");
        // STORE writes no register, so write_sel is unused; your decoder sets it to WB_RS
        check({6'b100010, 5'd4, 5'd5}, 4'b0000, 0, 0, WB_RS,  1, 0, 0, 0, 0, 0, "STORE r4, [r5]");

        // Control flow
        check({6'b110000, 5'd0, 5'd6}, 4'b0000, 0, 0, WB_ALU, 0, 0, 1, 0, 0, 0, "JMP r6");
        check({6'b110001, 5'd7, 5'd6}, 4'b0000, 0, 0, WB_ALU, 0, 0, 0, 1, 0, 0, "JZ r7, r6");
        check({6'b110010, 5'd8, 5'd0}, 4'b0000, 0, 0, WB_ALU, 0, 0, 0, 0, 1, 0, "OUT r8");

        // Unused opcode: every signal should be 0
        check({6'b110011, 5'd1, 5'd2}, 4'b0000, 0, 0, WB_ALU, 0, 0, 0, 0, 0, 0, "unused opcode 110011");

        $display("");
        if (errors == 0)
            $display("ALL %0d TESTS PASSED", tests);
        else
            $display("%0d of %0d TESTS FAILED", errors, tests);

        $finish;
    end

endmodule