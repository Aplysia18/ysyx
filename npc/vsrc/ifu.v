// import "DPI-C" function int pmem_read(input int addr);
// import "DPI-C" function void pmem_write(input int waddr, input int wdata, input byte wmask);
// import "DPI-C" function void get_pc(input int pc);
// import "DPI-C" function void get_inst(input int inst);

module ysyx_24110015_IFU (
  input clk,
  input rst,
  input ren,
  input [31:0] pc,
  output reg [31:0] inst
);

  wire [31:0] rdata;

  ysyx_24110015_SRAM #(32, 32) ifu_sram(
    .clk(clk),
    .raddr(pc),
    .ren(ren),
    .waddr(32'h0),
    .wdata(32'h0),
    .wen(1'b0),
    .rdata(rdata)
  );

  always @(*) begin
    if(!rst) begin
      inst = rdata;
      // get_pc(pc);
      // get_inst(inst);
    end else begin
      inst = 32'h0;
    end
  end

endmodule