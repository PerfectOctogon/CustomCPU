`default_nettype none

// Runs program.hex on the full CPU.
//
// The default program:
//   4025   LI   r1, 5
//   4043   LI   r2, 3
//   0422   ADD  r1, r2
//   C820   OUT  r1
//   0000   HALT
//
// Expected: OUT prints 8, then the CPU halts.

module cpu_tb;

    reg         clk = 0;
    reg         reset;
    wire [15:0] out_val;
    wire        halted;

    integer cycles = 0;
    integer errors = 0;

    localparam MAX_CYCLES = 1000;   // give up if the CPU never halts
    localparam DECODE     = 3'b010; // must match control.v

    cpu dut (
        .clk(clk), .reset(reset),
        .out_val(out_val), .halted(halted)
    );

    // Clock: one cycle = 10 time units
    always #5 clk = ~clk;

    // Trace: print each instruction as it reaches DECODE
    always @(posedge clk) begin
        if (!reset && dut.mod_control.state == DECODE)
            $display("  [cycle %0d] pc=%h instr=%h", cycles, dut.pc_out, dut.imem_instr_out);
    end

    // Print every OUT as it happens
    always @(posedge clk) begin
        if (dut.ctrl_out_en)
            $display("  OUT -> %0d (0x%h)", dut.reg_read_data_a, dut.reg_read_data_a);
    end

    // Compare one register's final value
    task check_reg;
        input [4:0]  r;
        input [15:0] expected;
        begin
            if (dut.mod_regfile.regs[r] !== expected) begin
                $display("FAIL  r%0d = %h, expected %h", r, dut.mod_regfile.regs[r], expected);
                errors = errors + 1;
            end else begin
                $display("pass  r%0d = %h", r, dut.mod_regfile.regs[r]);
            end
        end
    endtask

    initial begin
        $dumpfile("cpu_tb.vcd");
        $dumpvars(0, cpu_tb);

        // Reset for two cycles
        reset = 1;
        @(posedge clk); @(posedge clk); #1;
        reset = 0;

        $display("Running program.hex...");

        // Run until HALT, or give up after MAX_CYCLES
        while (!halted && cycles < MAX_CYCLES) begin
            @(posedge clk); #1;
            cycles = cycles + 1;
        end

        $display("");
        if (!halted) begin
            $display("FAIL  CPU did not halt within %0d cycles", MAX_CYCLES);
            errors = errors + 1;
        end else begin
            $display("Halted after %0d cycles", cycles);
        end

        // Final state
        if (out_val !== 16'd8) begin
            $display("FAIL  out_val = %0d, expected 8", out_val);
            errors = errors + 1;
        end else begin
            $display("pass  out_val = %0d", out_val);
        end
        check_reg(5'd1, 16'd8);
        check_reg(5'd2, 16'd3);

        $display("");
        if (errors == 0)
            $display("PROGRAM RAN CORRECTLY");
        else
            $display("%0d CHECK(S) FAILED", errors);

        $finish;
    end

endmodule