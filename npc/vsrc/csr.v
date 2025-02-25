module ysyx_24110015_CSR (
  input clk,
  input rst,
  input [31:0] din_mstatus,
  input [31:0] din_mtvec,
  input [31:0] din_mepc,
  input [31:0] din_mcause,
  input wen_mstatus,
  input wen_mtvec,
  input wen_mepc,
  input wen_mcause,
  output reg [31:0] dout_mstatus,
  output reg [31:0] dout_mtvec,
  output reg [31:0] dout_mepc,
  output reg [31:0] dout_mcause
);

  ysyx_24110015_Reg #(32, 32'h00001800) mstatus (.clk(clk), .rst(rst), .din(din_mstatus), .dout(dout_mstatus), .wen(wen_mstatus));
  ysyx_24110015_Reg #(32, 32'h00000000) mtvec (.clk(clk), .rst(rst), .din(din_mtvec), .dout(dout_mtvec), .wen(wen_mtvec)); 
  ysyx_24110015_Reg #(32, 32'h00000000) mepc (.clk(clk), .rst(rst), .din(din_mepc), .dout(dout_mepc), .wen(wen_mepc));
  ysyx_24110015_Reg #(32, 32'h00000000) mcause (.clk(clk), .rst(rst), .din(din_mcause), .dout(dout_mcause), .wen(wen_mcause));

endmodule
