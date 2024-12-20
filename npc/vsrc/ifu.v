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
  reg [31:0] pre_pc;
  always @(posedge clk) begin
    if(!rst) begin
      pre_pc <= pc;
    end
  end
  always @(pre_pc) begin
    if(!rst) begin
      inst = pmem_read(pre_pc);
      get_pc(pre_pc);
      get_inst(inst);
    end
  end

endmodule