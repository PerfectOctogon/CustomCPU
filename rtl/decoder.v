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

    // Write selection
    localparam WB_ALU = 2'b00;
    localparam WB_IMM = 2'b01;
    localparam WB_RS = 2'b10;
    localparam WB_MEM = 2'b11;

    always @(posedge clk) begin
        //defaults
        alu_op = 0;
        is_alu_b_imm = 0;
        is_reg_write = 0;
        write_sel = 0;
        is_mem_write = 0;
        is_load = 0;
        is_jump = 0;
        is_jz = 0;
        is_out = 0;
        is_halt = 0;

        if (instr == 0) begin
            is_halt <= 1;
        end else begin

            case (instr[15:14])
                // ALU operations
                OP_ALU: begin
                    alu_op <= instr[13:10];
                    is_alu_b_imm <= 0;
                    is_reg_write <= 1;
                    is_mem_write <= 0;
                    write_sel <= WB_ALU;
                end
                
                // Immediates
                OP_IMM: begin
                    // check if this is a non-ALU op (LI)
                    if (instr[13:10] == 4'b0000) begin
                        is_reg_write <= 1;
                        is_mem_write <= 0;
                        write_sel <= WB_IMM;
                    end else begin
                        alu_op <= instr[13:10];
                        is_alu_b_imm <= 1;
                        is_reg_write <= 1;
                        write_sel <= WB_ALU;
                        is_mem_write <= 0;
                    end
                end

                // Memory and moves
                OP_MOV: begin
                    
                end

                // Control flow
                OP_CFL: begin
                end
            endcase

        end
    end

endmodule