import "DPI-C" function int pmem_read(input int addr);
import "DPI-C" function void pmem_write(input int waddr, input int wdata, input byte wmask);

module ysyx_24110015_IFU (
  input clk,
  input rst,
  input [31:0] pc,
  output reg [31:0] inst
);

  always @(*) begin
    if (rst) begin
      inst = 32'b0;
    end else begin
      inst = pmem_read(pc);
    end
  end

endmodule