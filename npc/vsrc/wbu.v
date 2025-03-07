module ysyx_24110015_WBU (
    input clk,
    input rst,
    //from lsu
    input [31:0] alu_out,
    input [31:0] pc_next_i,
    input RegWrite_i,
    input [4:0] wb_addr_i,
    input zicsr,
    input [31:0] csr_rdata,
    input [31:0] din_mstatus_i,
    input [31:0] din_mtvec_i,
    input [31:0] din_mepc_i,
    input [31:0] din_mcause_i,
    input wen_mstatus_i,
    input wen_mtvec_i,
    input wen_mepc_i,
    input wen_mcause_i,
    input [2:0] func3,
    input MemRead,
    input [31:0] mem_rdata,
    //to exu
    output [31:0] pc_next_o,
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

    assign pc_next_o = pc_next_i;
    assign RegWrite_o = RegWrite_i;
    assign wb_addr_o = wb_addr_i;
    assign din_mstatus_o = din_mstatus_i;
    assign din_mtvec_o = din_mtvec_i;
    assign din_mepc_o = din_mepc_i;
    assign din_mcause_o = din_mcause_i;
    assign wen_mstatus_o = wen_mstatus_i;   
    assign wen_mtvec_o = wen_mtvec_i;
    assign wen_mepc_o = wen_mepc_i;
    assign wen_mcause_o = wen_mcause_i;

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

endmodule