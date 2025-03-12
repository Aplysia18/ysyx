module ysyx_24110015_AXI2MEM (
    input clk,
    input rst,
    // AR channel
    input [31:0] araddr,
    input arvalid,
    output arready,
    // R channel
    output [31:0] rdata,
    output [1:0] rresp,
    output rvalid,
    input rready, 
    // AW channel
    input [31:0] awaddr,
    input awvalid,
    output awready,
    // W channel
    input [31:0] wdata,
    input [3:0] wstrb,
    input wvalid,
    output wready,
    // B channel
    output [1:0] bresp,
    output bvalid,
    input bready
);

    reg [2:0] state, next_state;
    parameter IDLE = 3'b000, READ = 3'b001, WRITE = 3'b010, WRITE_WAIT_DATA = 3'b011, WRITE_WAIT_ADDR = 3'b110;

    always @(posedge clk or posedge rst) begin
        if(!rst) begin
            state <= next_state;
        end else begin
            state <= IDLE;
        end
    end

    always @(*) begin
        case(state)
            IDLE: begin
                if(arvalid & arready) begin
                    next_state = READ;
                end else if(awvalid & awready) begin
                    if(wvalid & wready) next_state = WRITE;
                    else next_state = WRITE_WAIT_DATA;
                end else if(wvalid & wready) begin
                    next_state = WRITE_WAIT_ADDR;
                end else begin
                    next_state = IDLE;
                end
            end
            READ: begin
                if(rvalid & rready) next_state = IDLE;
                else next_state = READ;
            end
            WRITE_WAIT_ADDR: begin
                if(awvalid & awready) begin
                    next_state = WRITE;
                end else begin
                    next_state = WRITE_WAIT_ADDR;
                end
            end
            WRITE_WAIT_DATA: begin
                if(wvalid & wready) begin
                    next_state = WRITE;
                end else begin
                    next_state = WRITE_WAIT_DATA;
                end
            end
            WRITE: begin
                if(bvalid & bready) next_state = IDLE;
                else next_state = WRITE;
            end
            default: next_state = IDLE;
        endcase
    end

    reg sram_wen, sram_ren;
    reg sram_wen_flag, sram_ren_flag;
    reg [31:0] sram_aradder, sram_awadder, sram_wdata;
    reg sram_araddr_flag, sram_awaddr_flag, sram_wdata_flag;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            sram_wen <= 0;
            sram_ren <= 0;
            sram_wen_flag <= 0;
            sram_ren_flag <= 0;
            sram_aradder <= 0;
            sram_awadder <= 0;
            sram_wdata <= 0;
            sram_araddr_flag <= 0;
            sram_awaddr_flag <= 0;
            sram_wdata_flag <= 0;
        end else
        case(next_state)
            IDLE: begin
                sram_ren <= 0;
                sram_ren_flag <= 0;
                sram_wen <= 0;
                sram_wen_flag <= 0;
                sram_araddr_flag <= 0;
                sram_awaddr_flag <= 0;
                sram_wdata_flag <= 0;
            end
            READ: begin
                if(sram_ren_flag) begin
                    sram_ren <= 0;
                end else begin
                    sram_ren <= 1;
                    sram_ren_flag <= 1;
                end
                if(~sram_araddr_flag) begin
                    sram_aradder <= araddr;
                    sram_araddr_flag <= 1;
                end
            end
            WRITE_WAIT_ADDR: begin
                if(~sram_awaddr_flag) begin
                    sram_awadder <= awaddr;
                    sram_awaddr_flag <= 1;
                end
            end
            WRITE_WAIT_DATA: begin
                if(~sram_wdata_flag) begin
                    sram_wdata <= wdata;
                    sram_wdata_flag <= 1;
                end
            end
            WRITE: begin
                if(sram_wen_flag) begin
                    sram_wen <= 0;
                end else begin
                    sram_wen <= 1;
                    sram_wen_flag <= 1;
                end
                if(~sram_awaddr_flag) begin
                    sram_awadder <= awaddr;
                    sram_awaddr_flag <= 1;
                end
                if(~sram_wdata_flag) begin
                    sram_wdata <= wdata;
                    sram_wdata_flag <= 1;
                end
            end
            default: begin
                sram_ren <= 0;
                sram_ren_flag <= 0;
                sram_wen <= 0;
                sram_wen_flag <= 0;
                sram_araddr_flag <= 0;
                sram_awaddr_flag <= 0;
                sram_wdata_flag <= 0;
            end
        endcase
    end

    ysyx_24110015_SRAM #(32, 32) sram(   
        .clk(clk),
        .rst(rst),
        //read
        .araddr(sram_aradder),
        .ren(sram_ren),
        .rdata(rdata),
        .rresp(rresp),
        .rvalid(rvalid),
        //write
        .awaddr(sram_awadder),
        .wdata(sram_wdata),
        .wen(sram_wen),
        .wstrb(wstrb),
        .bresp(bresp),
        .bvalid(bvalid)
    );

    assign arready = (state == IDLE);
    assign awready = (state == IDLE) | (state == WRITE_WAIT_ADDR);
    assign wready = (state == IDLE) | (state == WRITE_WAIT_DATA);

endmodule