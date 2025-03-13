module ysyx_24110015_LSU (
    input clk,
    input rst,
    //from exu
    input [31:0] alu_out_i,
    input [31:0] pc_next_i,
    input RegWrite_i,
    input [4:0] wb_addr_i,
    input [3:0] mem_wmask,
    input zicsr_i,
    input [31:0] csr_rdata_i,
    input [31:0] din_mstatus_i,
    input [31:0] din_mtvec_i,
    input [31:0] din_mepc_i,
    input [31:0] din_mcause_i,
    input wen_mstatus_i,
    input wen_mtvec_i,
    input wen_mepc_i,
    input wen_mcause_i,
    input [2:0] func3_i,
    input MemWrite,
    input MemRead_i,
    input [31:0] mem_wdata,
    //from controller
    input control_dMemRW,
    //to wbu
    output [31:0] alu_out_o,
    output [31:0] pc_next_o,
    output RegWrite_o,
    output [4:0] wb_addr_o,
    output zicsr_o,
    output [31:0] csr_rdata_o,
    output [31:0] din_mstatus_o,
    output [31:0] din_mtvec_o,
    output [31:0] din_mepc_o,
    output [31:0] din_mcause_o,
    output wen_mstatus_o,
    output wen_mtvec_o,
    output wen_mepc_o,
    output wen_mcause_o,
    output [2:0] func3_o,
    output MemRead_o,
    output [31:0] mem_rdata,
    //to controller
    output control_dmemR_end,
    output control_dmemW_end
);

    assign alu_out_o = alu_out_i;
    assign pc_next_o = pc_next_i;
    assign RegWrite_o = RegWrite_i;
    assign wb_addr_o = wb_addr_i;
    assign csr_rdata_o = csr_rdata_i;
    assign zicsr_o = zicsr_i;
    assign din_mstatus_o = din_mstatus_i;
    assign din_mtvec_o = din_mtvec_i;
    assign din_mepc_o = din_mepc_i;
    assign din_mcause_o = din_mcause_i;
    assign wen_mstatus_o = wen_mstatus_i;
    assign wen_mtvec_o = wen_mtvec_i;
    assign wen_mepc_o = wen_mepc_i;
    assign wen_mcause_o = wen_mcause_i;
    assign func3_o = func3_i;
    assign MemRead_o = MemRead_i;

    wire arvalid, arready, rvalid, rready, awvalid, awready, wvalid, wready, bvalid, bready;
    wire [1:0] rresp, bresp;

    assign arvalid = MemRead_o & control_dMemRW;
    assign rready = MemRead_o & control_dMemRW;
    assign awvalid = MemWrite & control_dMemRW;
    assign wvalid = MemWrite & control_dMemRW;
    assign bready = MemWrite & control_dMemRW;

    assign control_dmemR_end = rvalid & rready;
    assign control_dmemW_end = bvalid & bready;

    ysyx_24110015_AXI2MEM LSU_AXI2MEM(
        .clk(clk),
        .rst(rst),
        // AR channel
        .araddr(alu_out_i),
        .arvalid(arvalid),
        .arready(arready),
        // R channel
        .rdata(mem_rdata),
        .rresp(rresp),
        .rvalid(rvalid),
        .rready(rready), 
        // AW channel
        .awaddr(alu_out_i),
        .awvalid(awvalid),
        .awready(),
        // W channel
        .wdata(mem_wdata),
        .wstrb(mem_wmask),
        .wvalid(wvalid),
        .wready(),
        // B channel
        .bresp(bresp),
        .bvalid(bvalid),
        .bready(bready)
    );

endmodule