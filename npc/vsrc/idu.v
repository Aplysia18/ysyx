`include "macros.v"
import "DPI-C" function void idu_begin();
import "DPI-C" function void idu_end(input int inst);

module ysyx_24110015_IDU (
  input clk,
  input rst, 
  // handshake signals
  input in_valid, //idu valid
  output in_ready, //idu ready
  output reg out_valid, //to exu
  input out_ready, //from exu
  //to conflict detection
  output reg processing,
  output reg1_read,
  output reg2_read,
  output [4:0] raddr1,
  output [4:0] raddr2,
  input RAW_check,
  //for branch hazard
  input control_hazard,
  //from ifu
  input [31:0] inst_i,
  input [31:0] pc_i,
  input [31:0] pc_predict_i,
  //from wbu
  input RegWrite_i,
  input [4:0] wb_addr_i,
  input [31:0] din_mstatus,
  input [31:0] din_mtvec,
  input [31:0] din_mepc,
  input [31:0] din_mcause,
  input wen_mstatus,
  input wen_mtvec,
  input wen_mepc,
  input wen_mcause,
  input [31:0] wb_data,
  //to exu
  output reg [31:0] pc_o,
  output reg [31:0] inst_o,
  output reg [31:0] pc_predict_o,
  output [2:0] func3,
  output [31:0] imm,
  output [31:0] rdata1,
  output [31:0] rdata2,
  output RegWrite_o,
  output [4:0] wb_addr_o,
  output [1:0] ALUAsrc,
  output [1:0] ALUBsrc,
  output reg [3:0] ALUop,
  output MemWrite,
  output MemRead,
  output PCAsrc,
  output PCBsrc,
  output branch,
  output zicsr,
  output [4:0] zimm,
  output [31:0] dout_mstatus,
  output [31:0] dout_mtvec,
  output [31:0] dout_mepc,
  output [31:0] dout_mcause,
  output [31:0] dout_mvendorid,
  output [31:0] dout_marchid,
  output ebreak,
  output ecall,
  output fence_i,
  output mret
);

  /*-----handshake signals-----*/
  assign in_ready = ~RAW_check & out_ready; // ready when no RAW hazard
  assign out_valid = processing & ~RAW_check & ~control_hazard;
  
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      pc_o <= 0;
      pc_predict_o <= 0;
    end else if (in_valid && in_ready) begin
      pc_o <= pc_i;
      pc_predict_o <= pc_predict_i;
    end
  end

  reg [31:0] inst;
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      inst <= 32'b0;
      inst_o <= 32'b0;
    end else if (in_valid && in_ready) begin
      inst <= inst_i;
      inst_o <= inst_i;
    end
  end

  /*-----processing-----*/
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      processing <= 1'b0;
    end else if (in_valid && in_ready) begin
      processing <= 1'b1;
    end else if(control_hazard) begin
      processing <= 1'b0; //flush
    end else if (out_valid & out_ready) begin
      processing <= 1'b0;
    end
  end

  /*-----imm gen-----*/
  wire [6:0] opcode, func7;
  wire [31:0] immI, immS, immB, immU, immJ;
  wire R_type, I_type, S_type, B_type, U_type, J_type;

  assign opcode = inst[6:0];
  assign func7 = inst[31:25];
  assign func3 = inst[14:12];
  assign immI = {{20{inst[31]}}, inst[31:20]};
  assign immS = {{20{inst[31]}}, inst[31:25], inst[11:7]};
  assign immB = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
  assign immU = {inst[31:12], 12'b0};
  assign immJ = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
  
  assign R_type = (opcode == `ALU_R_type);
  assign I_type = (opcode == `load) || (opcode == `jalr) || (opcode == `ALU_I_type) || zicsr;
  assign S_type = (opcode == `S_type);
  assign B_type = (opcode == `B_type);
  assign U_type = (opcode == `lui) || (opcode == `auipc);
  assign J_type = (opcode == `jal);

  assign imm = I_type ? immI : S_type ? immS : B_type ? immB : U_type ? immU : J_type ? immJ : 32'b0;

  // conflict detection signals
  assign reg1_read = R_type | (zicsr ? inst[14]==0 : I_type) | S_type | B_type;
  assign reg2_read = R_type | S_type | B_type;

  /*-----Reg Write Single Generation-----*/
  assign RegWrite_o = R_type || I_type || U_type || J_type;

  /*-----Read Reg Data-----*/
  assign wb_addr_o = {1'b0, inst[10:7]};
  assign raddr1 = inst[19:15];
  assign raddr2 = inst[24:20];
  ysyx_24110015_RegisterFile #(4, 32) rf (
    .clk(clk), 
    .wdata(wb_data),
    .waddr(wb_addr_i[3:0]),
    .wen(RegWrite_i),
    .raddr1(raddr1[3:0]),
    .raddr2(raddr2[3:0]),
    .rdata1(rdata1),
    .rdata2(rdata2)
  );

  /*-----ALU data select control signal generation-----*/
  wire ALUAsrc_rs1, ALUAsrc_pc, ALUAsrc_0;
  wire ALUBsrc_rs2, ALUBsrc_imm, ALUBsrc_4;
  assign ALUAsrc_0 = (opcode == `lui)? 1 : 0;
  assign ALUAsrc_pc = (opcode == `auipc || opcode == `jal || opcode == `jalr)? 1 : 0;
  assign ALUAsrc_rs1 = ~(ALUAsrc_pc | ALUAsrc_0);
  assign ALUBsrc_rs2 = (opcode == `ALU_R_type || opcode == `B_type)? 1 : 0;
  assign ALUBsrc_4 = (opcode == `jal || opcode == `jalr)? 1 : 0;
  assign ALUBsrc_imm = ~(ALUBsrc_rs2 | ALUBsrc_4);

  assign ALUAsrc = ALUAsrc_rs1 ? 2'b00 : ALUAsrc_pc ? 2'b01 : ALUAsrc_0 ? 2'b10 : 2'b11;  //0: rs1, 1:pc, 2:0
  assign ALUBsrc = ALUBsrc_rs2 ? 2'b00 : ALUBsrc_imm ? 2'b01 : ALUBsrc_4 ? 2'B10 : 2'b11;  //0: rs2, 1:imm, 2:4

  /*-----ALU operation control signal generation-----*/
  reg [3:0]b_type_alu_op;
  //ALU op select for B type
  ysyx_24110015_MuxKey #(8, 3, 4) BTypeALUOpmux(
    .out(b_type_alu_op),
    .key(func3),
    .lut({
      3'b000, `ALU_EQ,
      3'b001, `ALU_NE,
      3'b010, 4'b1111,
      3'b011, 4'b1111,
      3'b100, `ALU_LT,
      3'b101, `ALU_GE,
      3'b110, `ALU_LTU,
      3'b111, `ALU_GEU
    })
  );

  always @(*) begin
    case (opcode)
      `lui: ALUop = `ALU_ADD;
      `auipc: ALUop = `ALU_ADD;
      `jal: ALUop = `ALU_ADD;
      `jalr: ALUop = `ALU_ADD;
      `B_type: ALUop = b_type_alu_op;
      `load: ALUop = `ALU_ADD;
      `S_type: ALUop = `ALU_ADD;
      `ALU_I_type: ALUop = (func3==3'b101) ? {func7[5], func3} : {1'b0, func3};
      `ALU_R_type: ALUop = {func7[5], func3};
      default: ALUop = 4'b1111;
    endcase
  end

  /*-----PC control single generation-----*/
  assign PCAsrc = (opcode == `jalr) ? 1 : 0; //0: pc, 1:rs1
  assign PCBsrc = (opcode == `jal || opcode == `jalr) ? 1 : 0;  //0: 4, 1: imm 

  /*-----csr control-----*/
  ysyx_24110015_CSR csr (
    .clk(clk),
    .rst(rst),
    .din_mstatus(din_mstatus),
    .din_mtvec(din_mtvec),
    .din_mepc(din_mepc),
    .din_mcause(din_mcause),
    .wen_mstatus(wen_mstatus),
    .wen_mtvec(wen_mtvec),
    .wen_mepc(wen_mepc),
    .wen_mcause(wen_mcause),
    .dout_mstatus(dout_mstatus),
    .dout_mtvec(dout_mtvec),
    .dout_mepc(dout_mepc),
    .dout_mcause(dout_mcause),
    .dout_mvendorid(dout_mvendorid),
    .dout_marchid(dout_marchid)
  );

  /*-----branch signal-----*/
  assign branch = B_type;

  /*-----Mem control single generation-----*/
  assign MemWrite = (opcode == `S_type);
  assign MemRead = (opcode == `load);

  /*-----zicsr control-----*/
  assign zicsr = (opcode == `zicsr);
  assign zimm = inst[19:15];

  /*-----ebreak&ecall single-----*/
  assign ebreak = (inst==32'h00100073);
  assign ecall = (inst==32'h00000073);

  /*-----fence.i control-----*/
  assign fence_i = (opcode == `fence) && (func3 == 3'b001);

  /*-----mret single-----*/
  assign mret = (inst==32'h30200073);

  /*-----performance counter-----*/
`ifndef __SYNTHESIS__
  always@(posedge clk) begin
    if(out_valid & out_ready) begin
        idu_end(inst_o);
    end
    if(in_valid & in_ready) begin
        idu_begin();
    end 
  end
`endif

endmodule