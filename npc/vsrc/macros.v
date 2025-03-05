//opcode class
`define lui 7'b0110111
`define auipc 7'b0010111
`define jal 7'b1101111
`define jalr 7'b1100111
`define B_type 7'b1100011
`define load 7'b0000011
`define S_type 7'b0100011
`define ALU_I_type 7'b0010011
`define ALU_R_type 7'b0110011
`define fence 7'b0001111
`define system 7'b1110011
`define zicsr 7'b1110011

//ALUsel
`define ALU_ADD 4'b0000
`define ALU_SLL 4'b0001
`define ALU_LT 4'b0010
`define ALU_LTU 4'b0011
`define ALU_XOR 4'b0100
`define ALU_SRL 4'b0101
`define ALU_OR 4'b0110
`define ALU_AND 4'b0111
`define ALU_SUB 4'b1000
`define ALU_EQ  4'b1001
`define ALU_NE 4'b1010
`define ALU_GE 4'b1011
`define ALU_GEU 4'b1100
`define ALU_SRA 4'b1101
//1110
//1111