module ysyx_24110015_Pc (
  input clk,
  input rst,
  input wen,
  input [31:0] din,
  output reg [31:0] pc
);
  ysyx_24110015_Reg #(32, 32'h20000000) i1 (.clk(clk), .rst(rst), .din(din), .dout(pc), .wen(wen));
endmodule
