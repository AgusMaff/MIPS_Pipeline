`timescale 1ns/1ps

module SIGN_EXTEND(
    input  wire [15:0] in,          // Entrada de 16 bits
    output wire [31:0] out          // Salida extendida a 32 bits
);

    // Extender el signo de los 16 bits a 32 bits
    assign out = { {16{in[15]}}, in };
endmodule