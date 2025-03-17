// for AXI latency test

module ysyx_24110015_shiftRegister(
  input clk,
  input rst,
  output reg [7:0] y
);
  wire in1bit;
  assign in1bit = ~(|y) ? 1'b1 : (y[4]^y[3]^y[2]^y[0]);

  always @(posedge clk) begin
    if(rst) begin
      y <= 8'b00000001;
    end else begin
      y <= {in1bit, y[7:1]};
    end
  end

endmodule