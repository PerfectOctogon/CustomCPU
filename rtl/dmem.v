`default_nettype none

// Data memory: holds the programs data during execution
// Allows read and write :)
module dmem(
    input wire clk,
    input wire [15:0] addr,
    input wire write_enable,
    input wire [15:0] write_data,
    output reg [15:0] read_data
);

    reg [15:0] mem [0:255];

    always @(posedge clk) begin
        // synchronous read so we can use block RAM
        read_data <= mem[addr[7:0]];

        if (write_enable) begin
            mem[addr[7:0]] <= write_data;
        end
    end
endmodule