`timescale 1ns / 1ps

module MUX2To1_1BIT (
    input  wire input_1,
    input  wire input_2,
    input  wire selection_bit,
    output wire mux
);
    assign mux = (selection_bit == 1'b0) ? input_1 : input_2;
endmodule