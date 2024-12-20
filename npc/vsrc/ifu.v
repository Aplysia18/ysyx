import "DPI-C" function int pmem_read(input int addr);
import "DPI-C" function void pmem_write(input int waddr, input int wdata, input byte wmask);
import "DPI-C" function void get_pc(input int pc);
import "DPI-C" function void get_inst(input int inst);

module ysyx_24110015_IFU (
  input clk,
  input rst,
  input [31:0] pc,
  output reg [31:0] inst
);
  always @(posedge clk) begin
    if(!rst) begin
      inst = pmem_read(pc);
      get_pc(pc);
      get_inst(inst);
    end else begin
      inst = 32'h0;
    end
  end

endmodule