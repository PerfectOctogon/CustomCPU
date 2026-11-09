`default_nettype none

module control_tb;

    reg  clk = 0;
    reg  reset;
    reg  is_reg_write, is_mem_write, is_jump, is_jz, is_out, is_halt;
    reg  rd_is_zero;
    wire reg_write_en, mem_write_en, pc_enable, pc_load, out_en, halted;

    integer errors = 0;
    integer tests  = 0;

    control dut (
        .clk(clk), .reset(reset),
        .is_reg_write(is_reg_write), .is_mem_write(is_mem_write),
        .is_jump(is_jump), .is_jz(is_jz), .is_out(is_out), .is_halt(is_halt),
        .rd_is_zero(rd_is_zero),
        .reg_write_en(reg_write_en), .mem_write_en(mem_write_en),
        .pc_enable(pc_enable), .pc_load(pc_load),
        .out_en(out_en), .halted(halted)
    );

    // Same state codes as control.v
    localparam FETCH     = 3'b001;
    localparam DECODE    = 3'b010;
    localparam EXECUTE   = 3'b011;
    localparam WRITEBACK = 3'b100;
    localparam HALTED    = 3'b000;

    // Clock: one cycle = 10 time units
    always #5 clk = ~clk;

    // Advance one clock cycle
    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    // Check the current state and every output.
    // dut.state reaches inside the module to read its internal state register.
    task check;
        input [2:0]      e_state;
        input            e_reg_we, e_mem_we, e_pc_en, e_pc_load, e_out_en, e_halted;
        input [8*36-1:0] label;
        begin
            tests = tests + 1;
            if ({dut.state, reg_write_en, mem_write_en, pc_enable, pc_load, out_en, halted}
                !==
                {e_state, e_reg_we, e_mem_we, e_pc_en, e_pc_load, e_out_en, e_halted}) begin
                $display("FAIL  %0s", label);
                $display("        got:      state=%b reg_we=%b mem_we=%b pc_en=%b pc_load=%b out_en=%b halted=%b",
                         dut.state, reg_write_en, mem_write_en, pc_enable, pc_load, out_en, halted);
                $display("        expected: state=%b reg_we=%b mem_we=%b pc_en=%b pc_load=%b out_en=%b halted=%b",
                         e_state, e_reg_we, e_mem_we, e_pc_en, e_pc_load, e_out_en, e_halted);
                errors = errors + 1;
            end else begin
                $display("pass  %0s", label);
            end
        end
    endtask

    initial begin
        $dumpfile("control_tb.vcd");
        $dumpvars(0, control_tb);

        // Reset into FETCH
        reset = 1;
        is_reg_write = 0; is_mem_write = 0; is_jump = 0;
        is_jz = 0; is_out = 0; is_halt = 0; rd_is_zero = 0;
        tick;
        reset = 0;

        // 1-2. Hold the write flags at 1: enables must still fire only in WRITEBACK
        is_reg_write = 1; is_mem_write = 1; is_out = 1;
        //                  state      reg  mem  pc_en load out  halt
        check(FETCH,         0,   0,   0,    0,   0,   0, "FETCH: no enables");               tick;
        check(DECODE,        0,   0,   0,    0,   0,   0, "DECODE: no enables");              tick;
        check(EXECUTE,       0,   0,   0,    0,   0,   0, "EXECUTE: no enables");             tick;
        check(WRITEBACK,     1,   1,   1,    0,   1,   0, "WRITEBACK: enables fire");         tick;
        check(FETCH,         0,   0,   0,    0,   0,   0, "back to FETCH");

        // 3-4. JZ with rd == 0: jumps, but only in WRITEBACK
        is_reg_write = 0; is_mem_write = 0; is_out = 0;
        is_jz = 1; rd_is_zero = 1;
        tick; tick;
        check(EXECUTE,       0,   0,   0,    0,   0,   0, "JZ: no load before WRITEBACK");    tick;
        check(WRITEBACK,     0,   0,   1,    1,   0,   0, "JZ taken (rd == 0)");              tick;

        // JZ with rd != 0: PC advances normally, no jump
        rd_is_zero = 0;
        tick; tick; tick;
        check(WRITEBACK,     0,   0,   1,    0,   0,   0, "JZ not taken (rd != 0)");          tick;

        // JMP: always jumps
        is_jz = 0; is_jump = 1;
        tick; tick; tick;
        check(WRITEBACK,     0,   0,   1,    1,   0,   0, "JMP");                             tick;

        // 5. HALT: seen in DECODE, then stuck in HALTED with no enables
        is_jump = 0; is_halt = 1;
        is_reg_write = 1; is_mem_write = 1; is_out = 1;   // must stay blocked while halted
        tick;
        check(DECODE,        0,   0,   0,    0,   0,   0, "HALT seen in DECODE");             tick;
        check(HALTED,        0,   0,   0,    0,   0,   1, "HALTED");
        repeat (5) tick;
        check(HALTED,        0,   0,   0,    0,   0,   1, "still HALTED 5 cycles later");

        // 6. Reset leaves HALTED
        reset = 1;
        tick;
        reset = 0; is_halt = 0;
        check(FETCH,         0,   0,   0,    0,   0,   0, "reset leaves HALTED");

        $display("");
        if (errors == 0)
            $display("ALL %0d TESTS PASSED", tests);
        else
            $display("%0d of %0d TESTS FAILED", errors, tests);

        $finish;
    end

endmodule