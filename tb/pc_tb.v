`default_nettype none

module pc_tb;

    reg         clk = 0;
    reg         reset, enable, load;
    reg  [15:0] jump_addr;
    wire [15:0] pc_out;

    integer errors = 0;
    integer tests  = 0;

    pc dut (
        .clk(clk), .reset(reset), .enable(enable), .load(load),
        .jump_addr(jump_addr), .pc_out(pc_out)
    );

    // Clock: flips every 5 time units, so one cycle = 10
    always #5 clk = ~clk;

    // Wait for the next rising edge, let pc_out update, then compare
    task step_and_check;
        input [15:0]      expected;
        input [8*40-1:0]  label;
        begin
            @(posedge clk);
            #1;
            tests = tests + 1;
            if (pc_out !== expected) begin
                $display("FAIL  %0s: got %h, expected %h", label, pc_out, expected);
                errors = errors + 1;
            end else begin
                $display("pass  %0s: pc = %h", label, pc_out);
            end
        end
    endtask

    initial begin
        $dumpfile("pc_tb.vcd");
        $dumpvars(0, pc_tb);

        // 1. Reset
        reset = 1; enable = 0; load = 0; jump_addr = 16'h0000;
        step_and_check(16'h0000, "reset");

        // 2. Count up
        reset = 0; enable = 1;
        step_and_check(16'h0001, "count 1");
        step_and_check(16'h0002, "count 2");
        step_and_check(16'h0003, "count 3");

        // 3. Hold when enable = 0
        enable = 0;
        step_and_check(16'h0003, "hold");
        step_and_check(16'h0003, "hold again");

        // 4. Jump (load + enable), then keep counting from there
        enable = 1; load = 1; jump_addr = 16'h0100;
        step_and_check(16'h0100, "jump to 0100");
        load = 0;
        step_and_check(16'h0101, "count after jump");
        step_and_check(16'h0102, "count after jump");

        // 5. load without enable: no jump
        enable = 0; load = 1; jump_addr = 16'h0200;
        step_and_check(16'h0102, "load ignored, enable=0");

        // 6. Wrap-around at the top of the address range
        enable = 1; load = 1; jump_addr = 16'hFFFF;
        step_and_check(16'hFFFF, "jump to FFFF");
        load = 0;
        step_and_check(16'h0000, "wrap to 0000");
        step_and_check(16'h0001, "count after wrap");

        // 7. Reset wins over load and enable
        reset = 1; enable = 1; load = 1; jump_addr = 16'h1234;
        step_and_check(16'h0000, "reset beats load");

        $display("");
        if (errors == 0)
            $display("ALL %0d TESTS PASSED", tests);
        else
            $display("%0d of %0d TESTS FAILED", errors, tests);

        $finish;
    end

endmodule