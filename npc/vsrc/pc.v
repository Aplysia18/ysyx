module ysyx_24110015_Pc (
  input clk,
  input rst,
  input [31:0] din,
  output reg [31:0] dout
);
  wire [31:0] pc_pre;
  ysyx_24110015_Reg #(32, 32'h80000000) i1 (.clk(clk), .rst(rst), .din(din), .dout(pc_pre), .wen(1'b1));
  always @(posedge clk) begin
    if (rst) dout <= 32'h0;
    else dout <= pc_pre;
  end
endmodule
