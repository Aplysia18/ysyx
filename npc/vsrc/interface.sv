interface axi_lite_if(
    // input logic clk,
    // input logic rst
);
    // AR channel
    logic [31:0] araddr;
    logic arvalid;
    logic arready;
    // R channel
    logic [31:0] rdata;
    logic [1:0] rresp;
    logic rvalid;
    logic rready; 
    // AW channel
    logic [31:0] awaddr;
    logic awvalid;
    logic awready;
    // W channel
    logic [31:0] wdata;
    logic [3:0] wstrb;
    logic wvalid;
    logic wready;
    // B channel
    logic [1:0] bresp;
    logic bvalid;
    logic bready;

    modport master(
        output araddr, arvalid, rready, awaddr, awvalid, wdata, wstrb, wvalid, bready, 
        input arready, rdata, rresp, rvalid, awready, wready, bresp, bvalid
    );

    modport slave(
        input araddr, arvalid, rready, awaddr, awvalid, wdata, wstrb, wvalid, bready, 
        output arready, rdata, rresp, rvalid, awready, wready, bresp, bvalid
    );
    
endinterface