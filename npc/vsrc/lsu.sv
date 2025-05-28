import "DPI-C" function int pmem_read(input int addr);
import "DPI-C" function void pmem_write(input int waddr, input int wdata, input byte wmask);
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

    logic in_sram, in_psram, in_sdram, read_word_align, write_word_align;
    assign in_sram = (alu_out_i>=32'h0f000000)&(alu_out_i<32'h10000000);
    assign in_psram = (alu_out_i>=32'h80000000)&(alu_out_i<32'ha0000000);
    assign in_sdram = (alu_out_i>=32'ha0000000)&(alu_out_i<32'hc0000000);
    // assign read_word_align = in_sram | in_psram | in_sdram;
    assign read_word_align = in_sram | in_psram | in_sdram;
    assign write_word_align = in_sram;

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
    // assign axiif.arsize = 3'b010; // 32 bit
    assign axiif.rready = 1;

    // sram读取32bit，再截取需要的部分; uart窄传输，需要控制arsize
    assign axiif.araddr = read_word_align ? {alu_out_i[31:2], 2'b00} : alu_out_i;
    //arsize: sram 4byte, other depends on func3
    always @(*) begin
        if(read_word_align) begin
            axiif.arsize = 3'b010;
        end else begin
            case (func3_i)
                3'b000: axiif.arsize = 3'b000; //lb
                3'b001: axiif.arsize = 3'b001; //lh
                3'b010: axiif.arsize = 3'b010; //lw
                3'b100: axiif.arsize = 3'b000; //lbu
                3'b101: axiif.arsize = 3'b001; //lhu
                default: axiif.arsize = 3'b010;
            endcase
        end
    end
    
    always @(*) begin
        case (func3_i)
            3'b000: begin   //lb
                if(read_word_align) begin
                    case (alu_out_i[1:0])
                        2'b00: mem_rdata = {{24{axiif.rdata[7]}}, axiif.rdata[7:0]};
                        2'b01: mem_rdata = {{24{axiif.rdata[15]}}, axiif.rdata[15:8]};
                        2'b10: mem_rdata = {{24{axiif.rdata[23]}}, axiif.rdata[23:16]};
                        2'b11: mem_rdata = {{24{axiif.rdata[31]}}, axiif.rdata[31:24]};
                    endcase
                end
                else begin
                    mem_rdata = {{24{axiif.rdata[7]}}, axiif.rdata[7:0]};
                end
            end
            3'b001: begin   //lh
                if(read_word_align) begin
                    case (alu_out_i[1:0])
                        2'b00: mem_rdata = {{16{axiif.rdata[15]}}, axiif.rdata[15:0]};
                        2'b10: mem_rdata = {{16{axiif.rdata[31]}}, axiif.rdata[31:16]};
                        default: mem_rdata = 32'b0;
                    endcase
                end
                else begin
                    mem_rdata = {{16{axiif.rdata[15]}}, axiif.rdata[15:0]};
                end
            end
            3'b010: begin   //lw
                case (alu_out_i[1:0])
                    2'b00: mem_rdata = axiif.rdata;
                    default: mem_rdata = 32'b0;
                endcase
            end
            3'b100: begin   //lbu
                if(read_word_align) begin
                    case (alu_out_i[1:0])
                        2'b00: mem_rdata = {24'b0, axiif.rdata[7:0]};
                        2'b01: mem_rdata = {24'b0, axiif.rdata[15:8]};
                        2'b10: mem_rdata = {24'b0, axiif.rdata[23:16]};
                        2'b11: mem_rdata = {24'b0, axiif.rdata[31:24]};
                    endcase
                end
                else begin
                    mem_rdata = {24'b0, axiif.rdata[7:0]};
                end
            end
            3'b101: begin   //lhu
                if(read_word_align) begin
                    case (alu_out_i[1:0])
                        2'b00: mem_rdata = {16'b0, axiif.rdata[15:0]};
                        2'b10: mem_rdata = {16'b0, axiif.rdata[31:16]};
                        default: mem_rdata = 32'b0;
                    endcase
                end
                else begin
                    mem_rdata = {16'b0, axiif.rdata[15:0]};
                end
            end
            default: begin
                mem_rdata = 32'b0;
            end
        endcase
    end

    /*-----write-----*/

    // assign axiif.awsize = 3'b010; // 32 bit
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

    reg axi_write_buf, axi_write_buf_1;
    // wvalid信号比awvalid信号延迟两个周期发送，使cpu顶层发送的wvalid信号在awvalid信号之后一个周期（xbar使awvalid延迟一个周期）
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            axiif.wvalid <= 0;
        end else begin
            if(axiif.wvalid) begin 
                if(axiif.wready) begin
                    axiif.wvalid <= 0;
                end
            end else if(axi_write_buf)begin
                axi_write_buf_1 <= 1;
                axi_write_buf <= 0; // clear the buffer after write
            end else if(axi_write_buf_1) begin
                axi_write_buf_1 <= 0;
                axiif.wvalid <= 1; // write data
            end else if(MemWrite & control_dMemRW) begin
                axi_write_buf <= 1;
                //axiif.wvalid <= 1;
            end else begin
                axiif.wvalid <= 0;
            end
        end
    end

    assign axiif.wlast = 1; // always 1, no burst transfer
    
    assign axiif.bready = 1;

    assign axiif.awaddr = write_word_align ? {alu_out_i[31:2], 2'b00} : alu_out_i;
    //awsize: sram 4byte, other depends on func3
    always @(*) begin
        if(write_word_align) begin
            axiif.awsize = 3'b010;
        end else begin
            case (func3_i)
                3'b000: axiif.awsize = 3'b000; //sb
                3'b001: axiif.awsize = 3'b001; //sh
                3'b010: axiif.awsize = 3'b010; //sw
                default: axiif.awsize = 3'b010;
            endcase
        end
    end
    always @(*) begin
        case(func3_i)
            3'b000: begin   //sb
                case (alu_out_i[1:0])
                    2'b00: axiif.wdata = mem_wdata;
                    2'b01: axiif.wdata = mem_wdata << 8;
                    2'b10: axiif.wdata = mem_wdata << 16;
                    2'b11: axiif.wdata = mem_wdata << 24;
                endcase
            end
            3'b001: begin   //sh
                case (alu_out_i[1:0])
                    2'b00: axiif.wdata = mem_wdata;
                    2'b10: axiif.wdata = mem_wdata << 16;
                    default: axiif.wdata = 32'b0;
                endcase
            end
            3'b010: begin   //sw
                case (alu_out_i[1:0])
                    2'b00: axiif.wdata = mem_wdata;
                    default: axiif.wdata = 32'b0;
                endcase
            end
            default: begin
                axiif.wdata = 32'b0;
            end
        endcase
    end

    assign axiif.wstrb = mem_wmask << (alu_out_i[1:0]);

    assign control_dmemR_end = axiif.rvalid & axiif.rready;
    assign control_dmemW_end = axiif.bvalid & axiif.bready;

    //for the skip of difftest
    always @(posedge clk or posedge rst) begin
        if(!rst) begin
            if(axiif.awvalid && axiif.awready) begin
                pmem_write(axiif.awaddr, axiif.wdata, {4'b0, axiif.wstrb}); // wdata/wstrb not correct
            end
            if(axiif.arvalid && axiif.rready) begin
                mem_rdata = pmem_read(axiif.araddr);
            end
        end
    end


endmodule