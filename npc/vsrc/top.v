module ysyx_24110015_top(
  input clk,
  input rst,
  output [31:0] pc,
  output [31:0] pc_next,
  output [31:0] inst,
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

  wire control_load;
  wire control_RegWrite;
  wire control_iMemRead;
  wire control_dMemRW;

  ysyx_24110015_Controller controller (
    .clk(clk), 
    .rst(rst),
    .control_load(control_load),
    .control_RegWrite(control_RegWrite),
    .control_iMemRead(control_iMemRead),
    .control_dMemRW(control_dMemRW)
  );

  wire [31:0] pc_ifu;
  wire [31:0] pc_next_exu, pc_next_lsu, pc_next_wbu;
  assign pc = pc_ifu;
  assign pc_next = pc_next_wbu;

  ysyx_24110015_IFU ifu (
    .clk(clk),
    .rst(rst),
    //from controller
    .control_RegWrite(control_RegWrite),
    .control_iMemRead(control_iMemRead),
    //from wbu
    .pc_next(pc_next_wbu),
    //to idu
    .inst(inst),
    .pc(pc_ifu)
  );

  wire [31:0] pc_idu;
  wire RegWrite_idu, RegWrite_exu, RegWrite_lsu, RegWrite_wbu;
  wire [4:0] wb_addr_idu, wb_addr_exu, wb_addr_lsu, wb_addr_wbu;
  wire [31:0] din_mcause_idu, din_mcause_exu, din_mcause_lsu, din_mcause_wbu;
  wire [31:0] din_mepc_idu, din_mepc_exu, din_mepc_lsu, din_mepc_wbu;
  wire [31:0] din_mstatus_idu, din_mstatus_exu, din_mstatus_lsu, din_mstatus_wbu;
  wire [31:0] din_mtvec_idu, din_mtvec_exu, din_mtvec_lsu, din_mtvec_wbu;
  wire wen_mcause_idu, wen_mcause_exu, wen_mcause_lsu, wen_mcause_wbu;
  wire wen_mepc_idu, wen_mepc_exu, wen_mepc_lsu, wen_mepc_wbu;
  wire wen_mstatus_idu, wen_mstatus_exu, wen_mstatus_lsu, wen_mstatus_wbu;
  wire wen_mtvec_idu, wen_mtvec_exu, wen_mtvec_lsu, wen_mtvec_wbu;
  wire [31:0] wb_data;
  wire [2:0] func3_idu, func3_exu, func3_lsu;
  wire [1:0] ALUAsrc, ALUBsrc;
  wire [3:0] ALUop;
  wire MemWrite_idu, MemWrite_exu, MemWrite_lsu;
  wire MemRead_idu, MemRead_exu, MemRead_lsu, MemRead_wbu;
  wire PCAsrc, PCBsrc;
  wire branch;
  wire zicsr_idu, zicsr_exu, zicsr_lsu;
  wire [4:0] zimm;

  ysyx_24110015_IDU idu (
    .clk(clk),
    .rst(rst),
    //from ifu
    .inst(inst),
    .pc_i(pc_ifu),
    //from wbu
    .RegWrite_i(RegWrite_wbu),
    .wb_addr_i(wb_addr_wbu),
    .din_mstatus(din_mstatus_wbu),
    .din_mtvec(din_mtvec_wbu),
    .din_mepc(din_mepc_wbu),
    .din_mcause(din_mcause_wbu),
    .wen_mstatus(wen_mstatus_wbu),
    .wen_mtvec(wen_mtvec_wbu),
    .wen_mepc(wen_mepc_wbu),
    .wen_mcause(wen_mcause_wbu),
    .wb_data(wb_data),
    //from controller
    .control_RegWrite(control_RegWrite),
    //to exu
    .pc_o(pc_idu),
    .func3(func3_idu),
    .imm(imm),
    .rdata1(rdata1),
    .rdata2(rdata2),
    .RegWrite_o(RegWrite_idu),
    .wb_addr_o(wb_addr_idu),
    .ALUAsrc(ALUAsrc),
    .ALUBsrc(ALUBsrc),
    .ALUop(ALUop),
    .MemWrite(MemWrite_idu),
    .MemRead(MemRead_idu),
    .PCAsrc(PCAsrc),
    .PCBsrc(PCBsrc),
    .branch(branch),
    .zicsr(zicsr_idu),
    .zimm(zimm),
    .dout_mstatus(dout_mstatus),
    .dout_mtvec(dout_mtvec),
    .dout_mepc(dout_mepc),
    .dout_mcause(dout_mcause),
    .ebreak(ebreak),
    .ecall(ecall),
    .mret(mret),
    //to controller
    .control_load(control_load)
);

  wire [31:0] alu_out_exu, alu_out_lsu;
  wire [3:0] mem_wmask;
  wire [31:0] csr_rdata_exu, csr_rdata_lsu;
  wire [31:0] mem_wdata;

  ysyx_24110015_EXU exu (
    .clk(clk),
    .rst(rst),
    //from idu
    .pc(pc_idu),
    .func3(func3_idu),
    .imm(imm),
    .data1(rdata1),
    .data2(rdata2),
    .RegWrite_i(RegWrite_idu),
    .wb_addr_i(wb_addr_idu),
    .ALUAsrc(ALUAsrc),
    .ALUBsrc(ALUBsrc),
    .ALUop(ALUop),
    .MemWrite_i(MemWrite_idu),
    .MemRead_i(MemRead_idu),
    .PCAsrc(PCAsrc),
    .PCBsrc(PCBsrc),
    .branch(branch),
    .zicsr_i(zicsr_idu),
    .zimm(zimm),
    .dout_mstatus(dout_mstatus),
    .dout_mtvec(dout_mtvec),
    .dout_mepc(dout_mepc),
    .dout_mcause(dout_mcause),
    .ebreak(ebreak),
    .ecall(ecall),
    .mret(mret),
    //to lsu
    .alu_out(alu_out_exu),
    .pc_next(pc_next_exu),
    .RegWrite_o(RegWrite_exu),
    .wb_addr_o(wb_addr_exu),
    .mem_wmask(mem_wmask),
    .zicsr_o(zicsr_exu),
    .csr_rdata(csr_rdata_exu),
    .din_mstatus(din_mstatus_exu),
    .din_mtvec(din_mtvec_exu),
    .din_mepc(din_mepc_exu),
    .din_mcause(din_mcause_exu),
    .wen_mstatus(wen_mstatus_exu),
    .wen_mtvec(wen_mtvec_exu),
    .wen_mepc(wen_mepc_exu),
    .wen_mcause(wen_mcause_exu),
    .func3_o(func3_exu),
    .MemWrite_o(MemWrite_exu),
    .MemRead_o(MemRead_exu),
    .mem_wdata(mem_wdata)
  );

  wire [31:0] mem_rdata;

  ysyx_24110015_LSU lsu (
    .clk(clk),
    .rst(rst),
    //from exu
    .alu_out_i(alu_out_exu),
    .pc_next_i(pc_next_exu),
    .RegWrite_i(RegWrite_exu),
    .wb_addr_i(wb_addr_exu),
    .mem_wmask(mem_wmask),
    .zicsr_i(zicsr_exu),
    .csr_rdata_i(csr_rdata_exu),
    .din_mstatus_i(din_mstatus_exu),
    .din_mtvec_i(din_mtvec_exu),
    .din_mepc_i(din_mepc_exu),
    .din_mcause_i(din_mcause_exu),
    .wen_mstatus_i(wen_mstatus_exu),
    .wen_mtvec_i(wen_mtvec_exu),
    .wen_mepc_i(wen_mepc_exu),
    .wen_mcause_i(wen_mcause_exu),
    .func3_i(func3_exu),
    .MemWrite(MemWrite_exu),
    .MemRead_i(MemRead_exu),
    .mem_wdata(mem_wdata),
    //from controller
    .control_dMemRW(control_dMemRW),
    //to wbu
    .alu_out_o(alu_out_lsu),
    .pc_next_o(pc_next_lsu),
    .RegWrite_o(RegWrite_lsu),
    .wb_addr_o(wb_addr_lsu),
    .zicsr_o(zicsr_lsu),
    .csr_rdata_o(csr_rdata_lsu),
    .din_mstatus_o(din_mstatus_lsu),
    .din_mtvec_o(din_mtvec_lsu),
    .din_mepc_o(din_mepc_lsu),
    .din_mcause_o(din_mcause_lsu),
    .wen_mstatus_o(wen_mstatus_lsu),
    .wen_mtvec_o(wen_mtvec_lsu),
    .wen_mepc_o(wen_mepc_lsu),
    .wen_mcause_o(wen_mcause_lsu),
    .func3_o(func3_lsu),
    .MemRead_o(MemRead_lsu),
    .mem_rdata(mem_rdata)
  );

  ysyx_24110015_WBU wbu(
    .clk(clk),
    .rst(rst),
    //from lsu
    .alu_out(alu_out_lsu),
    .pc_next_i(pc_next_lsu),
    .RegWrite_i(RegWrite_lsu),
    .wb_addr_i(wb_addr_lsu),
    .zicsr(zicsr_lsu),
    .csr_rdata(csr_rdata_lsu),
    .din_mstatus_i(din_mstatus_lsu),
    .din_mtvec_i(din_mtvec_lsu),
    .din_mepc_i(din_mepc_lsu),
    .din_mcause_i(din_mcause_lsu),
    .wen_mstatus_i(wen_mstatus_lsu),
    .wen_mtvec_i(wen_mtvec_lsu),
    .wen_mepc_i(wen_mepc_lsu),
    .wen_mcause_i(wen_mcause_lsu),
    .func3(func3_lsu),
    .MemRead(MemRead_lsu),
    .mem_rdata(mem_rdata),
    //to exu
    .pc_next_o(pc_next_wbu),
    .RegWrite_o(RegWrite_wbu),
    .wb_addr_o(wb_addr_wbu),
    .din_mstatus_o(din_mstatus_wbu),
    .din_mtvec_o(din_mtvec_wbu),
    .din_mepc_o(din_mepc_wbu),
    .din_mcause_o(din_mcause_wbu),
    .wen_mstatus_o(wen_mstatus_wbu),
    .wen_mtvec_o(wen_mtvec_wbu),
    .wen_mepc_o(wen_mepc_wbu),
    .wen_mcause_o(wen_mcause_wbu),
    .wb_data(wb_data)
  );


endmodule
