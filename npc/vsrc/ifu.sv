// import "DPI-C" function int pmem_read(input int addr);
// import "DPI-C" function void pmem_write(input int waddr, input int wdata, input byte wmask);
// import "DPI-C" function void get_pc(input int pc);
// import "DPI-C" function void get_inst(input int inst);
import "DPI-C" function void ifu_fetch();

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
  axi_if.master axiif
);
  /*-----PC-----*/
  ysyx_24110015_Pc pc_reg (
    .clk(clk), 
    .rst(rst), 
    .wen(control_RegWrite),
    .din(pc_next), 
    .pc(pc)
  ); 

  /*-----AXI&CACHE control-----*/
  localparam CACHE_BLOCK_SIZE = 4,
            CACHE_BLOCK_NUM = 16;
  logic [31:0] cpu_req_addr;
  logic cpu_req_valid;
  logic [8*CACHE_BLOCK_SIZE-1:0] cpu_req_data;
  logic cpu_req_ready;
  logic [31:0] mem_req_addr;
  logic mem_req_valid;
  logic [8*CACHE_BLOCK_SIZE-1:0] mem_req_data;
  logic mem_req_ready;

  logic cacheable; //if address need cache
  logic reg_cacheable;  //record if using cache


  assign control_iMemRead_end = ((cacheable & control_iMemRead) | reg_cacheable) ? cpu_req_ready : axiif.rready & axiif.rvalid;

`ifdef ysyxsoc
  assign cacheable = ((pc>=32'h30000000)&(pc<32'h40000000))|((pc>=32'h80000000)&(pc<32'hc0000000)); //FLASH/PSRAM/SDRAM
`else
  assign cacheable = 1;
`endif

  wire reg_cacheable_in = control_iMemRead_end ? 0 : (cacheable & control_iMemRead);
  ysyx_24110015_Reg #(1, 0) creg(
    .clk(clk), .rst(rst), .din(reg_cacheable_in), .dout(reg_cacheable), .wen(control_iMemRead | control_iMemRead_end) );

`ifndef __SYNTHESIS__
  always @(posedge clk) begin
    if(control_iMemRead)
      ifu_fetch();
  end
`endif

  localparam IDLE = 0;  //wait or cache hit
  localparam AXI_FETCH = 1; //send awvalid and until awready
  localparam AXI_WAIT_READ = 2; //wait for rvalid

  logic [1:0] state, next_state;
  always @(posedge clk or posedge rst) begin 
    if(rst) state <= IDLE;
    else state <= next_state;
  end

  always @(*) begin
    case(state)
      IDLE:
        if(mem_req_valid | (control_iMemRead&~cacheable)) begin
          next_state = AXI_FETCH;
        end else next_state = IDLE;
      AXI_FETCH:
        if(axiif.arready) next_state = AXI_WAIT_READ;
        else next_state = AXI_FETCH;
      AXI_WAIT_READ:
        if(axiif.rvalid) next_state = IDLE;
        else next_state = AXI_WAIT_READ;
    endcase
  end 
  
  assign axiif.arvalid = state==AXI_FETCH;
  assign axiif.araddr = pc;
  
  assign axiif.arsize = 3'b010;
  assign axiif.rready = 1;
  assign axiif.awaddr = 0;
  assign axiif.awvalid = 0;
  assign axiif.wdata = 0;
  assign axiif.wstrb = 0;
  assign axiif.wvalid = 0;
  assign axiif.bready = 0;

  assign cpu_req_addr = pc;
  assign cpu_req_valid = control_iMemRead & cacheable;
  assign mem_req_ready = axiif.rready & axiif.rvalid & reg_cacheable;
  assign mem_req_data = axiif.rdata;
  
  ysyx_24110015_icache #(CACHE_BLOCK_SIZE, CACHE_BLOCK_NUM) icache (
    .clk(clk),
    .rst(rst),
    .cpu_req_addr(cpu_req_addr),
    .cpu_req_valid(cpu_req_valid),
    .cpu_req_data(cpu_req_data),
    .cpu_req_ready(cpu_req_ready),
    .mem_req_addr(mem_req_addr),
    .mem_req_valid(mem_req_valid),
    .mem_req_data(mem_req_data),
    .mem_req_ready(mem_req_ready)
  );

  ysyx_24110015_Reg #(32, 0) inst_reg (
    .clk(clk),
    .rst(rst),
    .din(cacheable ? cpu_req_data : axiif.rdata),
    .dout(inst),
    .wen(control_iMemRead_end)
  );

endmodule