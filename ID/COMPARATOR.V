`timescale 1ns / 1ps

module COMPARATOR(
    input  wire [31:0] dato_a,   // Primer operando
    input  wire [31:0] dato_b,   // Segundo operando
    output wire        equal    // Señal de igualdad
);

    // Comparar los dos operandos
    assign equal = (a == b) ? 1'b1 : 1'b0;
endmodule