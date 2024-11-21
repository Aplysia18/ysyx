`include "macros.v"

module ysyx_24110015_EXU (
  input clk,
  input rst,
  input [31:0] pc,
  input [6:0] opcode,
  input [6:0] func7,
  input [2:0] func3,
  input [31:0] imm,
  input [31:0] data1,
  input [31:0] data2,
  output [31:0] data_out,
  output [31:0] pc_next,
  output rf_wen
);
  
  wire addi;
  wire [31:0] alu_out;

  assign pc_next = pc + 4;

  assign addi = (opcode == `ALU_I_type) && (func3 == 3'b000);

  // outports wire
  wire [31:0] 	dout;
  
  ysyx_24110015_Addr #(32) addr32(
    .ina(data1),
    .inb(imm),
    .outy(alu_out)
  );

  assign data_out = addi ? alu_out: 32'b0;
  assign rf_wen = addi ? 1'b1 : 1'b0;
  

endmodule