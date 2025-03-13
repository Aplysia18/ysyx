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
  reg arvalid, rready;

  assign control_iMemRead_end = rready & rvalid;

  wire [7:0] delay_cycles;
  ysyx_24110015_shiftRegister delay_counter_ifu (
    .clk(clk),
    .rst(rst),
    .y(delay_cycles)
  );
  reg [7:0] delay_counters_arvalid;
  reg [7:0] delay_counters_rready;

  always @(posedge clk or posedge rst) begin
    if(rst) begin
      delay_counters_arvalid <= delay_cycles;
      arvalid <= 0;
      rready <= 0;
    end else if (control_iMemRead) begin
      if(delay_counters_arvalid == 0) begin
        delay_counters_arvalid <= delay_cycles;
        arvalid <= 1;
        rready <= 1;
      end else begin
        delay_counters_arvalid <= delay_counters_arvalid - 1;
        arvalid <= 0;
        rready <= 0;
      end
    end else begin
      arvalid <= 0;
      rready <= 0;
    end
  end

  ysyx_24110015_AXI2MEM IFU_AXI2MEM (
    .clk(clk),
    .rst(rst),
    // AR channel
    .araddr(pc),
    .arvalid(arvalid),
    .arready(arready),
    // R channel
    .rdata(rdata),
    .rresp(rresp),
    .rvalid(rvalid),
    .rready(rready), 
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

  ysyx_24110015_Reg #(32, 0) inst_reg (
    .clk(clk),
    .rst(rst),
    .din(rdata),
    .dout(inst),
    .wen(control_iMemRead_end)
  );

endmodule