`include "macros.v"

module ysyx_24110015_IDU (
  input clk,
  input rst,
  input [31:0] inst,
  output [6:0] opcode,
  output [6:0] func7,
  output [2:0] func3,
  output [4:0] rs1,
  output [4:0] rs2,
  output [4:0] rd,
  output [31:0] imm
);
  wire [31:0] immI, immS, immB, immU, immJ;
  wire R_type, I_type, S_type, B_type, U_type, J_type;

  assign opcode = inst[6:0];
  assign func7 = inst[31:25];
  assign func3 = inst[14:12];
  assign rs1 = inst[19:15];
  assign rs2 = inst[24:20];
  assign rd = inst[11:7];
  assign immI = {{20{inst[31]}}, inst[31:20]};
  assign immS = {{20{inst[31]}}, inst[31:25], inst[11:7]};
  assign immB = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
  assign immU = {inst[31:12], 12'b0};
  assign immJ = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
  
//   assign R_type = (opcode == `ALU_R_type);
  assign I_type = (opcode == `load) || (opcode == `jalr) || (opcode == `ALU_I_type);
  assign S_type = (opcode == `S_type);
  assign B_type = (opcode == `B_type);
  assign U_type = (opcode == `lui) || (opcode == `auipc);
  assign J_type = (opcode == `jal);

  assign imm = I_type ? immI : S_type ? immS : B_type ? immB : U_type ? immU : J_type ? immJ : 32'b0;

endmodule