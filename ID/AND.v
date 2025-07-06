`timescale 1ns / 1ps

module AND(
    input  wire [31:0] a,       // Primer operando
    input  wire [31:0] b,       // Segundo operando
    output wire [31:0] result   // Resultado de la operación AND
);

    // Realizar la operación AND bit a bit
    assign result = a & b;
endmodule