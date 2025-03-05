import "DPI-C" function int pmem_read(input int addr);
// import "DPI-C" function void pmem_write(input int waddr, input int wdata, input byte wmask);

module ysyx_24110015_SRAM #(ADDR_WIDTH = 32, DATA_WIDTH = 32)
(   
    input clk,
    input [ADDR_WIDTH-1:0] raddr,
    input ren,
    input [ADDR_WIDTH-1:0] waddr,
    input [DATA_WIDTH-1:0] wdata,
    input wen,
    output reg [DATA_WIDTH-1:0] rdata
);

    always @(posedge clk) begin
        // if (wen) begin
        //     mem[waddr] <= wdata;
        // end
        if(ren) begin
            rdata <= pmem_read(raddr);
        end
    end

endmodule