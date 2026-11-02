`default_nettype none

module alu (
    input  wire [15:0] a,
    input  wire [15:0] b,
    input  wire [3:0]  op,
    output reg  [15:0] result,
    output wire        zero,
    output reg         overflow
);

    // Opcodes
    localparam OP_ADD = 4'b0001;
    localparam OP_SUB = 4'b0010;
    localparam OP_MUL = 4'b0011;
    localparam OP_AND = 4'b0100;
  	localparam OP_OR = 4'b0101;
  	localparam OP_XOR = 4'b0110;
  	localparam OP_NOT = 4'b0111;
  	localparam OP_SHL = 4'b1000;
  	localparam OP_SRL = 4'b1001;
  	localparam OP_SRA = 4'b1010;

    always @(*) begin
      	// defaults to avoid latch
      	overflow = 0;
      	result = 0;
		
      	// op mux
        case (op)
            OP_ADD: begin
                result = a + b;
              	// if result sig bit is different when input sig bits are same, overflow
              	overflow = ((a[15] == b[15]) && a[15] != result[15]) ? 1 : 0;
            end
            OP_SUB: begin
              	result = a - b;
              	// if input sig bits are different and 
              	// the result doesnt have the same sig bit as input a, overflow
              	overflow = ((a[15] != b[15]) && a[15] != result[15]) ? 1 : 0;
            end
          	OP_MUL: begin
              	result = a * b;
            end
          	OP_AND: begin
              	result = a & b;
            end
          	OP_OR: begin
              	result = a | b;
            end
          	OP_XOR: begin
              	result = a ^ b;
            end
          	OP_NOT: begin
              	result = ~a;
            end
          	OP_SHL: begin
              	result = a << b;
            end
          	OP_SRL: begin
              	result = a >> b;
            end
          	OP_SRA: begin
              result = $signed(a) >>> b;
            end
            default: begin
              	// we should realistically never get here
            end
        endcase
    end

  assign zero = !result;

endmodule