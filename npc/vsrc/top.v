module ysyx_24110015_top(
  input clk,
  input rst,
  input [31:0] inst,
  output [31:0] pc
);
  wire [31:0] pc_next;
  wire [6:0] opcode, func7;
  wire [2:0] func3;
  wire [31:0] imm;
  wire [4:0] rs1, rs2, rd;

  wire rf_wen;
  wire [31:0] rdata1, rdata2, wdata;
  
  ysyx_24110015_Pc pc_reg (
    .clk(clk), 
    .rst(rst), 
    .din(pc_next), 
    .dout(pc)
    );

  ysyx_24110015_IDU idu (
    .clk(clk), 
    .rst(rst), 
    .inst(inst), 
    .opcode(opcode),
    .func7(func7),
    .func3(func3),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .imm(imm)
    );

  ysyx_24110015_RegisterFile #(5, 32) rf (
    .clk(clk), 
    .wdata(wdata),
    .waddr(rd),
    .wen(rf_wen),
    .raddr1(rs1),
    .raddr2(rs2),
    .rdata1(rdata1),
    .rdata2(rdata2)
    );

  ysyx_24110015_EXU exu (
    .clk(clk), 
    .rst(rst), 
    .pc(pc), 
    .opcode(opcode), 
    .func7(func7), 
    .func3(func3), 
    .imm(imm), 
    .data1(rdata1), 
    .data2(rdata2), 
    .data_out(wdata), 
    .pc_next(pc_next),
    .rf_wen(rf_wen)
    );



endmodule
