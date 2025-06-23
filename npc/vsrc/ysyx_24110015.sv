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

  axi_if axiif_master_ifu();
  axi_if axiif_master_lsu();
  axi_if axiif_master();
  axi_if axiif_slave_clint();
`ifdef ysyxsoc
  axi_if axiif_slave_soc();
`else
  axi_if axiif_slave_sram();
  axi_if axiif_slave_uart();
`endif

  ysyx_24110015_AXIArbiter arbiter(
    .clk(clock),
    .rst(reset),
    .axi_master_ifu(axiif_master_ifu),
    .axi_master_lsu(axiif_master_lsu),
    .axi_slave(axiif_master)
  );

`ifdef ysyxsoc
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

`else
  ysyx_24110015_xbar xbar(
    .clk(clock),
    .rst(reset),
    .axi_master(axiif_master),
    .axi_slave_sram(axiif_slave_sram),
    .axi_slave_uart(axiif_slave_uart),
    .axi_slave_clint(axiif_slave_clint)
  );
  
  ysyx_24110015_AXI2MEM axi2mem(
    .clk(clock),
    .rst(reset),
    .axi(axiif_slave_sram)
  );

  ysyx_24110015_AXI2Uart axi2uart (
    .clk(clock),
    .rst(reset),
    .axi(axiif_slave_uart)
  );
  
`endif
  
  ysyx_24110015_AXI2Clint axi2clint (
    .clk(clock),
    .rst(reset),
    .axi(axiif_slave_clint)
  );

  logic [31:0] pc;
  logic [31:0] inst;
  logic [31:0] imm;
  logic [2:0] func3;
  logic [31:0] rdata1;
  logic [31:0] rdata2;
  logic [31:0] wdata;
  logic RegWrite;
  logic ebreak_idu, ebreak_exu,ebreak_lsu;
  logic ecall;
  logic mret;
  logic [31:0] dout_mstatus;
  logic [31:0] dout_mtvec;
  logic [31:0] dout_mepc;
  logic [31:0] dout_mcause;
  logic [31:0] dout_mvendorid;
  logic [31:0] dout_marchid;

  wire [31:0] pc_ifu, pc_idu, pc_exu, pc_lsu, pc_wbu;
  wire [31:0] inst_idu, inst_exu, inst_lsu, inst_wbu;
  wire [31:0] pc_next_exu;
  assign pc = pc_ifu;

  logic [31:0] pc_predict_ifu, pc_predict_idu;
  logic control_hazard;
  logic [31:0] pc_predict_bp;
  logic pc_predict_valid_bp;

  wire fence_i;

  logic ifu_in_valid, ifu_in_ready, ifu_out_valid, ifu_out_ready;

  always @(posedge clock or posedge reset) begin
    if(reset) begin
      ifu_in_valid <= 0;
    end else begin
      ifu_in_valid <= 1;  //need raw control
    end
  end

  /*-----IFU-----*/
  ysyx_24110015_IFU ifu (
    .clk(clock),
    .rst(reset),
    //handshake signals
    .in_valid(ifu_in_valid),
    .in_ready(ifu_in_ready),
    .out_valid(ifu_out_valid),
    .out_ready(ifu_out_ready),
    //from branch predictor
    .pc_predict_bp(pc_predict_bp),
    .pc_predict_valid_bp(pc_predict_valid_bp),
    //for branch hazard
    .control_hazard(control_hazard),
    .pc_next(pc_next_exu),
    //from idu
    .fence_i(fence_i),
    //to idu
    .inst(inst),
    .pc_out(pc_ifu),
    .pc_predict(pc_predict_ifu),
    //to axi
    .axiif(axiif_master_ifu)
  );

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
  wire branch, jal;
  wire zicsr_idu, zicsr_exu, zicsr_lsu;
  wire [4:0] zimm;
  wire [31:0] alu_out_exu, alu_out_lsu;
  wire [31:0] csr_rdata_exu, csr_rdata_lsu;

  logic idu_in_valid, idu_in_ready, idu_out_valid, idu_out_ready;
  assign ifu_out_ready = idu_in_ready;
  assign idu_in_valid = ifu_out_valid;

  logic idu_reg1_read, idu_reg2_read;
  logic [4:0] idu_raddr1, idu_raddr2;
  logic idu_processing, exu_processing, lsu_processing, wbu_processing;

  logic rs1_raw, rs2_raw, rs1_forward, rs2_forward;
  logic [31:0] rs1_value, rs2_value;

  ysyx_24110015_forward_check forward_check(
    //from idu
    .idu_processing(idu_processing),
    .idu_reg1_read(idu_reg1_read),
    .idu_reg2_read(idu_reg2_read),
    .idu_raddr1(idu_raddr1),
    .idu_raddr2(idu_raddr2),
    //from exu
    .exu_processing(exu_processing),
    .RegWrite_exu(RegWrite_exu),
    .wb_addr_exu(wb_addr_exu),
    .MemRead_exu(MemRead_exu),
    .zicsr_exu(zicsr_exu),
    .alu_out_exu(alu_out_exu),
    .csr_rdata_exu(csr_rdata_exu),
    //from lsu
    .lsu_processing(lsu_processing),
    .RegWrite_lsu(RegWrite_lsu),
    .wb_addr_lsu(wb_addr_lsu),
    .MemRead_lsu(MemRead_lsu),
    .zicsr_lsu(zicsr_lsu),
    .alu_out_lsu(alu_out_lsu),
    .csr_rdata_lsu(csr_rdata_lsu),
    //from wbu
    .wbu_processing(wbu_processing),
    .RegWrite_wbu(RegWrite_wbu),
    .wb_addr_wbu(wb_addr_wbu),
    .wb_data_wbu(wb_data),
    //output to idu
    .rs1_raw(rs1_raw),
    .rs1_forward(rs1_forward),
    .rs1_value(rs1_value),
    .rs2_raw(rs2_raw),
    .rs2_forward(rs2_forward),
    .rs2_value(rs2_value)
  );

  logic update_valid_bp, branch_bp, jal_bp;
  logic [31:0] pc_update_bp, target_addr_bp;
  ysyx_24110015_branch_predictor #(8) branch_predictor (
    .clk(clock),
    .rst(reset),
    //from ifu
    .pc_in(pc_ifu),
    //to ifu
    .pc_predict(pc_predict_bp),
    .pc_predict_valid(pc_predict_valid_bp),
    //from exu
    .update_valid(update_valid_bp),
    .branch(branch_bp),
    .jal(jal_bp),
    .pc_update(pc_update_bp),
    .target_addr(target_addr_bp)
);

  ysyx_24110015_IDU idu (
    .clk(clock),
    .rst(reset),
    // handshake signals
    .in_valid(idu_in_valid),
    .in_ready(idu_in_ready),
    .out_valid(idu_out_valid),
    .out_ready(idu_out_ready),
    //to forward check
    .processing(idu_processing),
    .reg1_read(idu_reg1_read),
    .reg2_read(idu_reg2_read),
    .raddr1(idu_raddr1),
    .raddr2(idu_raddr2),
    //from forward check
    .rs1_raw(rs1_raw),
    .rs1_forward(rs1_forward),
    .rs1_value(rs1_value),
    .rs2_raw(rs2_raw),
    .rs2_forward(rs2_forward),
    .rs2_value(rs2_value),
    //for branch hazard
    .control_hazard(control_hazard),
    //from ifu
    .inst_i(inst),
    .pc_i(pc_ifu),
    .pc_predict_i(pc_predict_ifu),
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
    //to exu
    .pc_o(pc_idu),
    .inst_o(inst_idu),
    .pc_predict_o(pc_predict_idu),
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
    .jal(jal),
    .zicsr(zicsr_idu),
    .zimm(zimm),
    .dout_mstatus(dout_mstatus),
    .dout_mtvec(dout_mtvec),
    .dout_mepc(dout_mepc),
    .dout_mcause(dout_mcause),
    .dout_mvendorid(dout_mvendorid),
    .dout_marchid(dout_marchid),
    .ebreak(ebreak_idu),
    .ecall(ecall),
    .fence_i(fence_i),
    .mret(mret)
);

  wire [3:0] mem_wmask;
  wire [31:0] mem_wdata;

  logic exu_in_valid, exu_in_ready, exu_out_valid, exu_out_ready;
  assign idu_out_ready = exu_in_ready;
  assign exu_in_valid = idu_out_valid;

  ysyx_24110015_EXU exu (
    .clk(clock),
    .rst(reset),
    // handshake signals
    .in_valid(exu_in_valid),
    .in_ready(exu_in_ready),
    .out_valid(exu_out_valid),
    .out_ready(exu_out_ready),
    //to conflict detection
    .processing(exu_processing), 
    //for branch hazard
    .control_hazard(control_hazard),
    .pc_next(pc_next_exu),
    //to branch predictor
    .update_valid_bp(update_valid_bp),
    .branch_bp(branch_bp),
    .jal_bp(jal_bp),
    .pc_update_bp(pc_update_bp),
    .target_addr_bp(target_addr_bp),
    //from idu
    .pc_i(pc_idu),
    .inst_i(inst_idu),
    .pc_predict_i(pc_predict_idu),
    .func3_i(func3_idu),
    .imm_i(imm),
    .data1_i(rdata1),
    .data2_i(rdata2),
    .RegWrite_i(RegWrite_idu),
    .wb_addr_i(wb_addr_idu),
    .ALUAsrc_i(ALUAsrc),
    .ALUBsrc_i(ALUBsrc),
    .ALUop_i(ALUop),
    .MemWrite_i(MemWrite_idu),
    .MemRead_i(MemRead_idu),
    .PCAsrc_i(PCAsrc),
    .PCBsrc_i(PCBsrc),
    .branch_i(branch),
    .jal_i(jal),
    .zicsr_i(zicsr_idu),
    .zimm_i(zimm),
    .dout_mstatus_i(dout_mstatus),
    .dout_mtvec_i(dout_mtvec),
    .dout_mepc_i(dout_mepc),
    .dout_mcause_i(dout_mcause),
    .dout_mvendorid_i(dout_mvendorid),
    .dout_marchid_i(dout_marchid),
    .ebreak_i(ebreak_idu),
    .ecall_i(ecall),
    .mret_i(mret),
    //to lsu
    .pc_o(pc_exu),
    .inst_o(inst_exu),
    .alu_out(alu_out_exu),
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
    .mem_wdata(mem_wdata),
    .ebreak_o(ebreak_exu)
  );

  wire [31:0] mem_rdata;

  wire lsu_in_valid, lsu_in_ready, lsu_out_valid, lsu_out_ready;
  assign exu_out_ready = lsu_in_ready;
  assign lsu_in_valid = exu_out_valid;

  ysyx_24110015_LSU lsu (
    .clk(clock),
    .rst(reset),
    // handshake signals
    .in_valid(lsu_in_valid),
    .in_ready(lsu_in_ready),
    .out_valid(lsu_out_valid),
    .out_ready(lsu_out_ready),
    //to conflict detection
    .processing(lsu_processing),
    //from exu
    .pc_i(pc_exu),
    .inst_i(inst_exu),
    .alu_out_i(alu_out_exu),
    .RegWrite_i(RegWrite_exu),
    .wb_addr_i(wb_addr_exu),
    .mem_wmask_i(mem_wmask),
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
    .MemWrite_i(MemWrite_exu),
    .MemRead_i(MemRead_exu),
    .mem_wdata_i(mem_wdata),
    .ebreak_i(ebreak_exu),
    //to wbu
    .pc_o(pc_lsu),
    .inst_o(inst_lsu),
    .alu_out_o(alu_out_lsu),
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
    .ebreak_o(ebreak_lsu),
    //to axi
    .axiif(axiif_master_lsu)
  );

  wire wbu_in_valid, wbu_in_ready;
  wire wbu_out_valid, wbu_out_ready;
  assign lsu_out_ready = wbu_in_ready;
  assign wbu_in_valid = lsu_out_valid;
  assign wbu_out_ready = 1'b1;  //to do

  ysyx_24110015_WBU wbu(
    .clk(clock),
    .rst(reset),
    // handshake signals
    .in_valid(wbu_in_valid),
    .in_ready(wbu_in_ready),
    .out_valid(wbu_out_valid),
    .out_ready(wbu_out_ready),
    //to conflict detection
    .processing(wbu_processing),
    //from lsu
    .pc_i(pc_lsu),
    .inst_i(inst_lsu),
    .alu_out_i(alu_out_lsu),
    .RegWrite_i(RegWrite_lsu),
    .wb_addr_i(wb_addr_lsu),
    .zicsr_i(zicsr_lsu),
    .csr_rdata_i(csr_rdata_lsu),
    .din_mstatus_i(din_mstatus_lsu),
    .din_mtvec_i(din_mtvec_lsu),
    .din_mepc_i(din_mepc_lsu),
    .din_mcause_i(din_mcause_lsu),
    .wen_mstatus_i(wen_mstatus_lsu),
    .wen_mtvec_i(wen_mtvec_lsu),
    .wen_mepc_i(wen_mepc_lsu),
    .wen_mcause_i(wen_mcause_lsu),
    .func3_i(func3_lsu),
    .MemRead_i(MemRead_lsu),
    .mem_rdata_i(mem_rdata),
    .ebreak_i(ebreak_lsu),
    //to idu
    .pc_o(pc_wbu),
    .inst_o(inst_wbu),
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
