module ysyx_24110015_Pc (
  input clk,
  input rst,
  input [31:0] din,
  output reg [31:0] pc,
  output reg [31:0] pc_next
);
  reg [31:0] pre_pc;
  always @(posedge clk) begin
    if(!rst) begin
      pc <= pc_next;
    end
    else begin
      pc <= 32'h00000000;
    end
  end
  ysyx_24110015_Reg #(32, 32'h80000000) i1 (.clk(clk), .rst(rst), .din(din), .dout(pc_next), .wen(1'b1));
endmodule
