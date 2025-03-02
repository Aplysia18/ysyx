`include "macros.v"
import "DPI-C" function void npc_trap();
// import "DPI-C" function int pmem_read(input int addr);
// import "DPI-C" function void pmem_write(input int waddr, input int wdata, input byte wmask);

module ysyx_24110015_EXU (
  input clk,
  input rst,
  input [31:0] pc,
  input [2:0] func3,
  input [31:0] imm,
  input [31:0] data1,
  input [31:0] data2,
  input [1:0] ALUAsrc,
  input [1:0] ALUBsrc,
  input [3:0] ALUop,
  input MemWrite,
  input MemRead,
  input PCAsrc,
  input PCBsrc,
  input branch,
  input zicsr,
  input [4:0] zimm,
  input ebreak,
  input ecall,
  input mret,
  output reg [31:0] data_out,
  output [31:0] pc_next
);

  wire [31:0] ALUout;

  reg [31:0] csr_rdata, csr_wdata;
  wire [31:0] din_mstatus, din_mtvec, din_mepc, din_mcause;
  wire wen_mstatus, wen_mtvec, wen_mepc, wen_mcause;
  wire [31:0] dout_mstatus, dout_mtvec, dout_mepc, dout_mcause;

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
  assign pc_next = pc_next_valid ? (branch && (ALUout==32'b1)) ? pc + imm : ecall ? dout_mtvec : mret ? dout_mepc : pc_default : 32'h80000000;

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

  wire[31:0] dmem_rdata1, dmem_rdata2;
  reg[31:0] dmem_wdata;
  wire[7:0] dmem_waddr, dmem_raddr1, dmem_raddr2;
  wire dmem_wen;

  ysyx_24110015_RegisterFile #(8, 32) dmem (
    .clk(clk),
    .wdata(dmem_wdata),
    .waddr(dmem_waddr),
    .wen(dmem_wen),
    .raddr1(dmem_raddr1),
    .raddr2(dmem_raddr2),
    .rdata1(dmem_rdata1),
    .rdata2(dmem_rdata2)
);

  assign dmem_raddr1 = ALUout[7:0];
  assign dmem_raddr2 = ALUout[7:0];

  always @(*) begin
    if (MemRead) begin
      // rdata = pmem_read(ALUout);
      rdata = dmem_rdata1;
    end else begin
      rdata = 32'b0;
    end
  end

  always @(negedge clk) begin
    if (MemRead) begin
      case (func3)
        3'b000: data_out <= {{24{rdata[7]}}, rdata[7:0]};
        3'b001: data_out <= {{16{rdata[15]}}, rdata[15:0]};
        3'b010: data_out <= rdata;
        3'b100: data_out <= {24'b0, rdata[7:0]};
        3'b101: data_out <= {16'b0, rdata[15:0]};
        default: data_out <= 32'b0;
      endcase
    end
    else begin
      if(zicsr) begin
        data_out <= csr_rdata;
      end
      else begin
        data_out <= ALUout;
      end
    end
  end

  assign dmem_wen = MemWrite;
  assign dmem_waddr = ALUout[7:0];

  always @(posedge clk) begin
    if(MemWrite) begin
      case (func3)
        // 3'b000: pmem_write(ALUout, data2, 8'b0001);
        // 3'b001: pmem_write(ALUout, data2, 8'b0011);
        // 3'b010: pmem_write(ALUout, data2, 8'b1111);
        // default: pmem_write(ALUout, data2, 8'b0000);
        3'b000: dmem_wdata = (dmem_rdata1&32'hfff0) | (data2 & 32'h000f);
        3'b001: dmem_wdata = (dmem_rdata1&32'hff00) | (data2 & 32'h00ff);
        3'b010: dmem_wdata = data2;
        default: dmem_wdata = dmem_rdata1;
      endcase
    end
  end

  /*-----CSR-----*/

  wire [31:0] csr_data1;
  assign csr_data1 = func3[2] ? {27'b0, zimm} : data1;
  
  always @(*) begin
    case(imm[11:0])
      12'h300: csr_rdata = dout_mstatus;
      12'h305: csr_rdata = dout_mtvec;
      12'h341: csr_rdata = dout_mepc;
      12'h342: csr_rdata = dout_mcause;
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
  assign din_mstatus = (zicsr&(imm[11:0]==12'h300)) ? csr_wdata : ecall ?  din_mstatus_ecall : mret ? din_mstatus_mret : dout_mstatus;
  assign wen_mstatus = (zicsr&(imm[11:0]==12'h300)) | ecall | mret;

  assign din_mtvec = (zicsr&(imm[11:0]==12'h305)) ? csr_wdata : dout_mtvec;
  assign wen_mtvec = (zicsr&(imm[11:0]==12'h305));

  wire [31:0] din_mepc_ecall;
  assign din_mepc_ecall = pc;
  assign din_mepc = (zicsr&(imm[11:0]==12'h341)) ? csr_wdata : ecall ? din_mepc_ecall : dout_mepc;
  assign wen_mepc = (zicsr&(imm[11:0]==12'h341)) | ecall;

  wire [31:0] din_mcause_ecall;
  assign din_mcause_ecall = 32'h0000000b;
  assign din_mcause = (zicsr&(imm[11:0]==12'h342)) ? csr_wdata : ecall ? din_mcause_ecall : dout_mcause;
  assign wen_mcause = (zicsr&(imm[11:0]==12'h342)) | ecall;


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
    .dout_mcause(dout_mcause)
  );

/*-----ebreak-----*/
  // always @(ebreak) begin
  //   if(ebreak) begin
  //     npc_trap();
  //   end
  // end
  

endmodule