module ysyx_24110015_top(
  input clk,
  input rst,
  output [31:0] pc,
  output [31:0] pc_next,
  // output reg [31:0] inst,
  output [31:0] imm,
  output [2:0] func3,
  output [31:0] rdata1,
  output [31:0] rdata2,
  output [31:0] wdata,
  output RegWrite,
  output ebreak,
  output ecall,
  output mret,
  output [31:0] dout_mstatus,
  output [31:0] dout_mtvec,
  output [31:0] dout_mepc,
  output [31:0] dout_mcause
);
  wire [31:0] inst;
  // wire [31:0] pc;
  // wire [31:0] pc_next;
  // wire [31:0] imm;
  // wire [2:0] func3;

  // wire [31:0] rdata1, rdata2, wdata;
  
  // wire RegWrite;
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
  // wire ebreak;
  // wire ecall;
  // wire mret;

  wire control_RegWrite;
  wire control_iMemRead;
  wire control_dMemWrite;

  ysyx_24110015_Controller controller (
    .clk(clk), 
    .rst(rst),
    .RegWrite(control_RegWrite),
    .iMemRead(control_iMemRead),
    .dMemWrite(control_dMemWrite)
  );
  
  ysyx_24110015_Pc pc_reg (
    .clk(clk), 
    .rst(rst), 
    .wen(control_RegWrite),
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
    .wen(RegWrite & control_RegWrite),
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
    .control_RegWrite(control_RegWrite),
    .control_dMemWrite(control_dMemWrite),
    .data_out(wdata), 
    .pc_next(pc_next),
    .dout_mstatus(dout_mstatus),
    .dout_mtvec(dout_mtvec),
    .dout_mepc(dout_mepc),
    .dout_mcause(dout_mepc)
    );



endmodule
