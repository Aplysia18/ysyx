interface axi_lite_if(
    // input logic clk,
    // input logic rst
);
    // AR channel
    logic [31:0] araddr;
    logic [3:0] arid;   //AXI
    logic [7:0] arlen;  //AXI
    logic [2:0] arsize; //AXI
    logic [1:0] arburst;      //AXI
    logic arvalid;
    logic arready;
    // R channel
    logic [31:0] rdata;
    logic [1:0] rresp;
    logic rlast;        //AXI
    logic [3:0] rid;   //AXI
    logic rvalid;
    logic rready; 
    // AW channel
    logic [31:0] awaddr;
    logic [3:0] awid;   //AXI
    logic [7:0] awlen;  //AXI
    logic [2:0] awsize; //AXI
    logic [1:0] awburst;      //AXI
    logic awvalid;
    logic awready;
    // W channel
    logic [31:0] wdata;
    logic [3:0] wstrb;
    logic wlast;    //AXI
    logic wvalid;
    logic wready;
    // B channel
    logic [1:0] bresp;
    logic [3:0] bid;   //AXI
    logic bvalid;
    logic bready;

    modport master(
        output araddr, arid, arlen, arsize, arburst, arvalid, rready, awaddr, awid, awlen, awsize, awburst, awvalid, wdata, wstrb, wlast, wvalid, bready, 
        input arready, rdata, rresp, rlast, rid, rvalid, awready, wready, bresp, bid, bvalid
    );

    modport slave(
        input araddr, arid, arlen, arsize, arburst, arvalid, rready, awaddr, awid, awlen, awsize, awburst, awvalid, wdata, wstrb, wlast, wvalid, bready, 
        output arready, rdata, rresp, rlast, rid, rvalid, awready, wready, bresp, bid, bvalid
    );
    
endinterface