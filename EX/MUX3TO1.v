`timescale 1ns / 1ps

module MUX3TO1 (
    input  wire [31:0]  input_1,
    input  wire [31:0]  input_2,
    input  wire [31:0]  input_3,
    input  wire [1:0]   selection_bit,
    output wire [31:0]  mux
);
    assign mux = (selection_bit == 2'b00) ? input_1 :
                 (selection_bit == 2'b01) ? input_2 :
                 (selection_bit == 2'b10) ? input_3 : 32'h00000000; // Default case
endmodule