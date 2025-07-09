`timescale 1ns / 1ps

module AND_ID (
    input  wire  a,       // Primer operando
    input  wire  b,       // Segundo operando
    output wire  result   // Resultado de la operación AND
);

    // Realizar la operación AND bit a bit
    assign result = a & b;
endmodule