`default_nettype none

module regfile(
    input wire clk,
    input wire [4:0] read_addr_a,
    input wire [4:0] read_addr_b,
    input wire write_enable,
    input wire [4:0] write_addr,
    input wire [15:0] write_data,
    input wire reset,

    output wire [15:0] read_data_a,
    output wire [15:0] read_data_b
);
    // array of 32 registers, each 16 bits long
    reg [15:0] regs [0:31];

    // r0 is the 0 register
    initial regs[0] = 16'd0;

    // read from the registers
    // read can happen outside the clocked block because
    // state isn't changing :)
    assign read_data_a = regs[read_addr_a];
    assign read_data_b = regs[read_addr_b];

    integer i;

    always @(posedge clk) begin
        // synchronous reset
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 16'd0;
            end
        end else begin
            // write if write is enabled and write address isn't the r0 register
            if (write_enable == 1 && write_addr) begin
                regs[write_addr] <= write_data;
            end
        end
    end

endmodule