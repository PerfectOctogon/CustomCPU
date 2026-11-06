`default_nettype none

// Expects program.hex in the folder you run the simulation from:
//   4025
//   4043
//   0422
//   C820
//   0000

module imem_tb;

    reg         clk = 0;
    reg  [15:0] addr;
    wire [15:0] instr;

    integer errors = 0;
    integer tests  = 0;

    imem dut (
        .clk(clk), .addr(addr), .instr(instr)
    );

    // Clock: one cycle = 10 time units
    always #5 clk = ~clk;

    // Compare instr against an expected value, with no clock edge
    task check_now;
        input [15:0]     expected;
        input [8*40-1:0] label;
        begin
            tests = tests + 1;
            if (instr !== expected) begin
                $display("FAIL  %0s: addr=%h instr=%h, expected %h", label, addr, instr, expected);
                errors = errors + 1;
            end else begin
                $display("pass  %0s: addr=%h instr=%h", label, addr, instr);
            end
        end
    endtask

    // Present an address, wait for the rising edge (synchronous read), then check
    task read_and_check;
        input [15:0]     a;
        input [15:0]     expected;
        input [8*40-1:0] label;
        begin
            addr = a;
            @(posedge clk);
            #1;
            check_now(expected, label);
        end
    endtask

    initial begin
        $dumpfile("imem_tb.vcd");
        $dumpvars(0, imem_tb);

        addr = 16'h0000;

        // 1. Every word of the program, in order
        read_and_check(16'h0000, 16'h4025, "addr 0: LI r1, 5");
        read_and_check(16'h0001, 16'h4043, "addr 1: LI r2, 3");
        read_and_check(16'h0002, 16'h0422, "addr 2: ADD r1, r2");
        read_and_check(16'h0003, 16'hC820, "addr 3: OUT r1");
        read_and_check(16'h0004, 16'h0000, "addr 4: HALT");

        // 2. The read is synchronous: changing addr alone does nothing until the edge
        addr = 16'h0001;
        #1;
        check_now(16'h0000, "before edge: still old word");
        @(posedge clk); #1;
        check_now(16'h4043, "after edge: new word");

        // 3. Past the end of the file: $readmemh leaves these slots unset (x)
        read_and_check(16'h0005, 16'hxxxx, "addr 5: never loaded");

        // 4. Only the low 8 bits index memory, so 256 wraps to 0 and 257 to 1
        read_and_check(16'h0100, 16'h4025, "addr 256 wraps to 0");
        read_and_check(16'h0101, 16'h4043, "addr 257 wraps to 1");

        $display("");
        if (errors == 0)
            $display("ALL %0d TESTS PASSED", tests);
        else
            $display("%0d of %0d TESTS FAILED", errors, tests);

        $finish;
    end

endmodule