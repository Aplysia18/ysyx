import "DPI-C" function void get_regs(input logic [31:0] a []);
module ysyx_24110015_RegisterFile #(ADDR_WIDTH = 1, DATA_WIDTH = 1) (
  input clk,
  input [DATA_WIDTH-1:0] wdata,
  input [ADDR_WIDTH-1:0] waddr,
  input wen,
  input [ADDR_WIDTH-1:0] raddr1,
  input [ADDR_WIDTH-1:0] raddr2,
  output [DATA_WIDTH-1:0] rdata1,
  output [DATA_WIDTH-1:0] rdata2
);
  reg [DATA_WIDTH-1:0] rf [2**ADDR_WIDTH-1:0];
  initial begin
    get_regs(rf);
  end
  //write
  always @(posedge clk) begin
    if (wen&&waddr!=0) rf[waddr] <= wdata;
  end
  //read
  assign rdata1 = (raddr1!=0) ? rf[raddr1] : 0;
  assign rdata2 = (raddr2!=0) ? rf[raddr2] : 0;
endmodule