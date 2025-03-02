// import "DPI-C" function int pmem_read(input int addr);
// import "DPI-C" function void pmem_write(input int waddr, input int wdata, input byte wmask);
// import "DPI-C" function void get_pc(input int pc);
// import "DPI-C" function void get_inst(input int inst);

module ysyx_24110015_IFU (
  input clk,
  input rst,
  input [31:0] pc,
  output reg [31:0] inst
);

  wire[31:0] imem_rdata1, imem_rdata2, imem_wdata;
  wire[7:0] imem_waddr, imem_raddr1, imem_raddr2;
  wire imem_wen;

  assign imem_raddr1 = pc[7:0];
  assign imem_raddr2 = pc[7:0];

  ysyx_24110015_RegisterFile #(8, 32) imem (
    .clk(clk),
    .wdata(imem_wdata),
    .waddr(imem_waddr),
    .wen(imem_wen),
    .raddr1(imem_raddr1),
    .raddr2(imem_raddr2),
    .rdata1(imem_rdata1),
    .rdata2(imem_rdata2)
);

  always @(posedge clk) begin
    if(!rst) begin
      inst <= imem_rdata1;
      // get_pc(pc);
      // get_inst(imem_rdata1);
    end else begin
      inst <= 32'h0;
    end
  end

endmodule