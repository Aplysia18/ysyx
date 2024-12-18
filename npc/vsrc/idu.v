`include "macros.v"

module ysyx_24110015_IDU (
  input clk,
  input rst,
  input [31:0] inst,
  output [6:0] opcode,
  output [6:0] func7,
  output [2:0] func3,
  output [31:0] imm,
  output RegWrite,
  output [1:0] ALUAsrc,
  output [1:0] ALUBsrc,
  output reg [3:0] ALUop,
  output PCAsrc,
  output PCBsrc,
  output branch,
  output ebreak
);

  /*-----imm gen-----*/
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
  assign I_type = (opcode == `load) || (opcode == `jalr) || (opcode == `ALU_I_type);
  assign S_type = (opcode == `S_type);
  assign B_type = (opcode == `B_type);
  assign U_type = (opcode == `lui) || (opcode == `auipc);
  assign J_type = (opcode == `jal);

  assign imm = I_type ? immI : S_type ? immS : B_type ? immB : U_type ? immU : J_type ? immJ : 32'b0;

  /*-----Reg Write Single Generation-----*/
  assign RegWrite = R_type || I_type || U_type || J_type;

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
      `ALU_I_type: ALUop = {1'b0, func3};
      `ALU_R_type: ALUop = {func7[5], func3};
      default: ALUop = 4'b1111;
    endcase
  end

  /*-----PC control single generation-----*/
  assign PCAsrc = (opcode == `jalr) ? 1 : 0; //0: pc, 1:rs1
  assign PCBsrc = (opcode == `jal || opcode == `jalr) ? 1 : 0;  //0: 4, 1: imm 

  assign branch = B_type;

  /*-----ebreak single-----*/
  assign ebreak = (inst==32'h00100073);

endmodule