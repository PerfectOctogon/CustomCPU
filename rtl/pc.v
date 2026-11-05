`default_nettype none

module pc(
	input wire reset,
  input wire enable,
  input wire load,
  input wire clk,
  input wire [15:0] jump_addr,
  output reg [15:0] pc_out
);
  
  always @(posedge clk) begin
    if (reset == 1'b1) begin
      pc_out <= 0;
    end else begin
      if (enable == 1'b1) begin
        if (load == 1'b1) begin
          pc_out <= jump_addr;
        end else begin
          pc_out <= pc_out + 1;
        end
      end
    end
  end
  
endmodule