module ysyx_24110015_xbar (
    input clk,
    input rst,
    axi_lite_if.slave axi_master,
    axi_lite_if.master axi_slave_clint
);

    typedef enum logic [2:0] {IDLE, ADDR_DECODE, XFER_RD, XFER_WR, RESP_RD, RESP_WR} xbar_state_t;
    xbar_state_t state, next_state;
    logic cur_slave;

    parameter [31:0] CLINT_BASE = 32'ha0000048;

    // axi_lite_if axi_slave;

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
                if(cur_slave) begin
                    if(axi_slave_clint.rvalid & axi_master.rready) begin
                        next_state = RESP_RD;
                    end else next_state = XFER_RD;
                end else next_state = IDLE;
            end
            XFER_WR: begin
                if(cur_slave) begin
                    if(axi_slave_clint.bvalid & axi_master.bready) begin
                        next_state = RESP_WR;
                    end else next_state = XFER_WR;
                end else next_state = IDLE;
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
            case(axi_master.arvalid? axi_master.araddr : axi_master.awaddr)
                CLINT_BASE: cur_slave <= 1; //CLINT
                CLINT_BASE+4: cur_slave <= 1;   //CLINT
                default: cur_slave <= 0;
            endcase
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
                    1: begin
                        axi_slave_clint.arvalid = axi_master.arvalid;
                        axi_master.arready = axi_slave_clint.arready;

                        axi_slave_clint.awvalid = axi_master.awvalid;
                        axi_master.awready = axi_slave_clint.awready;

                        axi_slave_clint.wvalid = axi_master.wvalid;
                        axi_master.wready = axi_slave_clint.wready;
                    end
                    default: begin
                        axi_slave_clint.arvalid = 0;
                        axi_master.arready = 0;

                        axi_slave_clint.awvalid = 0;
                        axi_master.awready = 0;
                        
                        axi_slave_clint.wvalid = 0;
                        axi_master.wready = 0;
                    end
                endcase
            end
            XFER_RD: begin
                case(cur_slave)
                    1: begin
                        axi_slave_clint.rready = axi_master.rready;
                        axi_master.rvalid = axi_slave_clint.rvalid;
                        axi_master.rdata = axi_slave_clint.rdata;
                        axi_master.rresp = axi_slave_clint.rresp;
                    end
                    default: begin
                        axi_slave_clint.rready = 0;
                        axi_master.rvalid = 0;
                        axi_master.rdata = 0;
                        axi_master.rresp = 0;
                    end
                endcase
            end
            XFER_WR: begin
                case(cur_slave)
                    1: begin
                        axi_slave_clint.bready = axi_master.bready;
                        axi_master.bvalid = axi_slave_clint.bvalid;
                        axi_master.bresp = axi_slave_clint.bresp;
                    end
                    default: begin
                        axi_slave_clint.bready = 0;
                        axi_master.bvalid = 0;
                        axi_master.bresp = 0;
                    end
                endcase
            end
            RESP_RD: begin
                axi_master.rvalid = 0;
                axi_slave_clint.rready = 0;
            end
            RESP_WR: begin
                axi_master.bvalid = 0;
                axi_slave_clint.bready = 0;
            end
            default: begin
                axi_slave_clint.arvalid = 0;
                axi_slave_clint.awvalid = 0;
                axi_slave_clint.wvalid = 0;
                axi_slave_clint.rready = 0;
                axi_slave_clint.bready = 0;

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
        axi_slave_clint.awaddr = axi_master.awaddr;
        axi_slave_clint.wdata = axi_master.wdata;
        axi_slave_clint.wstrb = axi_master.wstrb;
    end

endmodule