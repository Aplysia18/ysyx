module ysyx_24110015_Controller(
    input clk,
    input rst,
    //from idu
    input control_ls,
    //to idu & ifu
    output control_RegWrite,
    // from ifu
    input control_iMemRead_end,
    //to ifu
    output reg control_iMemRead,
    //from lsu
    input control_dmemR_end,
    input control_dmemW_end,
    //to lsu
    output reg control_dMemRW
);
    reg [2:0] state, next_state;

    parameter [2:0] init = 3'b000;
    parameter [2:0] sIF = 3'b001;
    parameter [2:0] sID = 3'b011;
    parameter [2:0] sLS = 3'b010;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state <= init;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case(state)
            init: begin
                next_state = sIF;
            end
            sIF: begin
                if(control_iMemRead_end) begin
                    next_state = sID;
                end else begin
                    next_state = sIF;
                end
            end
            sID: begin
                if(control_ls) begin
                    next_state = sLS;
                end else begin
                    next_state = sIF;
                end
            end
            sLS: begin
                if(control_dmemR_end | control_dmemW_end) begin
                    next_state = sIF;
                end else begin
                    next_state = sLS;
                end
            end
            default: begin
                next_state = init;
            end
        endcase
    end

    reg iMemRead_flag;
    reg dMemRW_flag;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            control_iMemRead <= 0;
            control_dMemRW <= 0;
            iMemRead_flag <= 0;
            dMemRW_flag <= 0;
        end else begin
            case(next_state)
                sIF: begin
                    dMemRW_flag <= 0;
                    if(~iMemRead_flag) begin 
                        control_iMemRead <= 1;
                        iMemRead_flag <= 1;
                    end
                    else control_iMemRead <= 0;
                    control_dMemRW <= 0;
                end
                sID: begin
                    dMemRW_flag <= 0;
                    iMemRead_flag <= 0;
                    control_iMemRead <= 0;
                    control_dMemRW <= 0;
                end
                sLS: begin
                    iMemRead_flag <= 0;
                    control_iMemRead <= 0;
                    if(~dMemRW_flag) begin 
                        control_dMemRW <= 1;
                        dMemRW_flag <= 1;
                    end
                    else control_dMemRW <= 0;
                end
                default: begin
                    control_iMemRead <= 0;
                    control_dMemRW <= 0;
                end
            endcase
        end
    end

    assign control_RegWrite = ((state == sLS) & (control_dmemR_end | control_dmemW_end)) | ((state == sID) & (~control_ls));
    // assign control_iMemRead = (state == sIF);
    // assign control_dMemRW = (state == sID) | (state == sLS);

endmodule