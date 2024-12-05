module ysyx_24110015_Pc (
  input clk,
  input rst,
  input [31:0] din,
  output reg [31:0] dout
);
  ysyx_24110015_Reg #(32, 32'h80000000) i1 (.clk(clk), .rst(rst), .din(din), .dout(dout), .wen(1'b1));
endmodule
