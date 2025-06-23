import "DPI-C" function void ifu_fetch();

module ysyx_24110015_IFU (
  input clk,
  input rst,
  //handshake signals
  input in_valid, //ifu valid
  output in_ready, //ifu ready
  output out_valid, //to idu
  input out_ready, //from idu
  //from branch predictor
  input [31:0] pc_predict_bp,
  input pc_predict_valid_bp,
  //for branch hazard
  input control_hazard,
  input [31:0] pc_next,
  //from idu?
  input fence_i,
  //to idu
  output [31:0] inst,
  output [31:0] pc_out,
  output [31:0] pc_predict,
  //to axi
  axi_if.master axiif
);

  logic [2:0] state, next_state;
  localparam IDLE = 0;  //wait or cache hit
  localparam AXI_FETCH = 1; //send awvalid and until awready
  localparam AXI_WAIT_READ = 2; //wait for rvalid
  localparam CACHE_AXI_FETCH = 3;
  localparam CACHE_AXI_WAIT_READ = 4;
  localparam CACHE_AXI_FETCH_SDRAM = 5;
  localparam CACHE_AXI_WAIT_READ_SDRAM = 6;

  logic control_iMemRead, control_iMemRead_end; //ifu fetch start and end signals
  logic flush_refetch, need_refetch;
  logic control_hazard_reg;
  logic [31:0] pc_next_reg;

  /*-----handshake signals-----*/
  assign in_ready = (next_state==IDLE)&~(out_valid & ~out_ready)&~need_refetch; // cache hit / no fetch req

  wire out_valid_begin;
  assign out_valid_begin = (~control_hazard&~control_hazard_reg)? control_iMemRead_end : flush_refetch & control_iMemRead_end; //ifu read request end
  reg out_valid_reg;
  always @(posedge clk or posedge rst) begin
    if(rst) begin
      out_valid_reg <= 0;
    end else if(out_valid_begin & ~out_ready) begin
      out_valid_reg <= 1;
    end else if(out_ready) begin
      out_valid_reg <= 0;
    end
  end
  assign out_valid = out_valid_begin | out_valid_reg;

  /*-----instruction fetch control-----*/
  always @(posedge clk or posedge rst) begin
    if(rst) begin
      control_iMemRead <= 0;
    end else if(in_valid & in_ready) begin
      control_iMemRead <= 1; //ifu read request
    end else if(control_iMemRead_end & need_refetch) begin
      control_iMemRead <= 1; //ifu read request for refetch
    end else begin
      control_iMemRead <= 0; //ifu read request end
    end
  end

  /*-----control hazard-----*/
  always @(posedge clk or posedge rst) begin
    if(rst) begin
      control_hazard_reg <= 0;
      pc_next_reg <= 0;
    end else if((~control_hazard_reg) & control_hazard) begin
      control_hazard_reg <= 1; //control hazard detected
      pc_next_reg <= pc_next; //next pc from idu
    end else if(out_valid) begin
      control_hazard_reg <= 0; //clear control hazard
    end
  end
  
  assign need_refetch = (control_hazard | control_hazard_reg)&~flush_refetch; //need refetch if control hazard or flush refetch

  always @(posedge clk or posedge rst) begin
    if(rst) begin
      flush_refetch <= 0;
    end else if(control_iMemRead_end) begin
      if(need_refetch) begin
        flush_refetch <= 1;
      end else begin
        flush_refetch <= 0;
      end
    end 
  end

  /*-----PC-----*/
  logic [31:0] pc;
  assign pc_predict = pc_predict_valid_bp ? pc_predict_bp : pc + 4; //pc increment
  // always @(posedge clk) begin
  //   if(out_valid & out_ready) begin
  //     $display("pc=%h, predict_pc=%h, pc_predict_valid_bp=%b",pc,pc_predict,pc_predict_valid_bp);
  //   end
  // end
  ysyx_24110015_Pc pc_reg (
    .clk(clk), 
    .rst(rst), 
    .wen((out_valid & out_ready)|(control_iMemRead_end & need_refetch)),
    .din((control_iMemRead_end & need_refetch)?control_hazard_reg?pc_next_reg:pc_next:pc_predict), 
    .pc(pc)
  ); 
  assign pc_out = pc; //pc to idu

  /*-----AXI&CACHE control-----*/
  localparam CACHE_BLOCK_SIZE = 16,
            CACHE_BLOCK_NUM = 16;
  localparam AXI_BURST_ARLEN = CACHE_BLOCK_SIZE/4; //AXI burst size, 4 bytes per word
  localparam CACHE_BLOCK_SIZE_LOG2 = $clog2(CACHE_BLOCK_SIZE);

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

  logic [8*CACHE_BLOCK_SIZE-1 : 0] axi_fetch_cache_data;
  logic axi_fetch_cache_done;

  assign control_iMemRead_end = ((cacheable & control_iMemRead) | reg_cacheable) ? (cpu_req_valid&cpu_req_ready) | axi_fetch_cache_done : axiif.rready & axiif.rvalid;

