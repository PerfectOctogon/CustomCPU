`default_nettype none

// Instruction memory: This module holds a program's instructions
// It is read-only once the program is loaded
module imem(
    input wire clk,
    input wire [15:0] addr,
    output reg [15:0] instr
);

    // using a 8 bit addressing-space for now, even though real
    // addressing-space is 16 bits long!!
    reg [15:0] mem [0:255];

    // load initial program
    initial $readmemh("program.hex", mem);

    always @(posedge clk) begin
        instr <= mem[addr[7:0]];
    end
endmodule