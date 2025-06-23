module ysyx_24110015_branch_predictor#(
    BLOCK_NUM = 8
) (
    input clk,
    input rst,
    //from ifu
    input [31:0] pc_in,
    //to ifu
    output [31:0] pc_predict,
    output pc_predict_valid,
    //from exu
    input update_valid,
    input branch,
    input jal,
    input [31:0] pc_update,
    input [31:0] target_addr
);
    localparam INDEX_WIDTH = $clog2(BLOCK_NUM);
    localparam TAG_WIDTH = 30 - INDEX_WIDTH; // 2 bits for offset, rest for tag
    
    logic [TAG_WIDTH-1:0] tag [0:BLOCK_NUM-1];
    logic [BLOCK_NUM-1:0] valid; // valid bits for each block
    logic [31:0] target [0:BLOCK_NUM-1];
    
    wire [INDEX_WIDTH-1:0] index = pc_in[INDEX_WIDTH+1:2];
    wire hit = valid[index] & (tag[index] == pc_in[31:32-TAG_WIDTH]);
    
    assign pc_predict = hit ? target[index] : pc_in + 4;
    assign pc_predict_valid = hit;

    wire [INDEX_WIDTH-1:0] update_index = pc_update[INDEX_WIDTH+1:2];
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid <= 0;
        end else if (update_valid) begin
            if (branch | jal) begin
                tag[update_index] <= pc_update[31:32-TAG_WIDTH];
                target[update_index] <= target_addr;
                valid[update_index] <= 1;
            end
        end
    end

    // always @(posedge clk) begin
    //     if(pc_predict_valid) begin
    //         $display("pc_in=%h, pc_predict=%h",pc_in, pc_predict);
    //     end
    // end
    
endmodule