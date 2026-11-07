`default_nettype none

module decoder(
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
    localparam OP_MEMOV = 2'b10;
    localparam OP_CFL = 2'b11;

    // Write selection
    localparam WB_ALU = 2'b00;
    localparam WB_IMM = 2'b01;
    localparam WB_RS = 2'b10;
    localparam WB_MEM = 2'b11;

    // Memory and move bits
    localparam OP_MOV = 2'b00;
    localparam OP_LOAD = 2'b01;
    localparam OP_STORE = 2'b10;

    // Control flow bits
    localparam OP_JMP = 2'b00;
    localparam OP_JZ = 2'b01;
    localparam OP_OUT = 2'b10;

    always @(*) begin
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

        if (instr[15:10] == 6'b000000) begin
            is_halt = 1;
        end else begin

            case (instr[15:14])
                // ALU operations
                OP_ALU: begin
                    alu_op = instr[13:10];
                    is_alu_b_imm = 0;
                    is_reg_write = 1;
                    is_mem_write = 0;
                    write_sel = WB_ALU;
                end
                
                // Immediates
                OP_IMM: begin
                    // check if this is a non-ALU op (LI)
                    if (instr[13:10] == 4'b0000) begin
                        is_reg_write = 1;
                        is_mem_write = 0;
                        write_sel = WB_IMM;
                    end else begin
                        alu_op = instr[13:10];
                        is_alu_b_imm = 1;
                        is_reg_write = 1;
                        write_sel = WB_ALU;
                        is_mem_write = 0;
                    end
                end

                // Memory and moves
                OP_MEMOV: begin
                    case (instr[11:10])
                        OP_MOV: begin
                            is_reg_write = 1;
                            write_sel = WB_RS;
                            is_mem_write = 0;
                        end

                        OP_LOAD: begin
                            is_reg_write = 1;
                            write_sel = WB_MEM;
                            is_mem_write = 0;
                            is_load = 1;
                        end

                        OP_STORE: begin
                            is_reg_write = 0;
                            write_sel = WB_RS;
                            is_mem_write = 1;
                        end
                    endcase
                end

                // Control flow
                OP_CFL: begin
                    case (instr[11:10])
                        OP_JMP: begin
                            is_jump = 1;
                        end

                        OP_JZ: begin
                            is_jz = 1;
                        end

                        OP_OUT: begin
                            is_out = 1;
                        end
                    endcase
                end
            endcase
        end
    end

endmodule