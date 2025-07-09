`timescale 1ns / 1ps

module COMPARATOR(
    input  wire [31:0] data_a,   // Primer operando
    input  wire [31:0] data_b,   // Segundo operando
    output wire        equal    // Señal de igualdad
);

    // Comparar los dos operandos
    assign equal = (data_a == data_b) ? 1'b1 : 1'b0;
endmodule