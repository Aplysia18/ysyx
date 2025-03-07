module ysyx_24110015_Controller(
    input clk,
    input rst,
    //from idu
    input control_load,
    //to idu & ifu
    output control_RegWrite,
    //to ifu
    output control_iMemRead,
    //to lsu
    output control_dMemRW
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
            next_state = sID;
        end
        sID: begin
            if(control_load) begin
                next_state = sLS;
            end else begin
                next_state = sIF;
            end
        end
        default: begin
            next_state = init;
        end
    endcase
end

    assign control_RegWrite = (state == sLS) | ((state == sID) & (~control_load));
    assign control_iMemRead = (state == sIF);
    assign control_dMemRW = (state == sID);

endmodule