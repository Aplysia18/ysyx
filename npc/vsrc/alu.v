`include "macros.v"
module ysyx_24110015_ALU #(DATA_WIDTH=32) (
  input [DATA_WIDTH-1:0] data1,
  input [DATA_WIDTH-1:0] data2,
  input [3:0] ALUop,
  output signed [DATA_WIDTH-1:0] data_out
);

  wire signed [DATA_WIDTH-1:0] sdata1, sdata2;
  assign sdata1 = data1;
  assign sdata2 = data2;

  wire [DATA_WIDTH-1:0] alu_add, alu_sll, alu_slt, alu_sltu, alu_xor, alu_srl, alu_or, alu_and, alu_sub, alu_eq, alu_ne, alu_ge, alu_geu, alu_sra;
  wire [4:0] shamt;
  assign shamt = data2[4:0];
  assign alu_add = data1 + data2;
  assign alu_sll = data1 << shamt;
  assign alu_slt = (sdata1 < sdata2) ? 32'b1 : 32'b0;
  assign alu_sltu = (data1 < data2) ? 32'b1 : 32'b0;
  assign alu_xor = data1 ^ data2;
  assign alu_srl = data1 >> shamt;
  assign alu_or = data1 | data2;
  assign alu_and = data1 & data2;
  assign alu_sub = data1 - data2;
  assign alu_eq = (data1 == data2) ? 32'b1 : 32'b0;
  assign alu_ne = (data1 != data2) ? 32'b1 : 32'b0;
  assign alu_ge = (sdata1 >= sdata2) ? 32'b1 : 32'b0;
  assign alu_geu = (data1 >= data2) ? 32'b1 : 32'b0;
  assign alu_sra = sdata1 >>> shamt;


  ysyx_24110015_MuxKey #(16, 4, 32) ALUmux(
    .out(data_out),
    .key(ALUop),
    .lut({
      `ALU_ADD, alu_add,
      `ALU_SLL, alu_sll,
      `ALU_LT, alu_slt,
      `ALU_LTU, alu_sltu,
      `ALU_XOR, alu_xor,
      `ALU_SRL, alu_srl,
      `ALU_OR, alu_or,
      `ALU_AND, alu_and,
      `ALU_SUB, alu_sub,
      `ALU_EQ, alu_eq,
      `ALU_NE, alu_ne,
      `ALU_GE, alu_ge,
      `ALU_GEU, alu_geu,
      `ALU_SRA, alu_sra,
      4'b1110, 32'b0,
      4'b1111, 32'b0
    })
  );
  

endmodule