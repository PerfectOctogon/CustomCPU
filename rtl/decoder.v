`default_nettype none

module decoder(
    input wire clk,
    input wire [15:0] instr,
    output reg [3:0] alu_op,
    output reg is_alu_b_imm,
    output reg is_reg_write,
    output reg [1:0] write_sel,
    output reg is_mem_write,
    output reg is_load,
    output reg is_jump,
    output reg is_jz,
    output reg is_out,
    output reg is_halt
);

    // Groups
    localparam OP_ALU = 2'b00;
    localparam OP_IMM = 2'b01;
    localparam OP_MOV = 2'b10;
    localparam OP_CFL = 2'b11;

    always @(posedge clk) begin
        
        case (instr[15:14])
            // ALU operations
            OP_ALU: begin
            end
            
            // Immediates
            OP_IMM: begin
            end

            // Memory and moves
            OP_MOV: begin
            end

            // Control flow
            OP_CFL: begin
            end
        endcase
    end

endmodule