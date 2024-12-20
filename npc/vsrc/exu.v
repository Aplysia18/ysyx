`include "macros.v"
import "DPI-C" function void npc_trap();
// import "DPI-C" function int pmem_read(input int addr);
// import "DPI-C" function void pmem_write(input int waddr, input int wdata, input byte wmask);

module ysyx_24110015_EXU (
  input clk,
  input rst,
  input [31:0] pc,
  input [31:0] imm,
  input [31:0] data1,
  input [31:0] data2,
  input [1:0] ALUAsrc,
  input [1:0] ALUBsrc,
  input [3:0] ALUop,
  input MemWrite,
  input MemRead,
  input [2:0] MemOp,
  input PCAsrc,
  input PCBsrc,
  input branch,
  input ebreak,
  output reg [31:0] data_out,
  output [31:0] pc_next
);

  wire [31:0] ALUout;

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
  assign pc_next = (branch && (ALUout==32'b1)) ? pc + imm : pc_default;

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
    .ALUout(ALUout)
  );

  /*-----Memory Access-----*/
  reg [31:0] rdata;
  wire mem_valid;
  assign mem_valid = MemWrite | MemRead;
  always @(negedge clk or posedge clk) begin
    if (MemWrite) begin
      case (MemOp)
        3'b000: pmem_write(ALUout, data2, 8'b0001);
        3'b001: pmem_write(ALUout, data2, 8'b0011);
        3'b010: pmem_write(ALUout, data2, 8'b1111);
        default: pmem_write(ALUout, data2, 8'b0000);
      endcase
    end
    else if (MemRead) begin
      rdata = pmem_read(ALUout);
      case (MemOp)
        3'b000: data_out <= {{24{rdata[7]}}, rdata[7:0]};
        3'b001: data_out <= {{16{rdata[15]}}, rdata[15:0]};
        3'b010: data_out <= rdata;
        3'b100: data_out <= {24'b0, rdata[7:0]};
        3'b101: data_out <= {16'b0, rdata[15:0]};
        default: data_out <= 32'b0;
      endcase
    end else begin
      data_out <= ALUout;
    end
  end

  always @(ebreak) begin
    if(ebreak) begin
      npc_trap();
    end
  end
  

endmodule