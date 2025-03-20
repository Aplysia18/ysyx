// import "DPI-C" function int pmem_read(input int addr);
// import "DPI-C" function void pmem_write(input int waddr, input int wdata, input byte wmask);
// import "DPI-C" function void get_pc(input int pc);
// import "DPI-C" function void get_inst(input int inst);

module ysyx_24110015_IFU (
  input clk,
  input rst,
  //from controller
  input control_RegWrite,
  input control_iMemRead,
  //from wbu
  input [31:0] pc_next,
  //to idu
  output reg [31:0] inst,
  output [31:0] pc,
  //to controller
  output control_iMemRead_end,
  //to axi
  axi_lite_if.master axiif
);

  ysyx_24110015_Pc pc_reg (
    .clk(clk), 
    .rst(rst), 
    .wen(control_RegWrite),
    .din(pc_next), 
    .pc(pc)
  );

  // axi_lite_if axiif(
  //   .clk(clk),
  //   .rst(rst)
  // );

  assign control_iMemRead_end = axiif.rready & axiif.rvalid;
  
  assign axiif.araddr = pc;
  // assign axiif.arvalid = control_iMemRead;
  always @(posedge clk or posedge rst) begin
    if(rst) begin
      axiif.arvalid <= 0;
    end else begin
      if(axiif.arvalid) begin
        if(axiif.arready) begin
          axiif.arvalid <= 0;
        end
      end else if(control_iMemRead) begin
        axiif.arvalid <= 1;
      end else begin
        axiif.arvalid <= axiif.arvalid;
      end
    end
  end
  assign axiif.rready = 1;
  assign axiif.awaddr = 0;
  assign axiif.awvalid = 0;
  assign axiif.wdata = 0;
  assign axiif.wstrb = 0;
  assign axiif.wvalid = 0;
  assign axiif.bready = 0;

//   ysyx_24110015_AXI2MEM IFU_AXI2MEM (
//     .clk(clk),
//     .rst(rst),
//     .axi(axiif)
// );

  ysyx_24110015_Reg #(32, 0) inst_reg (
    .clk(clk),
    .rst(rst),
    .din(axiif.rdata),
    .dout(inst),
    .wen(control_iMemRead_end)
  );

endmodule