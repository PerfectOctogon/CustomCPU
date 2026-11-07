`default_nettype none

module dmem_tb;

    reg         clk = 0;
    reg  [15:0] addr;
    reg         write_enable;
    reg  [15:0] write_data;
    wire [15:0] read_data;

    integer errors = 0;
    integer tests  = 0;

    dmem dut (
        .clk(clk), .addr(addr), .write_enable(write_enable),
        .write_data(write_data), .read_data(read_data)
    );

    // Clock: one cycle = 10 time units
    always #5 clk = ~clk;

    // Compare read_data against an expected value, with no clock edge
    task check_now;
        input [15:0]     expected;
        input [8*40-1:0] label;
        begin
            tests = tests + 1;
            if (read_data !== expected) begin
                $display("FAIL  %0s: addr=%0d read_data=%h, expected %h", label, addr, read_data, expected);
                errors = errors + 1;
            end else begin
                $display("pass  %0s: addr=%0d read_data=%h", label, addr, read_data);
            end
        end
    endtask

    // Drive the write port for one clock edge, then turn write_enable off
    task write_mem;
        input [15:0] a;
        input [15:0] d;
        input        en;
        begin
            addr = a; write_data = d; write_enable = en;
            @(posedge clk);
            #1;
            write_enable = 0;
        end
    endtask

    // Present an address, wait for the edge (synchronous read), then check
    task read_and_check;
        input [15:0]     a;
        input [15:0]     expected;
        input [8*40-1:0] label;
        begin
            addr = a; write_enable = 0;
            @(posedge clk);
            #1;
            check_now(expected, label);
        end
    endtask

    initial begin
        $dumpfile("dmem_tb.vcd");
        $dumpvars(0, dmem_tb);

        addr = 0; write_enable = 0; write_data = 0;

        // 1. Memory starts empty: an unwritten slot reads x
        read_and_check(16'd0, 16'hxxxx, "never written");

        // 2. Write then read
        write_mem(16'd10, 16'h1234, 1'b1);
        read_and_check(16'd10, 16'h1234, "write 10, read 10");

        // 3. write_enable = 0 blocks the write
        write_mem(16'd10, 16'hFFFF, 1'b0);
        read_and_check(16'd10, 16'h1234, "write_enable=0 keeps old");

        // 4. Several addresses, including the first and last slots
        write_mem(16'd0,   16'h00AA, 1'b1);
        write_mem(16'd255, 16'hBEEF, 1'b1);
        read_and_check(16'd0,   16'h00AA, "slot 0");
        read_and_check(16'd255, 16'hBEEF, "slot 255");
        read_and_check(16'd10,  16'h1234, "slot 10 untouched");

        // 5. The read is synchronous: changing addr alone does nothing until the edge
        addr = 16'd0;
        #1;
        check_now(16'h1234, "before edge: still old word");
        @(posedge clk); #1;
        check_now(16'h00AA, "after edge: new word");

        // 6. Only the low 8 bits are used: 300 = 0x12C, low 8 bits = 44
        write_mem(16'd300, 16'h5A5A, 1'b1);
        read_and_check(16'd44,  16'h5A5A, "store to 300 lands in 44");
        read_and_check(16'd300, 16'h5A5A, "load from 300 reads 44");

        // 7. Read and write the same address in one cycle: read-first
        addr = 16'd10; write_data = 16'h7777; write_enable = 1;
        @(posedge clk); #1;
        write_enable = 0;
        check_now(16'h1234, "same-cycle read gets OLD value");
        read_and_check(16'd10, 16'h7777, "next read gets new value");

        $display("");
        if (errors == 0)
            $display("ALL %0d TESTS PASSED", tests);
        else
            $display("%0d of %0d TESTS FAILED", errors, tests);

        $finish;
    end

endmodule