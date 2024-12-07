`include "macros.v"
import "DPI-C" function void npc_trap();

module ysyx_24110015_EXU (
  input clk,
  input rst,
  input [31:0] pc,
  input [31:0] imm,
  input [31:0] data1,
  input [31:0] data2,
  input [1:0] ALUAsrc,
  input [1:0] ALUBsrc,
  input PCAsrc,
  input PCBsrc,
  input ebreak,
  output [31:0] data_out,
  output [31:0] pc_next
);
  
  wire addi;
  wire [31:0] alu_out;

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

  assign pc_next = PCAdata + PCBdata;

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
  
  ysyx_24110015_Addr #(32) addr32(
    .ina(ALUAdata),
    .inb(ALUBdata),
    .outy(data_out)
  );

  always @(*) begin
    if(ebreak) begin
      npc_trap();
    end
  end
  

endmodule