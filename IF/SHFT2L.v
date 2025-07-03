`timescale 1ns / 1ps

module SHFT2L(
    input  wire [0:3]  pc_plus_4,   // 4 bits mas significativos del PC + 4
    input  wire [25:0] shift,       // Datos de entrada para desplazar 2 bits a la izquierda
    output wire [31:0] jump_dir     // Direccion de salto incondicional (i_pc_plus_4 + i_shift)
);


    wire [27:0] shifted; // Resultado del desplazamiento

    // Desplazar 2 bits a la izquierda (equivale a multiplicar por 4)
    assign shifted = shift << 2;

    // Concatenar con los 4 bits más significativos de PC+4
    assign jump_dir = {pc_plus_4, shifted};

endmodule


