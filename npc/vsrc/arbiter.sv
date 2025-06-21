module ysyx_24110015_AXIArbiter (
    input clk,
    input rst,
    axi_if.slave axi_master_ifu,
    axi_if.slave axi_master_lsu,
    axi_if.master axi_slave
);
    logic [1:0] state, next_state;
    parameter IDLE = 2'b00, IFU = 2'b01, LSU = 2'b10;

    always @(posedge clk or posedge rst) begin
        if(!rst) begin
            state <= next_state;
        end else begin
            state <= IDLE;
        end
    end

    always @(*) begin
        axi_master_ifu.arready = 0;
        axi_master_ifu.rdata = 0;
        axi_master_ifu.rresp = 0;
        axi_master_ifu.rvalid = 0;
        axi_master_ifu.awready = 0;
        axi_master_ifu.wready = 0;
        axi_master_ifu.bresp = 0;
        axi_master_ifu.bvalid = 0;

        axi_master_lsu.arready = 0;
        axi_master_lsu.rdata = 0;
        axi_master_lsu.rresp = 0;
        axi_master_lsu.rvalid = 0;
        axi_master_lsu.awready = 0;
        axi_master_lsu.wready = 0;
        axi_master_lsu.bresp = 0;
        axi_master_lsu.bvalid = 0;

        axi_slave.araddr = 0;
        axi_slave.arid = 0;
        axi_slave.arlen = 0;
        axi_slave.arsize = 0;
        axi_slave.arburst = 0;
        axi_slave.arvalid = 0;
        axi_slave.rready = 0;
        axi_slave.awaddr = 0;
        axi_slave.awid = 0;
        axi_slave.awlen = 0;
        axi_slave.awsize = 0;
        axi_slave.awburst = 0;
        axi_slave.awvalid = 0;
        axi_slave.wdata = 0;
        axi_slave.wstrb = 0;
        axi_slave.wlast = 0;
        axi_slave.wvalid = 0;
        axi_slave.bready = 0;

        case(state)
            IDLE: begin
                if(axi_master_lsu.arvalid | axi_master_lsu.awvalid) begin
                    next_state = LSU;
                    // AR channel
                    axi_slave.araddr = axi_master_lsu.araddr;
                    axi_slave.arid = axi_master_lsu.arid;
                    axi_slave.arlen = axi_master_lsu.arlen;
                    axi_slave.arsize = axi_master_lsu.arsize;
                    axi_slave.arburst = axi_master_lsu.arburst;
                    axi_slave.arvalid = axi_master_lsu.arvalid;
                    axi_master_lsu.arready = axi_slave.arready;
                    // R channel
                    axi_master_lsu.rdata = axi_slave.rdata;
                    axi_master_lsu.rresp = axi_slave.rresp;
                    axi_master_lsu.rlast = axi_slave.rlast;
                    axi_master_lsu.rid = axi_slave.rid;
                    axi_master_lsu.rvalid = axi_slave.rvalid;
                    axi_slave.rready = axi_master_lsu.rready;
                    // AW channel
                    axi_slave.awaddr = axi_master_lsu.awaddr;
                    axi_slave.awid = axi_master_lsu.awid;
                    axi_slave.awlen = axi_master_lsu.awlen;
                    axi_slave.awsize = axi_master_lsu.awsize;
                    axi_slave.awburst = axi_master_lsu.awburst;
                    axi_slave.awvalid = axi_master_lsu.awvalid;
                    axi_master_lsu.awready = axi_slave.awready;
                    // W channel
                    axi_slave.wdata = axi_master_lsu.wdata;
                    axi_slave.wstrb = axi_master_lsu.wstrb;
                    axi_slave.wlast = axi_master_lsu.wlast;
                    axi_slave.wvalid = axi_master_lsu.wvalid;
                    axi_master_lsu.wready = axi_slave.wready;
                    // B channel
                    axi_master_lsu.bresp = axi_slave.bresp;
                    axi_master_lsu.bid = axi_slave.bid;
                    axi_master_lsu.bvalid = axi_slave.bvalid;
                    axi_slave.bready = axi_master_lsu.bready;
                end else if(axi_master_ifu.arvalid) begin
                    next_state = IFU;
                    // AR channel
                    axi_slave.araddr = axi_master_ifu.araddr;
                    axi_slave.arid = axi_master_ifu.arid;
                    axi_slave.arlen = axi_master_ifu.arlen;
                    axi_slave.arsize = axi_master_ifu.arsize;
                    axi_slave.arburst = axi_master_ifu.arburst;
                    axi_slave.arvalid = axi_master_ifu.arvalid;
                    axi_master_ifu.arready = axi_slave.arready;
                    // R channel
                    axi_master_ifu.rdata = axi_slave.rdata;
                    axi_master_ifu.rresp = axi_slave.rresp;
                    axi_master_ifu.rlast = axi_slave.rlast;
                    axi_master_ifu.rid = axi_slave.rid;
                    axi_master_ifu.rvalid = axi_slave.rvalid;
                    axi_slave.rready = axi_master_ifu.rready;
                end else begin
                    next_state = IDLE;
                end
            end
            IFU: begin
                // AR channel
                axi_slave.araddr = axi_master_ifu.araddr;
                axi_slave.arid = axi_master_ifu.arid;
                axi_slave.arlen = axi_master_ifu.arlen;
                axi_slave.arsize = axi_master_ifu.arsize;
                axi_slave.arburst = axi_master_ifu.arburst;
                axi_slave.arvalid = axi_master_ifu.arvalid;
                axi_master_ifu.arready = axi_slave.arready;
                // R channel
                axi_master_ifu.rdata = axi_slave.rdata;
                axi_master_ifu.rresp = axi_slave.rresp;
                axi_master_ifu.rlast = axi_slave.rlast;
                axi_master_ifu.rid = axi_slave.rid;
                axi_master_ifu.rvalid = axi_slave.rvalid;
                axi_slave.rready = axi_master_ifu.rready;
                if(axi_slave.rvalid & axi_slave.rlast & axi_master_ifu.rready) begin
                    next_state = IDLE;
                end else begin
                    next_state = IFU;
                end
            end
            LSU: begin
                // AR channel
                axi_slave.araddr = axi_master_lsu.araddr;
                axi_slave.arid = axi_master_lsu.arid;
                axi_slave.arlen = axi_master_lsu.arlen;
                axi_slave.arsize = axi_master_lsu.arsize;
                axi_slave.arburst = axi_master_lsu.arburst;
                axi_slave.arvalid = axi_master_lsu.arvalid;
                axi_master_lsu.arready = axi_slave.arready;
                // R channel
                axi_master_lsu.rdata = axi_slave.rdata;
                axi_master_lsu.rresp = axi_slave.rresp;
                axi_master_lsu.rlast = axi_slave.rlast;
                axi_master_lsu.rid = axi_slave.rid;
                axi_master_lsu.rvalid = axi_slave.rvalid;
                axi_slave.rready = axi_master_lsu.rready;
                // AW channel
                axi_slave.awaddr = axi_master_lsu.awaddr;
                axi_slave.awid = axi_master_lsu.awid;
                axi_slave.awlen = axi_master_lsu.awlen;
                axi_slave.awsize = axi_master_lsu.awsize;
                axi_slave.awburst = axi_master_lsu.awburst;
                axi_slave.awvalid = axi_master_lsu.awvalid;
                axi_master_lsu.awready = axi_slave.awready;
                // W channel
                axi_slave.wdata = axi_master_lsu.wdata;
                axi_slave.wstrb = axi_master_lsu.wstrb;
                axi_slave.wlast = axi_master_lsu.wlast;
                axi_slave.wvalid = axi_master_lsu.wvalid;
                axi_master_lsu.wready = axi_slave.wready;
                // B channel
                axi_master_lsu.bresp = axi_slave.bresp;
                axi_master_lsu.bid = axi_slave.bid;
                axi_master_lsu.bvalid = axi_slave.bvalid;
                axi_slave.bready = axi_master_lsu.bready;
                if((axi_slave.rvalid & axi_slave.rlast & axi_master_lsu.rready)|(axi_slave.bvalid & axi_master_lsu.bready)) begin
                    next_state = IDLE;
                end else begin
                    next_state = LSU;
                end
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end


endmodule