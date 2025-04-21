`include "macros.v"
import "DPI-C" function void npc_trap();

module ysyx_24110015_EXU (
  input clk,
  input rst,
  //from idu
  input [31:0] pc,
  input [2:0] func3,
  input [31:0] imm,
  input [31:0] data1,
  input [31:0] data2,
  input RegWrite_i,
  input [4:0] wb_addr_i,
  input [1:0] ALUAsrc,
  input [1:0] ALUBsrc,
  input [3:0] ALUop,
  input MemWrite_i,
  input MemRead_i,
  input PCAsrc,
  input PCBsrc,
  input branch,
  input zicsr_i,
  input [4:0] zimm,
  input [31:0] dout_mstatus,
  input [31:0] dout_mtvec,
  input [31:0] dout_mepc,
  input [31:0] dout_mcause,
  input [31:0] dout_mvendorid,
  input [31:0] dout_marchid,
  input ebreak,
  input ecall,
  input mret,
  //to lsu
  output reg [31:0] alu_out,
  output [31:0] pc_next,
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
  output [31:0] mem_wdata
);

  assign RegWrite_o = RegWrite_i;
  assign wb_addr_o = wb_addr_i;
  assign zicsr_o = zicsr_i;
  assign func3_o = func3;
  assign MemWrite_o = MemWrite_i;
  assign MemRead_o = MemRead_i;

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
  assign din_mstatus = (zicsr_i&(imm[11:0]==12'h300)) ? csr_wdata : ecall ?  din_mstatus_ecall : mret ? din_mstatus_mret : dout_mstatus;
  assign wen_mstatus = (zicsr_i&(imm[11:0]==12'h300)) | ecall | mret;

  assign din_mtvec = (zicsr_i&(imm[11:0]==12'h305)) ? csr_wdata : dout_mtvec;
  assign wen_mtvec = zicsr_i&(imm[11:0]==12'h305);

  wire [31:0] din_mepc_ecall;
  assign din_mepc_ecall = pc;
  assign din_mepc = (zicsr_i&(imm[11:0]==12'h341)) ? csr_wdata : ecall ? din_mepc_ecall : dout_mepc;
  assign wen_mepc = (zicsr_i&(imm[11:0]==12'h341)) | ecall;

  wire [31:0] din_mcause_ecall;
  assign din_mcause_ecall = 32'h0000000b;
  assign din_mcause = (zicsr_i&(imm[11:0]==12'h342)) ? csr_wdata : ecall ? din_mcause_ecall : dout_mcause;
  assign wen_mcause = (zicsr_i&(imm[11:0]==12'h342)) | ecall;

/*-----ebreak-----*/
  always @(ebreak) begin
    if(ebreak) begin
      npc_trap();
    end
  end
  

endmodule