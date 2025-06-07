module ysyx_24110015_xbar (
    input clk,
    input rst,
    axi_if.slave axi_master,
    axi_if.master axi_slave_clint,
    axi_if.master axi_slave_soc
);

    // typedef enum logic [2:0] {IDLE, ADDR_DECODE, XFER_RD, XFER_WR, RESP_RD, RESP_WR} xbar_state_t;
    localparam IDLE = 3'b000, ADDR_DECODE = 3'b001, XFER_RD = 3'b010, XFER_WR = 3'b011, RESP_RD = 3'b100, RESP_WR = 3'b101;
    logic [2:0] state, next_state;
    // xbar_state_t state, next_state;
    logic [1:0] cur_slave; //01:clint 10:soc

    parameter [31:0] CLINT_BASE = 32'h02000000;
    parameter [31:0] CLINT_SIZE = 32'h0000FFFF;

    // axi_if axi_slave;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case(state)
            IDLE: begin
                if(axi_master.arvalid | axi_master.awvalid) begin
                    next_state = ADDR_DECODE;
                end else next_state = IDLE;
            end
            ADDR_DECODE: begin
                next_state = axi_master.arvalid? XFER_RD : XFER_WR;
            end
            XFER_RD: begin
                case(cur_slave)
                    2'b01: begin
                        if(axi_slave_clint.rvalid & axi_master.rready) begin
                            next_state = RESP_RD;
                        end else next_state = XFER_RD;
                    end
                    2'b10: begin
                        if(axi_slave_soc.rvalid & axi_master.rready) begin
                            next_state = RESP_RD;
                        end else next_state = XFER_RD;
                    end
                    default: begin
                        next_state = IDLE;
                    end
                endcase
            end
            XFER_WR: begin
                case(cur_slave)
                    2'b01: begin
                        if(axi_slave_clint.bvalid & axi_master.bready) begin
                            next_state = RESP_WR;
                        end else next_state = XFER_WR;
                    end
                    2'b10: begin
                        if(axi_slave_soc.bvalid & axi_master.bready) begin
                            next_state = RESP_WR;
                        end else next_state = XFER_WR;
                    end
                    default: begin
                        next_state = IDLE;
                    end
                endcase
            end
            RESP_RD, RESP_WR: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // addr decode
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            cur_slave <= 0;
        end
        else if(next_state == ADDR_DECODE) begin
            if((axi_master.arvalid? axi_master.araddr : axi_master.awaddr) >= CLINT_BASE &&
               (axi_master.arvalid? axi_master.araddr : axi_master.awaddr) < (CLINT_BASE + CLINT_SIZE)) begin
                cur_slave <= 2'b01; //CLINT
            end else cur_slave <= 2'b10; //SOC
        end else begin
            cur_slave <= cur_slave;
        end
    end

    // ready/valid 
    always @(*) begin

        axi_slave_clint.arvalid = 0;
        axi_slave_clint.awvalid = 0;
        axi_slave_clint.wvalid = 0;
        axi_slave_clint.rready = 0;
        axi_slave_clint.bready = 0;

        axi_slave_soc.arvalid = 0;
        axi_slave_soc.awvalid = 0;
        axi_slave_soc.wvalid = 0;
        axi_slave_soc.rready = 0;
        axi_slave_soc.bready = 0;

        axi_master.arready = 0;
        axi_master.awready = 0;
        axi_master.wready = 0;
        axi_master.rvalid = 0;
        axi_master.bvalid = 0;

        axi_master.rdata = 0;
        axi_master.rresp = 0;
        axi_master.bresp = 0;

        case(state)
            ADDR_DECODE: begin
                case (cur_slave)
                    2'b01: begin
                        axi_slave_clint.arvalid = axi_master.arvalid;
                        axi_master.arready = axi_slave_clint.arready;

                        axi_slave_clint.awvalid = axi_master.awvalid;
                        axi_master.awready = axi_slave_clint.awready;

                        axi_slave_clint.wvalid = axi_master.wvalid;
                        axi_master.wready = axi_slave_clint.wready;
                    end
                    2'b10: begin
                        axi_slave_soc.arvalid = axi_master.arvalid;
                        axi_master.arready = axi_slave_soc.arready;

                        axi_slave_soc.awvalid = axi_master.awvalid;
                        axi_master.awready = axi_slave_soc.awready;

                        axi_slave_soc.wvalid = axi_master.wvalid;
                        axi_master.wready = axi_slave_soc.wready;
                    end
                    default: begin
                        axi_slave_clint.arvalid = 0;
                        axi_slave_soc.arvalid = 0;
                        axi_master.arready = 0;

                        axi_slave_clint.awvalid = 0;
                        axi_slave_soc.awvalid = 0;
                        axi_master.awready = 0;
                        
                        axi_slave_clint.wvalid = 0;
                        axi_slave_soc.wvalid = 0;
                        axi_master.wready = 0;
                    end
                endcase
            end
            XFER_RD: begin
                case(cur_slave)
                    2'b01: begin
                        axi_slave_clint.arvalid = axi_master.arvalid;
                        axi_master.arready = axi_slave_clint.arready;

                        axi_slave_clint.awvalid = axi_master.awvalid;
                        axi_master.awready = axi_slave_clint.awready;

                        axi_slave_clint.wvalid = axi_master.wvalid;
                        axi_master.wready = axi_slave_clint.wready;

                        axi_slave_clint.rready = axi_master.rready;
                        axi_master.rvalid = axi_slave_clint.rvalid;
                        axi_master.rdata = axi_slave_clint.rdata;
                        axi_master.rresp = axi_slave_clint.rresp;
                    end
                    2'b10: begin
                        axi_slave_soc.arvalid = axi_master.arvalid;
                        axi_master.arready = axi_slave_soc.arready;

                        axi_slave_soc.awvalid = axi_master.awvalid;
                        axi_master.awready = axi_slave_soc.awready;

                        axi_slave_soc.wvalid = axi_master.wvalid;
                        axi_master.wready = axi_slave_soc.wready;

                        axi_slave_soc.rready = axi_master.rready;
                        axi_master.rvalid = axi_slave_soc.rvalid;
                        axi_master.rdata = axi_slave_soc.rdata;
                        axi_master.rresp = axi_slave_soc.rresp;
                    end
                    default: begin
                        axi_slave_clint.rready = 0;
                        axi_slave_soc.rready = 0;
                        axi_master.rvalid = 0;
                        axi_master.rdata = 0;
                        axi_master.rresp = 0;
                    end
                endcase
            end
            XFER_WR: begin
                case(cur_slave)
                    2'b01: begin
                        axi_slave_clint.arvalid = axi_master.arvalid;
                        axi_master.arready = axi_slave_clint.arready;

                        axi_slave_clint.awvalid = axi_master.awvalid;
                        axi_master.awready = axi_slave_clint.awready;

                        axi_slave_clint.wvalid = axi_master.wvalid;
                        axi_master.wready = axi_slave_clint.wready;

                        axi_slave_clint.bready = axi_master.bready;
                        axi_master.bvalid = axi_slave_clint.bvalid;
                        axi_master.bresp = axi_slave_clint.bresp;
                    end
                    2'b10: begin
                        axi_slave_soc.arvalid = axi_master.arvalid;
                        axi_master.arready = axi_slave_soc.arready;

                        axi_slave_soc.awvalid = axi_master.awvalid;
                        axi_master.awready = axi_slave_soc.awready;

                        axi_slave_soc.wvalid = axi_master.wvalid;
                        axi_master.wready = axi_slave_soc.wready;

                        axi_slave_soc.bready = axi_master.bready;
                        axi_master.bvalid = axi_slave_soc.bvalid;
                        axi_master.bresp = axi_slave_soc.bresp;
                    end
                    default: begin
                        axi_slave_clint.bready = 0;
                        axi_slave_soc.bready = 0;
                        axi_master.bvalid = 0;
                        axi_master.bresp = 0;
                    end
                endcase
            end
            RESP_RD: begin
                axi_master.rvalid = 0;
                axi_slave_clint.rready = 0;
                axi_slave_soc.rready = 0;
            end
            RESP_WR: begin
                axi_master.bvalid = 0;
                axi_slave_clint.bready = 0;
                axi_slave_soc.bready = 0;
            end
            default: begin
                axi_slave_clint.arvalid = 0;
                axi_slave_clint.awvalid = 0;
                axi_slave_clint.wvalid = 0;
                axi_slave_clint.rready = 0;
                axi_slave_clint.bready = 0;
                
                axi_slave_soc.arvalid = 0;
                axi_slave_soc.awvalid = 0;
                axi_slave_soc.wvalid = 0;
                axi_slave_soc.rready = 0;
                axi_slave_soc.bready = 0;

                axi_master.arready = 0;
                axi_master.awready = 0;
                axi_master.wready = 0;
                axi_master.rvalid = 0;
                axi_master.bvalid = 0;

                axi_master.rdata = 0;
                axi_master.rresp = 0;
                axi_master.bresp = 0;
            end
        endcase
    end

    // addr/data broadcast
    always @(*) begin
        axi_slave_clint.araddr = axi_master.araddr;
        axi_slave_clint.arid = axi_master.arid;
        axi_slave_clint.arlen = axi_master.arlen;
        axi_slave_clint.arsize = axi_master.arsize;
        axi_slave_clint.arburst = axi_master.arburst;
        axi_slave_clint.awaddr = axi_master.awaddr;
        axi_slave_clint.awid = axi_master.awid;
        axi_slave_clint.awlen = axi_master.awlen;
        axi_slave_clint.awsize = axi_master.awsize;
        axi_slave_clint.awburst = axi_master.awburst;
        axi_slave_clint.wdata = axi_master.wdata;
        axi_slave_clint.wstrb = axi_master.wstrb;
        axi_slave_clint.wlast = axi_master.wlast;

        axi_slave_soc.araddr = axi_master.araddr;
        axi_slave_soc.arid = axi_master.arid;
        axi_slave_soc.arlen = axi_master.arlen;
        axi_slave_soc.arsize = axi_master.arsize;
        axi_slave_soc.arburst = axi_master.arburst;
        axi_slave_soc.awaddr = axi_master.awaddr;
        axi_slave_soc.awid = axi_master.awid;
        axi_slave_soc.awlen = axi_master.awlen;
        axi_slave_soc.awsize = axi_master.awsize;
        axi_slave_soc.awburst = axi_master.awburst;
        axi_slave_soc.wdata = axi_master.wdata;
        axi_slave_soc.wstrb = axi_master.wstrb;
        axi_slave_soc.wlast = axi_master.wlast;
    end

endmodule