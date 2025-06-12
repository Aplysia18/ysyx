// import "DPI-C" function int pmem_read(input int addr);

module ysyx_24110015_AXI2Clint (
    input clk,
    input rst,
    axi_if.slave axi
);

`ifdef ysyxsoc
    localparam clint_addrl=32'h02000000;
    localparam clint_addrh=32'h02000004;
`else
    localparam clint_addrl=32'ha0000048;
    localparam clint_addrh=32'ha000004c;
`endif

    logic [2:0] state, next_state;
    parameter IDLE = 3'b000, READ = 3'b001, WAIT_RREADY = 3'b011, WRITE_WAIT_DATA = 3'b010, WRITE_WAIT_ADDR = 3'b110, WRITE = 3'b100, WAIT_BREADY = 3'b101;

    always @(posedge clk or posedge rst) begin
        if(!rst) begin
            state <= next_state;
        end else begin
            state <= IDLE;
        end
    end

    //regs signal
    logic [31:0] araddr_i, araddr_o, rdata_i, rdata_o, awaddr_i, awaddr_o, wdata_i, wdata_o;
    logic [3:0] wstrb_i, wstrb_o;
    logic [1:0] rresp_i, rresp_o, bresp_i, bresp_o;
    logic araddr_wen, rdata_wen, rresp_wen, awaddr_wen, wdata_wen, wstrb_wen, bresp_wen;
    logic [63:0] mtime;

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
                //read
                if(axi.arvalid & axi.arready) begin
                    next_state = READ;
                    //save the araddr
                    araddr_i = axi.araddr;
                    araddr_wen = 1;
                end 
                //wait
                else begin
                    next_state = IDLE;
                end
            end
            READ: begin
                axi.rvalid = 1;
                if(axi.rready) begin
                    next_state = IDLE;
                    if(araddr_o == clint_addrl) begin 
                        axi.rdata = mtime[31:0];
`ifndef __SYNTHESIS__
                        /* verilator lint_off IGNOREDRETURN */
                        pmem_read(clint_addrl);
                        /* verilator lint_on IGNOREDRETURN */
`endif
                    end
                    else if(araddr_o == clint_addrh) begin 
                        axi.rdata = mtime[63:32];
`ifndef __SYNTHESIS__
                        /* verilator lint_off IGNOREDRETURN */
                        pmem_read(clint_addrh);
                        /* verilator lint_on IGNOREDRETURN */
`endif
                    end
                    else axi.rdata = 0;
                    axi.rresp = 0;
                end else begin
                    next_state = WAIT_RREADY;
                    //save rdata
                    if(araddr_o == clint_addrl) begin
                        rdata_i = mtime[31:0];
`ifndef __SYNTHESIS__
                        /* verilator lint_off IGNOREDRETURN */
                        pmem_read(clint_addrl);
                        /* verilator lint_on IGNOREDRETURN */
`endif
                    end
                    else if(araddr_o == clint_addrh) begin
                        rdata_i = mtime[63:32];
`ifndef __SYNTHESIS__
                        $sformat("rdata_i = %h", rdata_i);
                        /* verilator lint_off IGNOREDRETURN */
                        pmem_read(clint_addrh);
                        /* verilator lint_on IGNOREDRETURN */
`endif
                    end
                    else rdata_i = 0;
                    rdata_wen = 1;
                end
            end
            WAIT_RREADY: begin
                axi.rvalid = 1;
                axi.rdata = rdata_o;
                if(axi.rready) next_state = IDLE;
                else next_state = WAIT_RREADY;
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

    ysyx_24110015_Reg #(64, 0) reg_mtime( .clk(clk), .rst(rst), .din(mtime+1), .dout(mtime), .wen(1));

    assign axi.arready = (state == IDLE);
    assign axi.awready = 0;
    assign axi.wready = 0;
    assign axi.rlast = 1;

endmodule