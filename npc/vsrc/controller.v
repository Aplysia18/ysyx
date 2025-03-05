module ysyx_24110015_Controller(
    input clk,
    input rst,
    // input [31:0] pc,
    // input [31:0] inst,
    output reg RegWrite,
    output reg iMemRead,
    output reg dMemWrite
);
reg [2:0] state, next_state;

parameter [2:0] init = 3'b000;
parameter [2:0] sIF = 3'b001;
parameter [2:0] sID = 3'b011;

always @(posedge clk or posedge rst) begin
    if(rst) begin
        state <= init;
    end else begin
        state <= next_state;
    end
end

always @(posedge clk) begin
        case(state)
            init: begin
                next_state <= sIF;
            end
            sIF: begin
                next_state <= sID;
            end
            sID: begin
                next_state <= sIF;
            end
            default: begin
                next_state <= init;
            end
        endcase
end

always @(*) begin
    case(state)
        init: begin
            RegWrite = 1'b0;
            iMemRead = 1'b0;
            dMemWrite = 1'b0;
        end
        sIF: begin
            RegWrite = 1'b0;
            iMemRead = 1'b1;
            dMemWrite = 1'b0;
        end
        sID: begin
            RegWrite = 1'b1;
            iMemRead = 1'b0;
            dMemWrite = 1'b1;
        end
        default: begin
            RegWrite = 1'b0;
            iMemRead = 1'b0;
            dMemWrite = 1'b0;
        end
    endcase
end

endmodule