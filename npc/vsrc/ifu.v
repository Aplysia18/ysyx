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
  output control_iMemRead_end
);

  wire [31:0] rdata;

  ysyx_24110015_Pc pc_reg (
    .clk(clk), 
    .rst(rst), 
    .wen(control_RegWrite),
    .din(pc_next), 
    .pc(pc)
  );

  wire arready, rvalid, awready, wready, bvalid;
  wire [1:0] rresp, bresp;

  assign control_iMemRead_end = control_iMemRead & rvalid;

  ysyx_24110015_AXI2MEM IFU_AXI2MEM (
    .clk(clk),
    .rst(rst),
    // AR channel
    .araddr(pc),
    .arvalid(control_iMemRead),
    .arready(arready),
    // R channel
    .rdata(rdata),
    .rresp(rresp),
    .rvalid(rvalid),
    .rready(control_iMemRead), 
    // AW channel
    .awaddr(0),
    .awvalid(0),
    .awready(awready),
    // W channel
    .wdata(0),
    .wstrb(0),
    .wvalid(0),
    .wready(wready),
    // B channel
    .bresp(bresp),
    .bvalid(bvalid),
    .bready(0)
);

  // always @(*) begin
  //   if(!rst) begin
  //     inst = rdata;
  //     // get_pc(pc);
  //     // get_inst(inst);
  //   end else begin
  //     inst = 32'h0;
  //   end
  // end

  ysyx_24110015_Reg #(32, 0) inst_reg (
    .clk(clk),
    .rst(rst),
    .din(rdata),
    .dout(inst),
    .wen(control_iMemRead_end)
  );

  // always @(posedge clk or posedge rst) begin
  //   if(rst) begin
  //     inst = 0;
  //   end else if(control_iMemRead_end) begin
  //     inst = rdata;
  //   end else begin

  // end

endmodule