`include "macros.v"
import "DPI-C" function void npc_trap();
import "DPI-C" function void exu_begin();
import "DPI-C" function void exu_end(input int inst);

module ysyx_24110015_EXU (
  input clk,
  input rst,
  // handshake signals
  input in_valid, //exu valid
  output in_ready, //exu ready
  output reg out_valid, //to lsu
  input out_ready, //from lsu
  //to conflict detection
  output reg processing,
  //for branch hazard
  output reg control_hazard,
  output [31:0] pc_next,
  //from idu
  input [31:0] pc_i,
  input [31:0] inst_i,
  input [31:0] pc_predict_i,
  input [2:0] func3_i,
  input [31:0] imm_i,
  input [31:0] data1_i,
  input [31:0] data2_i,
  input RegWrite_i,
  input [4:0] wb_addr_i,
  input [1:0] ALUAsrc_i,
  input [1:0] ALUBsrc_i,
  input [3:0] ALUop_i,
  input MemWrite_i,
  input MemRead_i,
  input PCAsrc_i,
  input PCBsrc_i,
  input branch_i,
  input zicsr_i,
  input [4:0] zimm_i,
  input [31:0] dout_mstatus_i,
  input [31:0] dout_mtvec_i,
  input [31:0] dout_mepc_i,
  input [31:0] dout_mcause_i,
  input [31:0] dout_mvendorid_i,
  input [31:0] dout_marchid_i,
  input ebreak_i,
  input ecall_i,
  input mret_i,
  //to lsu
  output reg [31:0] pc_o,
  output reg [31:0] inst_o,
  output reg [31:0] alu_out,
  output RegWrite_o,
  output [4:0] wb_addr_o,
  output [3:0] mem_wmask,
  output zicsr_o,
  output [31:0] csr_rdata,
  output [31:0] din_mstatus,
  output [31:0] din_mtvec,
  output [31:0] din_mepc,
  output [31:0] din_mcause,
  output wen_mstatus,
  output wen_mtvec,
  output wen_mepc,
  output wen_mcause,
  output [2:0] func3_o,
  output MemWrite_o,
  output MemRead_o,
  output [31:0] mem_wdata,
  output ebreak_o
);
  
  /*-----handshake signals-----*/
  assign in_ready = out_ready;
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      out_valid <= 1'b0;
    end else if (in_valid && in_ready) begin
      out_valid <= 1'b1;
    end else if(out_ready) begin
      out_valid <= 1'b0;
    end
  end

  //direct assign signals
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      pc_o <= 32'b0;
      inst_o <= 32'b0;
      RegWrite_o <= 1'b0;
      wb_addr_o <= 5'b0;
      zicsr_o <= 1'b0;
      func3_o <= 3'b0;
      MemWrite_o <= 1'b0;
      MemRead_o <= 1'b0;
      ebreak_o <= 1'b0;
    end else if (in_valid && in_ready) begin
      pc_o <= pc_i;
      inst_o <= inst_i;
      RegWrite_o <= RegWrite_i;
      wb_addr_o <= wb_addr_i;
      zicsr_o <= zicsr_i;
      func3_o <= func3_i;
      MemWrite_o <= MemWrite_i;
      MemRead_o <= MemRead_i;
      ebreak_o <= ebreak_i;
    end
  end

  reg [31:0] pc, pc_predict;
  reg [2:0] func3;
  reg [31:0] imm, data1, data2;
  reg [1:0] ALUAsrc, ALUBsrc;
  reg [3:0] ALUop;
  reg PCAsrc, PCBsrc, branch;
  reg [4:0] zimm;
  reg [31:0] dout_mstatus, dout_mtvec, dout_mepc, dout_mcause, dout_mvendorid, dout_marchid;
  reg ecall, mret;

  always @(posedge clk or posedge rst) begin
    if(rst) begin
      pc <= 32'b0;
      pc_predict <= 32'b0;
      func3 <= 3'b0;
      imm <= 32'b0;
      data1 <= 32'b0;
      data2 <= 32'b0;
      ALUAsrc <= 2'b0;
      ALUBsrc <= 2'b0;
      ALUop <= 4'b0;
      PCAsrc <= 1'b0;
      PCBsrc <= 1'b0;
      branch <= 1'b0;
      zimm <= 5'b0;
      dout_mstatus <= 32'b0;
      dout_mtvec <= 32'b0;
      dout_mepc <= 32'b0;
      dout_mcause <= 32'b0;
      dout_mvendorid <= 32'b0;
      dout_marchid <= 32'b0;
      ecall <= 1'b0;
      mret <= 1'b0;
    end else if (in_valid && in_ready) begin
      pc <= pc_i;
      pc_predict <= pc_predict_i;
      func3 <= func3_i;
      imm <= imm_i;
      data1 <= data1_i;
      data2 <= data2_i;
      ALUAsrc <= ALUAsrc_i;
      ALUBsrc <= ALUBsrc_i;
      ALUop <= ALUop_i;
      PCAsrc <= PCAsrc_i;
      PCBsrc <= PCBsrc_i;
      branch <= branch_i;
      zimm <= zimm_i;
      dout_mstatus <= dout_mstatus_i;
      dout_mtvec <= dout_mtvec_i;
      dout_mepc <= dout_mepc_i;
      dout_mcause <= dout_mcause_i;
      dout_mvendorid <= dout_mvendorid_i;
      dout_marchid <= dout_marchid_i;
      ecall <= ecall_i;
      mret <= mret_i;
    end
  end

  /*-----processing-----*/
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      processing <= 1'b0;
    end else if (in_valid && in_ready) begin
      processing <= 1'b1;
    end else if (out_valid & out_ready) begin
      processing <= 1'b0;
    end
  end

   /*-----branch hazard-----*/
  reg control_hazard_flag; //control hazard only raise 1 cycle every handshake
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      control_hazard_flag <= 1'b0;
    end else if (in_valid & in_ready) begin
      control_hazard_flag <= 1'b1;
    end else begin
      control_hazard_flag <= 1'b0;
    end
  end
  assign control_hazard = control_hazard_flag & (pc_predict != pc_next);

  /*-----Next PC Calculate-----*/
  wire [31:0] PCAdata, PCBdata;
  ysyx_24110015_MuxKey #(2, 1, 32) PCAmux(
    .out(PCAdata),
    .key(PCAsrc),
    .lut({
      1'b0, pc,
      1'b1, data1
    })
  );

  ysyx_24110015_MuxKey #(2, 1, 32) PCBmux(
    .out(PCBdata),
    .key(PCBsrc),
    .lut({
      1'b0, 32'b100,
      1'b1, imm
    })
  );

  wire [31:0] pc_default;

  assign pc_default = PCAdata + PCBdata;

  reg pc_next_valid;
  always @(posedge clk) begin
    if (rst) begin
      pc_next_valid <= 0;
    end else begin
      pc_next_valid <= 1;
    end
  end
  assign pc_next = pc_next_valid ? (branch && (alu_out==32'b1)) ? pc + imm : ecall ? dout_mtvec : mret ? dout_mepc : pc_default : 32'h20000000;

  /*-----ALU Calculate-----*/
  wire [31:0] ALUAdata, ALUBdata;
  ysyx_24110015_MuxKey #(4, 2, 32) ALUAmux(
    .out(ALUAdata),
    .key(ALUAsrc),
    .lut({
      2'b00, data1,
      2'b01, pc,
      2'b10, 32'b0,
      2'b11, 32'b0
    })
  );

  ysyx_24110015_MuxKey #(4, 2, 32) ALUBmux(
    .out(ALUBdata),
    .key(ALUBsrc),
    .lut({
      2'b00, data2,
      2'b01, imm,
      2'b10, 32'b100,
      2'b11, 32'b0
    })
  );
  
  ysyx_24110015_ALU #(32) ALU32(
    .data1(ALUAdata),
    .data2(ALUBdata),
    .ALUop(ALUop),
    .ALUout(alu_out)
  );

  /*-----Memory Access Signal-----*/
  assign mem_wmask = (func3 == 3'b000)? 4'b0001 : (func3 == 3'b001)? 4'b0011 : (func3 == 3'b010)? 4'b1111 : 4'b0000;
  assign mem_wdata = data2;

  /*-----CSR-----*/

  reg [31:0] csr_wdata;
  wire [31:0] csr_data1;
  assign csr_data1 = func3[2] ? {27'b0, zimm} : data1;
  
  always @(*) begin
    case(imm[11:0])
      12'h300: csr_rdata = dout_mstatus;
      12'h305: csr_rdata = dout_mtvec;
      12'h341: csr_rdata = dout_mepc;
      12'h342: csr_rdata = dout_mcause;
      12'hF11: csr_rdata = dout_mvendorid;
      12'hF12: csr_rdata = dout_marchid;
      default: csr_rdata = 32'b0;
    endcase
  end

  // zicsr calculate
  always @(*) begin
    case(func3[1:0]) 
      2'b00: csr_wdata = csr_rdata;
      2'b01: csr_wdata = csr_data1;
      2'b10: csr_wdata = csr_rdata | csr_data1;
      2'b11: csr_wdata = csr_rdata & (~csr_data1);
    endcase
  end

  wire [31:0] din_mstatus_ecall, din_mstatus_mret;
  assign din_mstatus_ecall = (((dout_mstatus & 32'hffffff7f) | (((dout_mstatus >> 3) & 32'b1) << 7)) & 32'hfffffff7) | 32'h00001800;
  assign din_mstatus_mret = (((dout_mstatus & 32'hfffffff7) | (((dout_mstatus >> 7) & 32'b1) << 3)) | 32'h80) & 32'hffffe7ff;
  assign din_mstatus = (zicsr_o&(imm[11:0]==12'h300)) ? csr_wdata : ecall ?  din_mstatus_ecall : mret ? din_mstatus_mret : dout_mstatus;
  assign wen_mstatus = (zicsr_o&(imm[11:0]==12'h300)) | ecall | mret;

  assign din_mtvec = (zicsr_o&(imm[11:0]==12'h305)) ? csr_wdata : dout_mtvec;
  assign wen_mtvec = zicsr_o&(imm[11:0]==12'h305);

  wire [31:0] din_mepc_ecall;
  assign din_mepc_ecall = pc;
  assign din_mepc = (zicsr_o&(imm[11:0]==12'h341)) ? csr_wdata : ecall ? din_mepc_ecall : dout_mepc;
  assign wen_mepc = (zicsr_o&(imm[11:0]==12'h341)) | ecall;

  wire [31:0] din_mcause_ecall;
  assign din_mcause_ecall = 32'h0000000b;
  assign din_mcause = (zicsr_o&(imm[11:0]==12'h342)) ? csr_wdata : ecall ? din_mcause_ecall : dout_mcause;
  assign wen_mcause = (zicsr_o&(imm[11:0]==12'h342)) | ecall;

/*-----performance counter-----*/
`ifndef __SYNTHESIS__
  always@(posedge clk) begin
    if(out_valid & out_ready) begin
        exu_end(inst_o);
    end
    if(in_valid & in_ready) begin
        exu_begin();
    end 
  end
`endif

endmodule