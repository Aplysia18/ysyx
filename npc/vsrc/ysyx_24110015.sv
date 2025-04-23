module ysyx_24110015(
  input clock,
  input reset,
  input io_interrupt,
  //AXI4 Master
  input io_master_awready,
  output io_master_awvalid,
  output [31:0] io_master_awaddr,
  output [3:0] io_master_awid,
  output [7:0] io_master_awlen,
  output [2:0] io_master_awsize,
  output [1:0] io_master_awburst,
  input io_master_wready,
  output io_master_wvalid,
  output [31:0] io_master_wdata,
  output [3:0] io_master_wstrb,
  output io_master_wlast,
  output io_master_bready,
  input io_master_bvalid,
  input [1:0] io_master_bresp,
  input [3:0] io_master_bid,
  input io_master_arready,
  output io_master_arvalid,
  output [31:0] io_master_araddr,
  output [3:0] io_master_arid,
  output [7:0] io_master_arlen,
  output [2:0] io_master_arsize,
  output [1:0] io_master_arburst,
  output io_master_rready,
  input io_master_rvalid,
  input [1:0] io_master_rresp,
  input [31:0] io_master_rdata,
  input io_master_rlast,
  input [3:0] io_master_rid,
  //AXI4 Slave
  output io_slave_awready,
  input io_slave_awvalid,
  input [31:0] io_slave_awaddr,
  input [3:0] io_slave_awid,
  input [7:0] io_slave_awlen,
  input [2:0] io_slave_awsize,
  input [1:0] io_slave_awburst,
  output io_slave_wready,
  input io_slave_wvalid,
  input [31:0] io_slave_wdata,
  input [3:0] io_slave_wstrb,
  input io_slave_wlast,
  input io_slave_bready,
  output io_slave_bvalid,
  output [1:0] io_slave_bresp,
  output [3:0] io_slave_bid,
  output io_slave_arready,
  input io_slave_arvalid,
  input [31:0] io_slave_araddr,
  input [3:0] io_slave_arid,
  input [7:0] io_slave_arlen,
  input [2:0] io_slave_arsize,
  input [1:0] io_slave_arburst,
  input io_slave_rready,
  output io_slave_rvalid,
  output [1:0] io_slave_rresp,
  output [31:0] io_slave_rdata,
  output io_slave_rlast,
  output [3:0] io_slave_rid
);
  //unused output ports
  assign io_slave_awready = 0;
  assign io_slave_wready = 0;
  assign io_slave_bvalid = 0;
  assign io_slave_bid = 0;
  assign io_slave_bresp = 0;
  assign io_slave_arready = 0;
  assign io_slave_rvalid = 0;
  assign io_slave_rid = 0;  
  assign io_slave_rdata = 0;
  assign io_slave_rresp = 0;
  assign io_slave_rlast = 0;

  logic [31:0] pc;
  logic [31:0] pc_next;
  logic [31:0] inst;
  logic [31:0] imm;
  logic [2:0] func3;
  logic [31:0] rdata1;
  logic [31:0] rdata2;
  logic [31:0] wdata;
  logic RegWrite;
  logic ebreak;
  logic ecall;
  logic mret;
  logic [31:0] dout_mstatus;
  logic [31:0] dout_mtvec;
  logic [31:0] dout_mepc;
  logic [31:0] dout_mcause;
  logic [31:0] dout_mvendorid;
  logic [31:0] dout_marchid;
  logic control_ls;
  logic control_RegWrite;
  logic control_iMemRead_end;
  logic control_iMemRead;
  logic control_dmemR_end;
  logic control_dmemW_end;
  logic control_dMemRW;

  ysyx_24110015_Controller controller (
    .clk(clock), 
    .rst(reset),
    .control_ls(control_ls),
    .control_RegWrite(control_RegWrite),
    .control_iMemRead_end(control_iMemRead_end),
    .control_iMemRead(control_iMemRead),
    .control_dmemR_end(control_dmemR_end),
    .control_dmemW_end(control_dmemW_end),
    .control_dMemRW(control_dMemRW)
  );

  axi_lite_if axiif_master_ifu();
  axi_lite_if axiif_master_lsu();
  axi_lite_if axiif_master();
  axi_lite_if axiif_slave_clint();
  axi_lite_if axiif_slave_soc();

  ysyx_24110015_AXIArbiter arbiter(
    .clk(clock),
    .rst(reset),
    .axi_master_ifu(axiif_master_ifu),
    .axi_master_lsu(axiif_master_lsu),
    .axi_slave(axiif_master)
  );

  assign axiif_slave_soc.awready = io_master_awready;
  assign io_master_awvalid = axiif_slave_soc.awvalid;
  assign io_master_awaddr = axiif_slave_soc.awaddr;
  assign io_master_awid = axiif_slave_soc.awid;
  assign io_master_awlen = axiif_slave_soc.awlen;
  assign io_master_awsize = axiif_slave_soc.awsize;
  assign io_master_awburst = axiif_slave_soc.awburst;
  assign axiif_slave_soc.wready = io_master_wready;
  assign io_master_wvalid = axiif_slave_soc.wvalid;
  assign io_master_wdata = axiif_slave_soc.wdata;
  assign io_master_wstrb = axiif_slave_soc.wstrb;
  assign io_master_wlast = axiif_slave_soc.wlast;
  assign io_master_bready = axiif_slave_soc.bready;
  assign axiif_slave_soc.bvalid = io_master_bvalid;
  assign axiif_slave_soc.bresp = io_master_bresp;
  assign axiif_slave_soc.bid = io_master_bid;
  assign axiif_slave_soc.arready = io_master_arready;
  assign io_master_arvalid = axiif_slave_soc.arvalid;
  assign io_master_araddr = axiif_slave_soc.araddr;
  assign io_master_arid = axiif_slave_soc.arid;
  assign io_master_arlen = axiif_slave_soc.arlen;
  assign io_master_arsize = axiif_slave_soc.arsize;
  assign io_master_arburst = axiif_slave_soc.arburst;
  assign io_master_rready = axiif_slave_soc.rready;
  assign axiif_slave_soc.rvalid = io_master_rvalid;
  assign axiif_slave_soc.rresp = io_master_rresp;
  assign axiif_slave_soc.rdata = io_master_rdata;
  assign axiif_slave_soc.rlast = io_master_rlast;
  assign axiif_slave_soc.rid = io_master_rid;

  ysyx_24110015_xbar xbar(
    .clk(clock),
    .rst(reset),
    .axi_master(axiif_master),
    .axi_slave_clint(axiif_slave_clint),
    .axi_slave_soc(axiif_slave_soc)
  );
  
  ysyx_24110015_AXI2Clint axi2clint (
    .clk(clock),
    .rst(reset),
    .axi(axiif_slave_clint)
  );

  wire [31:0] pc_ifu;
  wire [31:0] pc_next_exu, pc_next_lsu, pc_next_wbu;
  assign pc = pc_ifu;
  assign pc_next = pc_next_wbu;

  ysyx_24110015_IFU ifu (
    .clk(clock),
    .rst(reset),
    //from controller
    .control_RegWrite(control_RegWrite),
    .control_iMemRead(control_iMemRead),
    //from wbu
    .pc_next(pc_next_wbu),
    //to idu
    .inst(inst),
    .pc(pc_ifu),
    //to controller
    .control_iMemRead_end(control_iMemRead_end),
    //to axi
    .axiif(axiif_master_ifu)
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
    .clk(clock),
    .rst(reset),
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
    .dout_mvendorid(dout_mvendorid),
    .dout_marchid(dout_marchid),
    .ebreak(ebreak),
    .ecall(ecall),
    .mret(mret),
    //to controller
    .control_ls(control_ls)
);

  wire [31:0] alu_out_exu, alu_out_lsu;
  wire [3:0] mem_wmask;
  wire [31:0] csr_rdata_exu, csr_rdata_lsu;
  wire [31:0] mem_wdata;

  ysyx_24110015_EXU exu (
    .clk(clock),
    .rst(reset),
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
    .dout_mvendorid(dout_mvendorid),
    .dout_marchid(dout_marchid),
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
    .clk(clock),
    .rst(reset),
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
    .mem_rdata(mem_rdata),
    //to controller
    .control_dmemR_end(control_dmemR_end),
    .control_dmemW_end(control_dmemW_end),
    //to axi
    .axiif(axiif_master_lsu)
  );

  ysyx_24110015_WBU wbu(
    .clk(clock),
    .rst(reset),
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
