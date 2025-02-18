import "DPI-C" function void get_dnpc(input int pc);

module ysyx_24110015_top(
  input clk,
  input rst
);
  wire [31:0] inst;
  wire [31:0] pc;
  wire [31:0] pc_next;
  wire [31:0] imm;
  wire [2:0] func3;

  wire [31:0] rdata1, rdata2, wdata;
  
  wire RegWrite;
  wire [1:0] ALUAsrc;
  wire [1:0] ALUBsrc;
  wire [3:0] ALUop;
  wire MemWrite;
  wire MemRead;
  wire PCAsrc;
  wire PCBsrc;
  wire branch;
  wire zicsr;
  wire [4:0] zimm;
  wire ebreak;
  wire ecall;
  wire mret;

  always @(pc_next) begin
    get_dnpc(pc_next);
  end
  
  ysyx_24110015_Pc pc_reg (
    .clk(clk), 
    .rst(rst), 
    .din(pc_next), 
    .pc(pc)
    );

  ysyx_24110015_IFU ifu (
    .clk(clk), 
    .rst(rst), 
    .pc(pc_next), 
    .inst(inst)
    );

  ysyx_24110015_IDU idu (
    .clk(clk), 
    .rst(rst), 
    .inst(inst),
    .func3(func3), 
    .imm(imm),
    .RegWrite(RegWrite),
    .ALUAsrc(ALUAsrc),
    .ALUBsrc(ALUBsrc),
    .ALUop(ALUop),
    .MemWrite(MemWrite),
    .MemRead(MemRead),
    .PCAsrc(PCAsrc),
    .PCBsrc(PCBsrc),
    .branch(branch),
    .zicsr(zicsr),
    .zimm(zimm),
    .ebreak(ebreak),
    .ecall(ecall),
    .mret(mret)
    );

  ysyx_24110015_RegisterFile #(4, 32) rf (
    .clk(clk), 
    .wdata(wdata),
    .waddr(inst[10:7]),
    .wen(RegWrite),
    .raddr1(inst[18:15]),
    .raddr2(inst[23:20]),
    .rdata1(rdata1),
    .rdata2(rdata2)
    );

  ysyx_24110015_EXU exu (
    .clk(clk), 
    .rst(rst), 
    .pc(pc), 
    .func3(func3),
    .imm(imm), 
    .data1(rdata1), 
    .data2(rdata2), 
    .ALUAsrc(ALUAsrc),
    .ALUBsrc(ALUBsrc),
    .ALUop(ALUop),
    .MemWrite(MemWrite),
    .MemRead(MemRead),
    .PCAsrc(PCAsrc),
    .PCBsrc(PCBsrc),
    .branch(branch),
    .zicsr(zicsr),
    .zimm(zimm),
    .ebreak(ebreak),
    .ecall(ecall),
    .mret(mret),
    .data_out(wdata), 
    .pc_next(pc_next)
    );



endmodule
