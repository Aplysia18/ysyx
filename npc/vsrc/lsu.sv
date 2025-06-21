`ifndef __SYNTHESIS__
import "DPI-C" function int pmem_read(input int addr);
import "DPI-C" function void pmem_write(input int waddr, input int wdata, input byte wmask);
import "DPI-C" function void lsu_fetch();
`endif
module ysyx_24110015_LSU (
    input clk,
    input rst,
    //handshake signals
    input in_valid, //lsu valid
    output in_ready, //lsu ready
    output reg out_valid, //to wbu
    input out_ready, //from wbu
    //to conflict detection
    output reg processing,
    //from exu
    input [31:0] pc_i,
    input [31:0] inst_i,
    input [31:0] alu_out_i,
    input RegWrite_i,
    input [4:0] wb_addr_i,
    input [3:0] mem_wmask_i,
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
    input MemWrite_i,
    input MemRead_i,
    input [31:0] mem_wdata_i,
    input ebreak_i,
    //to wbu
    output [31:0] pc_o,
    output [31:0] inst_o,
    output [31:0] alu_out_o,
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
    output ebreak_o,
    //to axi
    axi_if.master axiif
);
    logic control_dMemRW; //dmem read/write start signal
    logic control_dmemR_end, control_dmemW_end; //dmem read/write end signals
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            control_dMemRW <= 0;
        end else if(in_valid & in_ready & (MemRead_i | MemWrite_i)) begin
            control_dMemRW <= 1; //dmem read/write request
        end else begin
            control_dMemRW <= 0; //dmem read/write request end
        end
    end

    /*-----handshake signals-----*/
    reg lsu_load_store;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            lsu_load_store = 0;
        end else if(in_valid & in_ready & (MemRead_i | MemWrite_i)) begin
            lsu_load_store = 1;
        end else if(control_dmemR_end | control_dmemW_end) begin 
            lsu_load_store = 0;
        end
    end
    assign in_ready = ~lsu_load_store | (control_dmemR_end | control_dmemW_end); // no load/store req
    
    
    reg out_valid_reg;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            out_valid_reg <= 0;
        end else if((in_valid & in_ready & ~(MemRead_i | MemWrite_i)) | ((control_dmemR_end | control_dmemW_end)&~out_ready)) begin
            out_valid_reg <= 1; // no load/store req, just pass through / axi read/write end
        end else if(out_ready) begin
            out_valid_reg <= 0;
        end
    end
    assign out_valid = out_valid_reg | (control_dmemR_end | control_dmemW_end);

    // direct assign signal
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            pc_o <= 32'b0;
            inst_o <= 32'b0;
            alu_out_o <= 32'b0;
            RegWrite_o <= 1'b0;
            wb_addr_o <= 5'b0;
            csr_rdata_o <= 32'b0;
            zicsr_o <= 1'b0;
            din_mstatus_o <= 32'b0;
            din_mtvec_o <= 32'b0;
            din_mepc_o <= 32'b0;
            din_mcause_o <= 32'b0;
            wen_mstatus_o <= 1'b0;
            wen_mtvec_o <= 1'b0;
            wen_mepc_o <= 1'b0;
            wen_mcause_o <= 1'b0;
            func3_o <= 3'b0;
            MemRead_o <= 1'b0;
            ebreak_o <= 1'b0;
        end else if(in_valid & in_ready) begin
            pc_o <= pc_i; //pc from exu
            inst_o <= inst_i; //instruction from exu
            alu_out_o <= alu_out_i; //alu result
            RegWrite_o <= RegWrite_i; //reg write signal
            wb_addr_o <= wb_addr_i; //write back address
            csr_rdata_o <= csr_rdata_i; //csr read data
            zicsr_o <= zicsr_i; //zicsr signal
            din_mstatus_o <= din_mstatus_i; //mstatus write data
            din_mtvec_o <= din_mtvec_i; //mtvec write data
            din_mepc_o <= din_mepc_i; //mepc write data
            din_mcause_o <= din_mcause_i; //mcause write data
            wen_mstatus_o <= wen_mstatus_i; //mstatus write enable
            wen_mtvec_o <= wen_mtvec_i; //mtvec write enable
            wen_mepc_o <= wen_mepc_i; //mepc write enable
            wen_mcause_o <= wen_mcause_i; //mcause write enable
            func3_o <= func3_i; //func3 for load/store operation
            MemRead_o <= MemRead_i; //memory read signal
            ebreak_o <= ebreak_i;
        end
    end
    
    logic [3:0] mem_wmask;
    logic MemWrite;
    logic [31:0] mem_wdata;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            mem_wmask <= 4'b0;
            MemWrite <= 1'b0;
            mem_wdata <= 32'b0;
        end else if(in_valid & in_ready) begin
            mem_wmask <= mem_wmask_i; //memory write mask
            MemWrite <= MemWrite_i; //memory write signal
            mem_wdata <= mem_wdata_i; //memory write data
        end
    end

    /*-----processing-----*/
    always @(posedge clk or posedge rst) begin
        if (rst) begin
        processing <= 1'b0;
        end else if (in_valid && in_ready) begin
        processing <= 1'b1;
        end else if (out_valid & out_ready) begin
        processing <= 1'b0;
        end
    end

    /*-----AXI control-----*/

