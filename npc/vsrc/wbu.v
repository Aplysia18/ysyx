import "DPI-C" function void wbu_begin();
import "DPI-C" function void wbu_end(input int inst);

module ysyx_24110015_WBU (
    input clk,
    input rst,
    //handshake signals
    input in_valid, //wbu valid
    output in_ready, //wbu ready
    output reg out_valid, //to npc
    input out_ready, //from npc
    //to conflict detection
    output reg processing,
    //from lsu
    input [31:0] pc_i,
    input [31:0] inst_i,
    input [31:0] alu_out_i,
    input RegWrite_i,
    input [4:0] wb_addr_i,
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
    input MemRead_i,
    input [31:0] mem_rdata_i,
    input ebreak_i,
    //to idu
    output reg [31:0] pc_o,
    output reg [31:0] inst_o,
    output RegWrite_o,
    output [4:0] wb_addr_o,
    output [31:0] din_mstatus_o,
    output [31:0] din_mtvec_o,
    output [31:0] din_mepc_o,
    output [31:0] din_mcause_o,
    output wen_mstatus_o,
    output wen_mtvec_o,
    output wen_mepc_o,
    output wen_mcause_o,
    output reg [31:0] wb_data

);
    /*-----handshake signals-----*/
    assign in_ready = 1'b1;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
        out_valid <= 1'b0;
        end else if (in_valid && in_ready) begin
        out_valid <= 1'b1;
        end else if(out_ready) begin
        out_valid <= 1'b0;
        end
    end

    //direct assign signals
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_o <= 32'b0;
            inst_o <= 32'b0;
            RegWrite_o <= 1'b0;
            wb_addr_o <= 5'b0;
            din_mstatus_o <= 32'b0;
            din_mtvec_o <= 32'b0;
            din_mepc_o <= 32'b0;
            din_mcause_o <= 32'b0;
            wen_mstatus_o <= 1'b0;
            wen_mtvec_o <= 1'b0;
            wen_mepc_o <= 1'b0;
            wen_mcause_o <= 1'b0;
        end else if (in_valid && in_ready) begin
            pc_o <= pc_i;
            inst_o <= inst_i;
            RegWrite_o <= RegWrite_i;
            wb_addr_o <= wb_addr_i;
            din_mstatus_o <= din_mstatus_i;
            din_mtvec_o <= din_mtvec_i;
            din_mepc_o <= din_mepc_i;
            din_mcause_o <= din_mcause_i;
            wen_mstatus_o <= wen_mstatus_i;
            wen_mtvec_o <= wen_mtvec_i;
            wen_mepc_o <= wen_mepc_i;
            wen_mcause_o <= wen_mcause_i;
        end
    end

    reg [31:0] alu_out;
    reg zicsr;
    reg [31:0] csr_rdata;
    reg [2:0] func3;
    reg MemRead;
    reg [31:0] mem_rdata;
    reg ebreak;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_out <= 32'b0;
            zicsr <= 1'b0;
            csr_rdata <= 32'b0;
            func3 <= 3'b0;
            MemRead <= 1'b0;
            mem_rdata <= 32'b0;
        end else if (in_valid && in_ready) begin
            alu_out <= alu_out_i;
            zicsr <= zicsr_i;
            csr_rdata <= csr_rdata_i;
            func3 <= func3_i;
            MemRead <= MemRead_i;
            mem_rdata <= mem_rdata_i;
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
    
    /*-----write back data calculate-----*/

    always @(*) begin
        if(zicsr) begin
            wb_data = csr_rdata;
        end
        else if(MemRead) begin
            case(func3)
                3'b000: wb_data = {{24{mem_rdata[7]}}, mem_rdata[7:0]};
                3'b001: wb_data = {{16{mem_rdata[15]}}, mem_rdata[15:0]};
                3'b010: wb_data = mem_rdata;
                3'b100: wb_data = {24'b0, mem_rdata[7:0]};
                3'b101: wb_data = {16'b0, mem_rdata[15:0]};
                default: wb_data = 32'b0;
            endcase
        end
        else begin
            wb_data = alu_out;
        end
    end

/*-----ebreak-----*/

`ifndef __SYNTHESIS__
  always@(posedge clk) begin
    if(out_valid & out_ready) begin
        wbu_end(inst_o);
    end
    if(in_valid & in_ready) begin
        wbu_begin();
    end 
  end
`endif

endmodule