`ifdef ysyxsoc
  assign cacheable = ((pc>=32'h30000000)&(pc<32'h40000000))|((pc>=32'h80000000)&(pc<32'hc0000000)); //FLASH/PSRAM/SDRAM
  wire in_sdram = (pc>=32'ha0000000) & (pc<32'hc0000000);//burst transfer
`else
  assign cacheable = 1;
  wire in_sdram = 0;
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

  /*-----FSM-----*/
  always @(posedge clk or posedge rst) begin 
    if(rst) state <= IDLE;
    else state <= next_state;
  end

  always @(*) begin
    case(state)
      IDLE:
        if(control_iMemRead&~cacheable) begin
          next_state = AXI_FETCH;
        end else if (mem_req_valid)
          if(in_sdram) next_state = CACHE_AXI_FETCH_SDRAM;
          else next_state = CACHE_AXI_FETCH;
        else next_state = IDLE;
      AXI_FETCH:
        if(axiif.arready) next_state = AXI_WAIT_READ;
        else next_state = AXI_FETCH;
      AXI_WAIT_READ:
        if(axiif.rvalid) next_state = IDLE;
        else next_state = AXI_WAIT_READ;
      CACHE_AXI_FETCH:
        if(axiif.arready) next_state = CACHE_AXI_WAIT_READ;
        else next_state = CACHE_AXI_FETCH;
      CACHE_AXI_WAIT_READ:
        if(axiif.rvalid)
          if(axi_fetch_cache_done) next_state = IDLE;
          else next_state = CACHE_AXI_FETCH;
        else next_state = CACHE_AXI_WAIT_READ;
      CACHE_AXI_FETCH_SDRAM:
        if(axiif.arready) next_state = CACHE_AXI_WAIT_READ_SDRAM;
        else next_state = CACHE_AXI_FETCH_SDRAM;
      CACHE_AXI_WAIT_READ_SDRAM:
        if(axiif.rvalid & axiif.rlast) begin
          next_state = IDLE;
        end else begin
          next_state = CACHE_AXI_WAIT_READ_SDRAM;
        end
      default:
        next_state = IDLE;
    endcase
  end

  logic [2:0] counter;  //counter for no burst cache data fetch
  always @(posedge clk or posedge rst) begin
    if(rst) begin
      counter <= 0;
      axi_fetch_cache_data <= 0;
    end else begin
      case (state)
        IDLE: begin
          counter <= 0;
          axi_fetch_cache_data <= 0;
        end
        AXI_FETCH: begin
          counter <= 0;
          axi_fetch_cache_data <= 0;
        end
        AXI_WAIT_READ: begin
          counter <= 0;
          axi_fetch_cache_data <= 0;
        end
        CACHE_AXI_FETCH:  begin
          counter <= counter;
          axi_fetch_cache_data <= axi_fetch_cache_data;
        end
        CACHE_AXI_WAIT_READ: begin
          if(axiif.rvalid) begin
            counter <= counter+1;
            axi_fetch_cache_data <= {axiif.rdata , axi_fetch_cache_data[8*CACHE_BLOCK_SIZE-1:32]};
          end else begin
            counter <= counter;
          end
        end
        CACHE_AXI_FETCH_SDRAM: begin
          counter <= 0;
          axi_fetch_cache_data <= 0;
        end
        CACHE_AXI_WAIT_READ_SDRAM: begin
          counter <= 0;
          if(axiif.rvalid) begin
            axi_fetch_cache_data <= {axiif.rdata , axi_fetch_cache_data[8*CACHE_BLOCK_SIZE-1:32]};
          end else begin
            axi_fetch_cache_data <= axi_fetch_cache_data;
          end
        end
        default: begin
          counter <= 0;
          axi_fetch_cache_data <= 0;
        end
      endcase
    end
  end

  assign axi_fetch_cache_done = (state==CACHE_AXI_WAIT_READ && axiif.rvalid && {29'b0,counter}==AXI_BURST_ARLEN-1) || (state==CACHE_AXI_WAIT_READ_SDRAM && axiif.rvalid & axiif.rlast);
  
  assign axiif.arvalid = (state==AXI_FETCH) || (state==CACHE_AXI_FETCH) || (state==CACHE_AXI_FETCH_SDRAM);
  assign axiif.araddr = (state==CACHE_AXI_FETCH) ? {pc[31:CACHE_BLOCK_SIZE_LOG2] , counter[CACHE_BLOCK_SIZE_LOG2-3:0], 2'b0} : (state==CACHE_AXI_FETCH_SDRAM) ? {pc[31:CACHE_BLOCK_SIZE_LOG2] , {CACHE_BLOCK_SIZE_LOG2{1'b0}}}: pc;
  assign axiif.arid = 0; //AXI ID, not used
  assign axiif.arlen = in_sdram ? AXI_BURST_ARLEN-1 : 8'h0; //burst length, 0 for single transfer, 1 for burst of 2
  assign axiif.arburst = in_sdram ? 2'b01 : 2'b00; //burst type, 01 for INCR, 00 for FIXED
  
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
  assign mem_req_ready = axi_fetch_cache_done & reg_cacheable;
  assign mem_req_data = {axiif.rdata , axi_fetch_cache_data[8*CACHE_BLOCK_SIZE-1:32]};

  wire cache_flush = control_iMemRead & fence_i;
  
  ysyx_24110015_icache #(CACHE_BLOCK_SIZE, CACHE_BLOCK_NUM) icache (
    .clk(clk),
    .rst(rst),
    .flush(cache_flush),
    .cpu_req_addr(cpu_req_addr),
    .cpu_req_valid(cpu_req_valid),
    .cpu_req_data(cpu_req_data),
    .cpu_req_ready(cpu_req_ready),
    .mem_req_addr(mem_req_addr),
    .mem_req_valid(mem_req_valid),
    .mem_req_data(mem_req_data),
    .mem_req_ready(mem_req_ready)
  );

  wire [31:0] inst_in_cache_data = cpu_req_data[(pc[CACHE_BLOCK_SIZE_LOG2-1:2] * 32) +: 32];
  
  reg [31:0] inst_reg;
  wire [31:0] inst_din = cacheable ? inst_in_cache_data : axiif.rdata;
  ysyx_24110015_Reg #(32, 0) inst_register (
    .clk(clk),
    .rst(rst),
    .din(inst_din),
    .dout(inst_reg),
    .wen(control_iMemRead_end)
  );
  assign inst = control_iMemRead_end?inst_din:inst_reg;

endmodule