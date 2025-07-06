`timescale 1ns / 1ps

module MUX2TO1 (
    input  wire [31:0]  input_1,
    input  wire [31:0]  input_2,
    input  wire         selection_bit,
    output wire [31:0]  mux
);

  assign mux = (selection_bit) ? input_2 : input_1;
endmodule