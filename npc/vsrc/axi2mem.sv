`ifndef ysyxsoc
module ysyx_24110015_AXI2MEM (
    input clk,
    input rst,
    axi_if.slave axi
);

    reg [2:0] state, next_state;
    parameter IDLE = 3'b000, READ = 3'b001, WAIT_RREADY = 3'b011, WRITE_WAIT_DATA = 3'b010, WRITE_WAIT_ADDR = 3'b110, WRITE = 3'b100, WAIT_BREADY = 3'b101;

    always @(posedge clk or posedge rst) begin
        if(!rst) begin
            state <= next_state;
        end else begin
            state <= IDLE;
        end
    end

    //sram input
    reg sram_wen, sram_ren;
    reg [31:0] sram_araddr, sram_awaddr, sram_wdata;
    reg [3:0] sram_wstrb;
    //sram output
    reg [31:0] sram_rdata;
    reg [1:0] sram_rresp, sram_bresp;
    reg sram_rvalid, sram_bvalid;
    //regs signal
    reg [31:0] araddr_i, araddr_o, rdata_i, rdata_o, awaddr_i, awaddr_o, wdata_i, wdata_o;
    reg [3:0] wstrb_i, wstrb_o;
    reg [1:0] rresp_i, rresp_o, bresp_i, bresp_o;
    reg araddr_wen, rdata_wen, rresp_wen, awaddr_wen, wdata_wen, wstrb_wen, bresp_wen;

    assign axi.rlast = 1;

    always @(*) begin
        axi.rvalid = 0;
        axi.bvalid = 0;
        axi.rdata = 0;
        axi.rresp = 0;
        axi.bresp = 0;

        sram_wen = 0;
        sram_ren = 0;
        sram_araddr = 0;
        sram_awaddr = 0;
        sram_wdata = 0;
        sram_wstrb = 0;

        araddr_wen = 0;
        rdata_wen = 0;
        rresp_wen = 0;
        awaddr_wen = 0;
        wdata_wen = 0;
        wstrb_wen = 0;
        bresp_wen = 0;
        araddr_i = 0;
        rdata_i = 0;
        rresp_i = 0;
        awaddr_i = 0;
        wdata_i = 0;
        wstrb_i = 0;
        bresp_i = 0;
        
        if(rst) begin
            next_state = IDLE;
        end else
        case(state)
            IDLE: begin
                //read
                if(axi.arvalid & axi.arready) begin
                    next_state = READ;
                    //begin read
                    sram_ren = 1;
                    sram_araddr = axi.araddr;
                    //save the araddr
                    araddr_i = axi.araddr;
                    araddr_wen = 1;
                end 
                //write
                else if(axi.awvalid & axi.awready) begin
                    //save the awaddr
                    awaddr_i = axi.awaddr;
                    awaddr_wen = 1;
                    if(axi.wvalid & axi.wready) begin
                        next_state = WRITE;
                        //begin sram write
                        sram_wdata = axi.wdata;
                        sram_wstrb = axi.wstrb;
                        sram_awaddr = axi.awaddr;
                        sram_wen = 1;
                        //save the wdata
                        wdata_i = axi.wdata;
                        wdata_wen = 1;
                        wstrb_i = axi.wstrb;
                        wstrb_wen = 1;
                    end else begin
                        next_state = WRITE_WAIT_DATA;
                    end
                end else if(axi.wvalid & axi.wready) begin
                    next_state = WRITE_WAIT_ADDR;
                    //save the wdata
                    wdata_i = axi.wdata;
                    wdata_wen = 1;
                    wstrb_i = axi.wstrb;
                    wstrb_wen = 1;
                end 
                //wait
                else begin
                    next_state = IDLE;
                end
            end
            READ: begin
                if(sram_rvalid) begin
                    axi.rvalid = 1;
                    if(axi.rready) begin
                        next_state = IDLE;
                        axi.rdata = sram_rdata;
                        axi.rresp = sram_rresp;
                    end else begin
                        next_state = WAIT_RREADY;
                        //save rdata
                        rdata_i = sram_rdata;
                        rdata_wen = 1;
                    end
                end else begin 
                    next_state = READ;
                    sram_araddr = araddr_o;
                    sram_ren = 1;
                end
            end
            WAIT_RREADY: begin
                axi.rvalid = 1;
                axi.rdata = rdata_o;
                if(axi.rready) next_state = IDLE;
                else next_state = WAIT_RREADY;
            end
            WRITE_WAIT_ADDR: begin
                if(axi.awvalid & axi.awready) begin
                    next_state = WRITE;
                    //begin sram write
                    sram_wdata = wdata_o;
                    sram_wstrb = wstrb_o;
                    sram_awaddr = axi.awaddr;
                    sram_wen = 1;
                    //save the waddr
                    awaddr_i = axi.awaddr;
                    awaddr_wen = 1;
                end else begin
                    next_state = WRITE_WAIT_ADDR;
                end
            end
            WRITE_WAIT_DATA: begin
                if(axi.wvalid & axi.wready) begin
                    next_state = WRITE;
                    //begin sram write
                    sram_wdata = axi.wdata;
                    sram_wstrb = axi.wstrb;
                    sram_awaddr = awaddr_o;
                    sram_wen = 1;
                    //save the wdata
                    wdata_i = axi.wdata;
                    wdata_wen = 1;
                    wstrb_i = axi.wstrb;
                    wstrb_wen = 1;
                end else begin
                    next_state = WRITE_WAIT_DATA;
                end
            end
            WRITE: begin
                if(sram_bvalid) begin
                    axi.bvalid = 1;
                    if(axi.bready) begin 
                        next_state = IDLE;
                        axi.bresp = sram_bresp;
                    end else begin
                        next_state = WAIT_BREADY;
                        //save the bresp
                        bresp_i = sram_bresp;
                        bresp_wen = 1;
                    end
                end
                else begin
                    next_state = WRITE;
                    //keep writing
                    sram_wen = 1;
                    sram_wdata = wdata_o;
                    sram_wstrb = wstrb_o;
                    sram_awaddr = awaddr_o;
                end
            end
            WAIT_BREADY: begin
                axi.bvalid = 1;
                axi.bresp = bresp_o;
                if(axi.bready) begin 
                    next_state = IDLE;
                end else begin
                    next_state = WAIT_BREADY;
                end
            end
            default: next_state = IDLE;
        endcase
    end

    ysyx_24110015_Reg #(32, 0) reg_araddr( .clk(clk), .rst(rst), .din(araddr_i), .dout(araddr_o), .wen(araddr_wen) );
    ysyx_24110015_Reg #(32, 0) reg_rdata( .clk(clk), .rst(rst), .din(rdata_i), .dout(rdata_o), .wen(rdata_wen) );
    ysyx_24110015_Reg #(2, 0) reg_rresp( .clk(clk), .rst(rst), .din(rresp_i), .dout(rresp_o), .wen(rresp_wen) );
    ysyx_24110015_Reg #(32, 0) reg_awaddr( .clk(clk), .rst(rst), .din(awaddr_i), .dout(awaddr_o), .wen(awaddr_wen) );
    ysyx_24110015_Reg #(32, 0) reg_wdata( .clk(clk), .rst(rst), .din(wdata_i), .dout(wdata_o), .wen(wdata_wen) );
    ysyx_24110015_Reg #(4, 0) reg_wstrb( .clk(clk), .rst(rst), .din(wstrb_i), .dout(wstrb_o), .wen(wstrb_wen) );
    ysyx_24110015_Reg #(2, 0) reg_bresp( .clk(clk), .rst(rst), .din(bresp_i), .dout(bresp_o), .wen(bresp_wen) );

    ysyx_24110015_SRAM #(32, 32) sram(   
        .clk(clk),
        .rst(rst),
        //read
        .araddr(sram_araddr),
        .ren(sram_ren),
        .rdata(sram_rdata),
        .rresp(sram_rresp),
        .rvalid(sram_rvalid),
        //write
        .awaddr(sram_awaddr),
        .wdata(sram_wdata),
        .wen(sram_wen),
        .wstrb(sram_wstrb),
        .bresp(sram_bresp),
        .bvalid(sram_bvalid)
    );

    assign axi.arready = (state == IDLE);
    assign axi.awready = (state == IDLE) | (state == WRITE_WAIT_ADDR);
    assign axi.wready = (state == IDLE) | (state == WRITE_WAIT_DATA);

endmodule
`endif