import "DPI-C" function int pmem_read(input int addr);
import "DPI-C" function void pmem_write(input int waddr, input int wdata, input byte wmask);

module ysyx_24110015_SRAM #(ADDR_WIDTH = 32, DATA_WIDTH = 32)
(   
    input clk,
    input rst,
    //read
    input [ADDR_WIDTH-1:0] araddr,
    input ren,
    output reg [DATA_WIDTH-1:0] rdata,
    output reg [1:0] rresp,
    output reg rvalid,
    //write
    input [ADDR_WIDTH-1:0] awaddr,
    input [DATA_WIDTH-1:0] wdata,
    input wen,
    input [DATA_WIDTH/8-1:0] wstrb,
    output reg [1:0] bresp,
    output reg bvalid
);

    parameter DELAY_CYCLES = 5;

    reg [31:0] delay_counters;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            rdata <= 0;
            rresp <= 0;
            rvalid <= 0;
            bresp <= 0;
            bvalid <= 0;
            delay_counters <= DELAY_CYCLES-1;
        end else if (wen) begin
            if(delay_counters == 0) begin
                pmem_write(awaddr, wdata, {4'b0000,wstrb});
                $display("write addr:%x data:%x wstrb:%x", awaddr, wdata, wstrb);
                bresp <= 0;
                bvalid <= 1;
                delay_counters <= DELAY_CYCLES-1;
            end else begin
                delay_counters <= delay_counters - 1;
            end
        end
        else if(ren) begin
            if(delay_counters == 0) begin
                rdata <= pmem_read(araddr);
                $display("read addr:%x data:%x", araddr, rdata);
                rresp <= 0;
                rvalid <= 1;
                delay_counters <= DELAY_CYCLES-1;
            end else begin
                delay_counters <= delay_counters - 1;
            end
        end else begin
            rdata <= 0;
            rresp <= 0;
            rvalid <= 0;
            bresp <= 0;
            bvalid <= 0;
            delay_counters <= DELAY_CYCLES-1;
        end
    end

endmodule