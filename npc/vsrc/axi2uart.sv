// import "DPI-C" function void pmem_write(input int waddr, input int wdata, input byte wmask);
module ysyx_24110015_AXI2Uart (
    input clk,
    input rst,
    axi_lite_if.slave axi
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

    //regs signal
    reg [31:0] araddr_i, araddr_o, rdata_i, rdata_o, awaddr_i, awaddr_o, wdata_i, wdata_o;
    reg [3:0] wstrb_i, wstrb_o;
    reg [1:0] rresp_i, rresp_o, bresp_i, bresp_o;
    reg araddr_wen, rdata_wen, rresp_wen, awaddr_wen, wdata_wen, wstrb_wen, bresp_wen;

    always @(*) begin
        axi.rvalid = 0;
        axi.bvalid = 0;
        axi.rdata = 0;
        axi.rresp = 0;
        axi.bresp = 0;

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
                //write
                if(axi.awvalid & axi.awready) begin
                    //save the awaddr
                    awaddr_i = axi.awaddr;
                    awaddr_wen = 1;
                    if(axi.wvalid & axi.wready) begin
                        next_state = WRITE;
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
            WAIT_RREADY: begin
                axi.rvalid = 1;
                axi.rdata = rdata_o;
                if(axi.rready) next_state = IDLE;
                else next_state = WAIT_RREADY;
            end
            WRITE_WAIT_ADDR: begin
                if(axi.awvalid & axi.awready) begin
                    next_state = WRITE;
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
                    next_state = IDLE;
                    axi.bvalid = 1;
                    axi.bresp = 0;
            end
            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk) begin
        if(state==WRITE) begin
            $write("%c", wdata_o[7:0]);
            pmem_write(awaddr_o, wdata_o, {4'b0, wstrb_o});
        end

    end

    ysyx_24110015_Reg #(32, 0) reg_araddr( .clk(clk), .rst(rst), .din(araddr_i), .dout(araddr_o), .wen(araddr_wen) );
    ysyx_24110015_Reg #(32, 0) reg_rdata( .clk(clk), .rst(rst), .din(rdata_i), .dout(rdata_o), .wen(rdata_wen) );
    ysyx_24110015_Reg #(2, 0) reg_rresp( .clk(clk), .rst(rst), .din(rresp_i), .dout(rresp_o), .wen(rresp_wen) );
    ysyx_24110015_Reg #(32, 0) reg_awaddr( .clk(clk), .rst(rst), .din(awaddr_i), .dout(awaddr_o), .wen(awaddr_wen) );
    ysyx_24110015_Reg #(32, 0) reg_wdata( .clk(clk), .rst(rst), .din(wdata_i), .dout(wdata_o), .wen(wdata_wen) );
    ysyx_24110015_Reg #(4, 0) reg_wstrb( .clk(clk), .rst(rst), .din(wstrb_i), .dout(wstrb_o), .wen(wstrb_wen) );
    ysyx_24110015_Reg #(2, 0) reg_bresp( .clk(clk), .rst(rst), .din(bresp_i), .dout(bresp_o), .wen(bresp_wen) );

    assign axi.arready = 0;
    assign axi.awready = (state == IDLE) | (state == WRITE_WAIT_ADDR);
    assign axi.wready = (state == IDLE) | (state == WRITE_WAIT_DATA);

endmodule