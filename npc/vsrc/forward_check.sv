module ysyx_24110015_forward_check (
    //from idu
    input logic idu_processing,
    input logic idu_reg1_read,
    input logic idu_reg2_read,
    input logic [4:0] idu_raddr1,
    input logic [4:0] idu_raddr2,
    //from exu
    input logic exu_processing,
    input logic RegWrite_exu,
    input logic [4:0] wb_addr_exu,
    input logic MemRead_exu,
    input logic zicsr_exu,
    input logic [31:0] alu_out_exu,
    input logic [31:0] csr_rdata_exu,
    //from lsu
    input logic lsu_processing,
    input logic RegWrite_lsu,
    input logic [4:0] wb_addr_lsu,
    input logic MemRead_lsu,
    input logic zicsr_lsu,
    input logic [31:0] alu_out_lsu,
    input logic [31:0] csr_rdata_lsu,
    //from wbu
    input logic wbu_processing,
    input logic RegWrite_wbu,
    input logic [4:0] wb_addr_wbu,
    input logic [31:0] wb_data_wbu,
    //output to idu
    output logic rs1_raw,   //raw check
    output logic rs1_forward,   //rs1 can be forwarded
    output logic [31:0] rs1_value, //value to be forwarded
    output logic rs2_raw,
    output logic rs2_forward,
    output logic [31:0] rs2_value
);
    wire idu_rs1_check, idu_rs2_check;
    wire idu_rs1_check = idu_processing & idu_reg1_read & (idu_raddr1 != 0);
    wire idu_rs2_check = idu_processing & idu_reg2_read & (idu_raddr2 != 0);
    
    logic rs1_raw_exu, rs1_raw_lsu, rs1_raw_wbu;
    logic rs2_raw_exu, rs2_raw_lsu, rs2_raw_wbu;
    assign rs1_raw_exu = exu_processing & RegWrite_exu & (wb_addr_exu == idu_raddr1);
    assign rs1_raw_lsu = lsu_processing & RegWrite_lsu & (wb_addr_lsu == idu_raddr1);
    assign rs1_raw_wbu = wbu_processing & RegWrite_wbu & (wb_addr_wbu == idu_raddr1);
    assign rs1_raw = idu_rs1_check & (rs1_raw_exu | rs1_raw_lsu | rs1_raw_wbu);

    logic rs1_forward_exu, rs1_forward_lsu, rs1_forward_wbu;
    assign rs1_forward_exu = rs1_raw_exu & ~MemRead_exu;
    assign rs1_forward_lsu = ~rs1_raw_exu & rs1_raw_lsu & ~MemRead_lsu;
    assign rs1_forward_wbu = ~rs1_raw_exu & ~rs1_raw_lsu & rs1_raw_wbu;
    assign rs1_forward = idu_rs1_check & (rs1_forward_exu | rs1_forward_lsu | rs1_forward_wbu);
    assign rs1_value = rs1_forward_exu ? (zicsr_exu ? csr_rdata_exu : alu_out_exu) :
                    rs1_forward_lsu ? (zicsr_lsu ? csr_rdata_lsu : alu_out_lsu) :
                    rs1_forward_wbu ? wb_data_wbu : 0;

    assign rs2_raw_exu = exu_processing & RegWrite_exu & (wb_addr_exu == idu_raddr2);
    assign rs2_raw_lsu = lsu_processing & RegWrite_lsu & (wb_addr_lsu == idu_raddr2);
    assign rs2_raw_wbu = wbu_processing & RegWrite_wbu & (wb_addr_wbu == idu_raddr2);
    assign rs2_raw = idu_rs2_check & (rs2_raw_exu | rs2_raw_lsu | rs2_raw_wbu);
    logic rs2_forward_exu, rs2_forward_lsu, rs2_forward_wbu;
    assign rs2_forward_exu = rs2_raw_exu & ~MemRead_exu;
    assign rs2_forward_lsu = ~rs2_raw_exu & rs2_raw_lsu & ~MemRead_lsu;
    assign rs2_forward_wbu = ~rs2_raw_exu & ~rs2_raw_lsu & rs2_raw_wbu;
    assign rs2_forward = idu_rs2_check & (rs2_forward_exu | rs2_forward_lsu | rs2_forward_wbu);
    assign rs2_value = rs2_forward_exu ? (zicsr_exu ? csr_rdata_exu : alu_out_exu) :
                    rs2_forward_lsu ? (zicsr_lsu ? csr_rdata_lsu : alu_out_lsu) :
                    rs2_forward_wbu ? wb_data_wbu : 0;

endmodule