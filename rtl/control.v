`default_nettype none

module control(
    input wire clk,
    input wire reset,

    input wire is_reg_write,
    input wire is_mem_write,
    input wire is_jump,
    input wire is_jz,
    input wire is_out,
    input wire is_halt,

    input wire rd_is_zero,

    output wire reg_write_en,
    output wire mem_write_en,
    output wire pc_enable,
    output wire pc_load,
    output wire out_en,
    output wire halted
);

    // States
    localparam FETCH = 3'b001;
    localparam DECODE = 3'b010;
    localparam EXECUTE = 3'b011;
    localparam WRITEBACK = 3'b100;
    localparam HALTED = 3'b000;

    reg [2:0] state;
    reg [2:0] next_state;

    always @(posedge clk) begin
        state <= reset ? FETCH : next_state;
    end

    always @(*) begin
        case (state)
            FETCH: next_state = DECODE;
            DECODE: next_state = is_halt ? HALTED : EXECUTE;
            EXECUTE: next_state = WRITEBACK;
            WRITEBACK: next_state = FETCH;
            HALTED: next_state = HALTED;
            default: next_state = FETCH;
        endcase
    end

    assign reg_write_en = is_reg_write && (state == WRITEBACK);
    assign mem_write_en = is_mem_write && (state == WRITEBACK);
    assign pc_enable = (state == WRITEBACK);
    assign pc_load = (is_jump || (is_jz && rd_is_zero)) && (state == WRITEBACK);
    assign out_en = is_out && (state == WRITEBACK);
    assign halted = (state == HALTED);

endmodule