`ifdef ysyxsoc
    logic in_sram, in_psram, in_sdram, in_chiplink, read_word_align, write_word_align;
    assign in_sram = (alu_out_o>=32'h0f000000)&(alu_out_o<32'h10000000);
    assign in_psram = (alu_out_o>=32'h80000000)&(alu_out_o<32'ha0000000);
    assign in_sdram = (alu_out_o>=32'ha0000000)&(alu_out_o<32'hc0000000);
    assign in_chiplink = (alu_out_o>=32'hc0000000);
    // assign read_word_align = in_sram | in_psram | in_sdram;
    assign read_word_align = in_sram | in_psram | in_sdram | in_chiplink;
    assign write_word_align = in_sram;
`else
    logic read_word_align, write_word_align;
    assign read_word_align = 1; // always read word aligned
    assign write_word_align = 1; // always write word aligned
`endif

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
    assign axiif.araddr = read_word_align ? {alu_out_o[31:2], 2'b00} : alu_out_o;
    //arsize: sram 4byte, other depends on func3
    always @(*) begin
        if(read_word_align) begin
            axiif.arsize = 3'b010;
        end else begin
            case (func3_o)
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
        case (func3_o)
            3'b000: begin   //lb
                if(read_word_align) begin
                    case (alu_out_o[1:0])
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
                    case (alu_out_o[1:0])
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
                case (alu_out_o[1:0])
                    2'b00: mem_rdata = axiif.rdata;
                    default: mem_rdata = 32'b0;
                endcase
            end
            3'b100: begin   //lbu
                if(read_word_align) begin
                    case (alu_out_o[1:0])
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
                    case (alu_out_o[1:0])
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
    assign axiif.wlast = 1; // always 1, no burst transfer
    
    assign axiif.bready = 1;

    assign axiif.awaddr = write_word_align ? {alu_out_o[31:2], 2'b00} : alu_out_o;
    //awsize: sram 4byte, other depends on func3
    always @(*) begin
        if(write_word_align) begin
            axiif.awsize = 3'b010;
        end else begin
            case (func3_o)
                3'b000: axiif.awsize = 3'b000; //sb
                3'b001: axiif.awsize = 3'b001; //sh
                3'b010: axiif.awsize = 3'b010; //sw
                default: axiif.awsize = 3'b010;
            endcase
        end
    end
    always @(*) begin
        case(func3_o)
            3'b000: begin   //sb
                case (alu_out_o[1:0])
                    2'b00: axiif.wdata = mem_wdata;
                    2'b01: axiif.wdata = mem_wdata << 8;
                    2'b10: axiif.wdata = mem_wdata << 16;
                    2'b11: axiif.wdata = mem_wdata << 24;
                endcase
            end
            3'b001: begin   //sh
                case (alu_out_o[1:0])
                    2'b00: axiif.wdata = mem_wdata;
                    2'b10: axiif.wdata = mem_wdata << 16;
                    default: axiif.wdata = 32'b0;
                endcase
            end
            3'b010: begin   //sw
                case (alu_out_o[1:0])
                    2'b00: axiif.wdata = mem_wdata;
                    default: axiif.wdata = 32'b0;
                endcase
            end
            default: begin
                axiif.wdata = 32'b0;
            end
        endcase
    end

    assign axiif.wstrb = mem_wmask << (alu_out_o[1:0]);

    assign control_dmemR_end = axiif.rvalid & axiif.rready;
    assign control_dmemW_end = axiif.bvalid & axiif.bready;

`ifndef __SYNTHESIS__
    always @(posedge clk or posedge rst) begin
        if(axiif.rvalid & axiif.rready) begin
            lsu_fetch();
        end
    end

`ifdef ysyxsoc
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
`endif
`endif

`ifndef __SYNTHESIS__
  always @(ebreak_o) begin
    if(ebreak_o) begin
      npc_trap();
    end
  end
`endif

endmodule