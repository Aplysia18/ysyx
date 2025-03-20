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
    output control_dmemW_end,
    //to axi
    axi_lite_if.master axiif
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

    // wire arready, rvalid, awready, wready, bvalid;
    // wire arvalid, rready, awvalid, wvalid, bready;
    // wire [1:0] rresp, bresp;

    // assign axiif.arvalid = MemRead_o & control_dMemRW;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            axiif.arvalid <= 0;
        end else begin
            if(axiif.arvalid) begin 
                if(axiif.arready) begin
                    axiif.arvalid <= 0;
                end
            end else if(MemRead_o & control_dMemRW) begin
                axiif.arvalid <= 1;
            end else begin
                axiif.arvalid <= axiif.arvalid;
            end
        end
    end

    // assign axiif.rready = MemRead_o & control_dMemRW;
    assign axiif.rready = 1;
    // assign axiif.awvalid = MemWrite & control_dMemRW;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            axiif.awvalid <= 0;
        end else begin
            if(axiif.awvalid) begin 
                if(axiif.awready) begin
                    axiif.awvalid <= 0;
                end
            end else if(MemWrite & control_dMemRW) begin
                axiif.awvalid <= 1;
            end else begin
                axiif.awvalid <= axiif.awvalid;
            end
        end
    end
    // assign axiif.wvalid = MemWrite & control_dMemRW;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            axiif.wvalid <= 0;
        end else begin
            if(axiif.wvalid) begin 
                if(axiif.wready) begin
                    axiif.wvalid <= 0;
                end
            end else if(MemWrite & control_dMemRW) begin
                axiif.wvalid <= 1;
            end else begin
                axiif.wvalid <= 0;
            end
        end
    end
    // assign axiif.bready = MemWrite & control_dMemRW;
    assign axiif.bready = 1;
    assign axiif.araddr = alu_out_i;
    assign mem_rdata = axiif.rdata;
    assign axiif.awaddr = alu_out_i;
    assign axiif.wdata = mem_wdata;
    assign axiif.wstrb = mem_wmask;

    assign control_dmemR_end = axiif.rvalid & axiif.rready;
    assign control_dmemW_end = axiif.bvalid & axiif.bready;


endmodule