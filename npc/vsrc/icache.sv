import "DPI-C" function void icache_valid();
import "DPI-C" function void icache_ready();

module ysyx_24110015_icache #(
    BLOCK_SIZE = 4, //byte
    BLOCK_NUM = 16
)(
    input clk,
    input rst,

    input [31:0] cpu_req_addr,
    input cpu_req_valid,
    output [8*BLOCK_SIZE-1:0]cpu_req_data,
    output cpu_req_ready,

    output [31:0] mem_req_addr,
    output mem_req_valid,
    input [8*BLOCK_SIZE-1:0] mem_req_data,
    input mem_req_ready
);
    localparam OFFSET_WIDTH = $clog2(BLOCK_SIZE),
            INDEX_WIDTH = $clog2(BLOCK_NUM), 
            TAG_WIDTH = 32-OFFSET_WIDTH-INDEX_WIDTH;

    logic [8*BLOCK_SIZE-1:0] cache_data [0:BLOCK_NUM-1];
    logic [TAG_WIDTH:0] cache_tag [0:BLOCK_NUM-1];

    wire [INDEX_WIDTH-1:0] index = cpu_req_addr[INDEX_WIDTH+OFFSET_WIDTH-1:OFFSET_WIDTH];
    wire [TAG_WIDTH-1:0] tag = cpu_req_addr[31:INDEX_WIDTH+OFFSET_WIDTH]; 
    wire hit = cache_tag[index][TAG_WIDTH:0] == {1'b1, tag};

    parameter IDLE = 0, AXI_FETCH = 1;
    logic state, next_state;

    always @(posedge clk or posedge rst) begin
        if(rst) state <= IDLE;
        else state <= next_state;
    end

    always @(*) begin
        case(state) 
            IDLE: 
                if(cpu_req_valid&~hit) next_state = AXI_FETCH;
                else next_state = IDLE;
            AXI_FETCH:
                if(mem_req_ready) next_state = IDLE;
                else next_state = AXI_FETCH;
        endcase
    end
    
    assign cpu_req_ready = (cpu_req_valid & hit) | ((state==AXI_FETCH)&mem_req_ready);
    assign cpu_req_data = (cpu_req_valid & hit) ? cache_data[index][8*BLOCK_SIZE-1:0] : ((state==AXI_FETCH)&mem_req_ready) ? mem_req_data : 0;

    assign mem_req_addr = cpu_req_addr;
    assign mem_req_valid = ((state==IDLE)&(cpu_req_valid&~hit))|state==AXI_FETCH;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
`ifndef __SYNTHESIS__
            for(int i = 0; i < BLOCK_NUM; i++) begin
                cache_data[i] <= 0;
                cache_tag[i] <= 0;
            end
`endif
        end else begin
            if(mem_req_valid & mem_req_ready) begin
                cache_data[index] <= mem_req_data;
                cache_tag[index] <= {1'b1, tag}; 
            end else begin
                cache_data[index] <= cache_data[index];
                cache_tag[index] <= cache_tag[index];
            end
        end
    end

`ifndef __SYNTHESIS__
    always@(posedge clk) begin
        if(cpu_req_valid) begin
            icache_valid();
        end 
        if(cpu_req_ready) begin
            icache_ready();
        end
    end
`endif

endmodule