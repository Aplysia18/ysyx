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
    output logic [31:0] mem_rdata,
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
    // assign axiif.arsize = ((func3_i&3'b011)==3'b000) ? 3'b000 : ((func3_i&3'b011)==3'b001) ? 3'b001 : 3'b010;
    assign axiif.arsize = 3'b010; // 32 bit

    // assign axiif.rready = MemRead_o & control_dMemRW;
    assign axiif.rready = 1;


    // assign axiif.awvalid = MemWrite & control_dMemRW;
    // assign axiif.awsize = (mem_wmask == 4'b1111) ? 3'b010 : (mem_wmask == 4'b0011) ? 3'b001 : 3'b000;
    assign axiif.awsize = 3'b010; // 32 bit
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
    
    // 需要添加地址非对齐检测

    // assign axiif.bready = MemWrite & control_dMemRW;
    assign axiif.bready = 1;
    // sram读取32bit，再截取需要的部分
    assign axiif.araddr = {alu_out_i[31:2], 2'b00};
    always @(*) begin
        case (func3_i)
            3'b000: begin   //lb
                case (alu_out_i[1:0])
                    2'b00: mem_rdata = {{24{axiif.rdata[7]}}, axiif.rdata[7:0]};
                    2'b01: mem_rdata = {{24{axiif.rdata[15]}}, axiif.rdata[15:8]};
                    2'b10: mem_rdata = {{24{axiif.rdata[23]}}, axiif.rdata[23:16]};
                    2'b11: mem_rdata = {{24{axiif.rdata[31]}}, axiif.rdata[31:24]};
                endcase
            end
            3'b001: begin   //lh
                case (alu_out_i[1:0])
                    2'b00: mem_rdata = {{16{axiif.rdata[15]}}, axiif.rdata[15:0]};
                    2'b10: mem_rdata = {{16{axiif.rdata[31]}}, axiif.rdata[31:16]};
                    default: mem_rdata = 32'b0;
                endcase
            end
            3'b010: begin   //lw
                case (alu_out_i[1:0])
                    2'b00: mem_rdata = axiif.rdata;
                    default: mem_rdata = 32'b0;
                endcase
            end
            3'b100: begin   //lbu
                case (alu_out_i[1:0])
                    2'b00: mem_rdata = {24'b0, axiif.rdata[7:0]};
                    2'b01: mem_rdata = {24'b0, axiif.rdata[15:8]};
                    2'b10: mem_rdata = {24'b0, axiif.rdata[23:16]};
                    2'b11: mem_rdata = {24'b0, axiif.rdata[31:24]};
                endcase
            end
            3'b101: begin   //lhu
                case (alu_out_i[1:0])
                    2'b00: mem_rdata = {16'b0, axiif.rdata[15:0]};
                    2'b10: mem_rdata = {16'b0, axiif.rdata[31:16]};
                    default: mem_rdata = 32'b0;
                endcase
            end
            default: begin
                mem_rdata = 32'b0;
            end
        endcase
    end
    // assign mem_rdata = axiif.rdata;
    assign axiif.awaddr = {alu_out_i[31:2], 2'b00};
    assign axiif.wdata = mem_wdata;
    assign axiif.wstrb = mem_wmask << (alu_out_i[1:0]);

    assign control_dmemR_end = axiif.rvalid & axiif.rready;
    assign control_dmemW_end = axiif.bvalid & axiif.bready;


endmodule