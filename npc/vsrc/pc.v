module ysyx_24110015_Pc (
  input clk,
  input rst,
  input wen,
  input [31:0] din,
  output reg [31:0] pc
);
`ifdef ysyxsoc
localparam RESET_VEC = 32'h30000000;
`else
localparam RESET_VEC = 32'h80000000;
`endif
  ysyx_24110015_Reg #(32, RESET_VEC) i1 (.clk(clk), .rst(rst), .din(din), .dout(pc), .wen(wen));
endmodule
