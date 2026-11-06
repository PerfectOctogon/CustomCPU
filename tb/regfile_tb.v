`default_nettype none

module regfile_tb;

    reg         clk = 0;
    reg         reset;
    reg  [4:0]  read_addr_a, read_addr_b;
    reg         write_enable;
    reg  [4:0]  write_addr;
    reg  [15:0] write_data;
    wire [15:0] read_data_a, read_data_b;

    integer errors = 0;
    integer tests  = 0;
    integer j;

    regfile dut (
        .clk(clk), .reset(reset),
        .read_addr_a(read_addr_a), .read_addr_b(read_addr_b),
        .write_enable(write_enable), .write_addr(write_addr), .write_data(write_data),
        .read_data_a(read_data_a), .read_data_b(read_data_b)
    );

    // Clock: one cycle = 10 time units
    always #5 clk = ~clk;

    // Drive the write port for one clock edge, then turn write_enable off
    task write_reg;
        input [4:0]  addr;
        input [15:0] data;
        input        en;
        begin
            write_addr   = addr;
            write_data   = data;
            write_enable = en;
            @(posedge clk);
            #1;
            write_enable = 0;
        end
    endtask

    // Set both read addresses, wait a moment (no clock edge needed), compare both ports
    task check_read;
        input [4:0]      addr_a;
        input [15:0]     exp_a;
        input [4:0]      addr_b;
        input [15:0]     exp_b;
        input [8*40-1:0] label;
        begin
            read_addr_a = addr_a;
            read_addr_b = addr_b;
            #1;
            tests = tests + 1;
            if (read_data_a !== exp_a || read_data_b !== exp_b) begin
                $display("FAIL  %0s: A r%0d=%h (expected %h), B r%0d=%h (expected %h)",
                         label, addr_a, read_data_a, exp_a, addr_b, read_data_b, exp_b);
                errors = errors + 1;
            end else begin
                $display("pass  %0s: A r%0d=%h, B r%0d=%h",
                         label, addr_a, read_data_a, addr_b, read_data_b);
            end
        end
    endtask

    initial begin
        $dumpfile("regfile_tb.vcd");
        $dumpvars(0, regfile_tb);

        // Start in reset
        reset = 1; write_enable = 0;
        write_addr = 0; write_data = 0;
        read_addr_a = 0; read_addr_b = 0;
        @(posedge clk); #1;
        reset = 0;

        // 1. After reset: r0 and the far ends of the register file are 0
        check_read(5'd0,  16'h0000, 5'd31, 16'h0000, "after reset: r0 and r31");
        check_read(5'd15, 16'h0000, 5'd16, 16'h0000, "after reset: r15 and r16");

        // 2. Writing to r0 is ignored
        write_reg(5'd0, 16'hBEEF, 1'b1);
        check_read(5'd0, 16'h0000, 5'd0, 16'h0000, "r0 ignores writes");

        // 3. Write then read
        write_reg(5'd5, 16'h1234, 1'b1);
        check_read(5'd5, 16'h1234, 5'd5, 16'h1234, "write r5, read on both ports");

        // 4. Two different registers on the two ports at once
        write_reg(5'd6, 16'hABCD, 1'b1);
        check_read(5'd5, 16'h1234, 5'd6, 16'hABCD, "r5 on A, r6 on B");

        // 5. write_enable = 0 blocks the write
        write_reg(5'd5, 16'hFFFF, 1'b0);
        check_read(5'd5, 16'h1234, 5'd6, 16'hABCD, "write_enable=0 keeps r5");

        // 6. Reads are combinational: change the address with no clock edge
        check_read(5'd6, 16'hABCD, 5'd5, 16'h1234, "swap addresses, no clock");

        // 7. Several registers, including the last one
        write_reg(5'd1,  16'h0001, 1'b1);
        write_reg(5'd16, 16'h1616, 1'b1);
        write_reg(5'd31, 16'h3131, 1'b1);
        check_read(5'd1,  16'h0001, 5'd31, 16'h3131, "r1 and r31");
        check_read(5'd16, 16'h1616, 5'd5,  16'h1234, "r16 and r5 untouched");

        // 8. Reset clears every register, r0 through r31
        reset = 1;
        @(posedge clk); #1;
        reset = 0;
        for (j = 0; j < 32; j = j + 1)
            check_read(j[4:0], 16'h0000, j[4:0], 16'h0000, "after second reset");

        $display("");
        if (errors == 0)
            $display("ALL %0d TESTS PASSED", tests);
        else
            $display("%0d of %0d TESTS FAILED", errors, tests);

        $finish;
    end

endmodule