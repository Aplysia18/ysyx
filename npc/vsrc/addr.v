module ysyx_24110015_Addr #(WIDTH = 32) (
  input [WIDTH-1:0] ina,
  input [WIDTH-1:0] inb,
  output [WIDTH-1:0] outy
);
  assign outy = ina + inb;
endmodule