import "DPI-C" function void get_dnpc(input int pc);

module ysyx_24110015_top(
  input clk,
  input rst
);
  wire [31:0] inst;
  wire [31:0] pc;
  wire [31:0] pc_next;
  wire [6:0] opcode, func7;
  wire [2:0] func3;
  wire [31:0] imm;

  wire ebreak;
  wire [31:0] rdata1, rdata2, wdata;
  
  wire RegWrite;
  wire [1:0] ALUAsrc;
  wire [1:0] ALUBsrc;
  wire [3:0] ALUop;
  wire MemWrite;
  wire MemRead;
  wire [2:0] MemOp;
  wire PCAsrc;
  wire PCBsrc;
  wire branch;

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
    .opcode(opcode),
    .func7(func7),
    .func3(func3),
    .imm(imm),
    .RegWrite(RegWrite),
    .ALUAsrc(ALUAsrc),
    .ALUBsrc(ALUBsrc),
    .ALUop(ALUop),
    .MemWrite(MemWrite),
    .MemRead(MemRead),
    .MemOp(MemOp),
    .PCAsrc(PCAsrc),
    .PCBsrc(PCBsrc),
    .branch(branch),
    .ebreak(ebreak)
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
    .imm(imm), 
    .data1(rdata1), 
    .data2(rdata2), 
    .ALUAsrc(ALUAsrc),
    .ALUBsrc(ALUBsrc),
    .ALUop(ALUop),
    .MemWrite(MemWrite),
    .MemRead(MemRead),
    .MemOp(MemOp),
    .PCAsrc(PCAsrc),
    .PCBsrc(PCBsrc),
    .branch(branch),
    .ebreak(ebreak),
    .data_out(wdata), 
    .pc_next(pc_next)
    );



endmodule
