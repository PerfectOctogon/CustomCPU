`default_nettype none

module alu_tb;

    reg  [15:0] a, b;
    reg  [3:0]  op;
    wire [15:0] result;
    wire        zero, overflow;

    integer errors = 0;
    integer tests  = 0;

    alu dut (
        .a(a), .b(b), .op(op),
        .result(result), .zero(zero), .overflow(overflow)
    );

    // Same codes as the ALU
    localparam OP_ADD = 4'b0001;
    localparam OP_SUB = 4'b0010;
    localparam OP_MUL = 4'b0011;
    localparam OP_AND = 4'b0100;
    localparam OP_OR  = 4'b0101;
    localparam OP_XOR = 4'b0110;
    localparam OP_NOT = 4'b0111;
    localparam OP_SHL = 4'b1000;
    localparam OP_SRL = 4'b1001;
    localparam OP_SRA = 4'b1010;

    // Apply inputs, wait, compare against the expected outputs
    task check;
        input [3:0]  t_op;
        input [15:0] t_a, t_b, exp_result;
        input        exp_zero, exp_ov;
        begin
            op = t_op; a = t_a; b = t_b;
            #1;
            tests = tests + 1;
            if (result !== exp_result || zero !== exp_zero || overflow !== exp_ov) begin
                $display("FAIL  op=%b a=%h b=%h | got result=%h zero=%b ov=%b | expected result=%h zero=%b ov=%b",
                         t_op, t_a, t_b, result, zero, overflow, exp_result, exp_zero, exp_ov);
                errors = errors + 1;
            end else begin
                $display("pass  op=%b a=%h b=%h -> result=%h zero=%b ov=%b",
                         t_op, t_a, t_b, result, zero, overflow);
            end
        end
    endtask

    initial begin
        $dumpfile("alu_tb.vcd");
        $dumpvars(0, alu_tb);

        // ADD
        check(OP_ADD, 16'h0003, 16'h0004, 16'h0007, 1'b0, 1'b0); // 3 + 4
        check(OP_ADD, 16'h7FFF, 16'h0001, 16'h8000, 1'b0, 1'b1); // max positive + 1 overflows
        check(OP_ADD, 16'hFFFF, 16'h0001, 16'h0000, 1'b1, 1'b0); // -1 + 1 = 0, carry out but no overflow
        check(OP_ADD, 16'h8000, 16'hFFFF, 16'h7FFF, 1'b0, 1'b1); // most negative + -1 overflows

        // SUB
        check(OP_SUB, 16'h000A, 16'h0003, 16'h0007, 1'b0, 1'b0); // 10 - 3
        check(OP_SUB, 16'h0005, 16'h0005, 16'h0000, 1'b1, 1'b0); // 5 - 5 = 0
        check(OP_SUB, 16'h7FFF, 16'hFFFF, 16'h8000, 1'b0, 1'b1); // 32767 - (-1) overflows
        check(OP_SUB, 16'h8000, 16'h0001, 16'h7FFF, 1'b0, 1'b1); // -32768 - 1 overflows

        // MUL
        check(OP_MUL, 16'h0006, 16'h0007, 16'h002A, 1'b0, 1'b0); // 6 * 7 = 42
        check(OP_MUL, 16'h0100, 16'h0100, 16'h0000, 1'b1, 1'b0); // 256 * 256 = 0x10000, low half is 0

        // Logic
        check(OP_AND, 16'hF0F0, 16'hFF00, 16'hF000, 1'b0, 1'b0);
        check(OP_OR,  16'hF0F0, 16'h0F00, 16'hFFF0, 1'b0, 1'b0);
        check(OP_XOR, 16'hFFFF, 16'h0F0F, 16'hF0F0, 1'b0, 1'b0);
        check(OP_NOT, 16'h00FF, 16'h1234, 16'hFF00, 1'b0, 1'b0); // b is ignored

        // Shifts
        check(OP_SHL, 16'h0001, 16'h0004, 16'h0010, 1'b0, 1'b0); // 1 << 4
        check(OP_SHL, 16'h8001, 16'h0001, 16'h0002, 1'b0, 1'b0); // top bit falls off
        check(OP_SHL, 16'hFFFF, 16'h0010, 16'h0000, 1'b1, 1'b0); // shift by 16: everything out
        check(OP_SRL, 16'h8000, 16'h0004, 16'h0800, 1'b0, 1'b0); // logical: fills with 0
        check(OP_SRA, 16'h8000, 16'h0004, 16'hF800, 1'b0, 1'b0); // arithmetic: copies the sign bit
        check(OP_SRA, 16'h4000, 16'h0004, 16'h0400, 1'b0, 1'b0); // positive: same as SRL

        // Unused codes fall to the default
        check(4'b0000, 16'h0005, 16'h0003, 16'h0000, 1'b1, 1'b0);
        check(4'b1111, 16'h0005, 16'h0003, 16'h0000, 1'b1, 1'b0);

        $display("");
        if (errors == 0)
            $display("ALL %0d TESTS PASSED", tests);
        else
            $display("%0d of %0d TESTS FAILED", errors, tests);

        $finish;
    end

endmodule