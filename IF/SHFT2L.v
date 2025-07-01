`timescale 1ns / 1ps

module SHFT2L(
    input  wire [31:0] i_data,       // Datos de entrada
    output wire [31:0] o_shifted     // Datos desplazados a la izquierda
);
    // Desplaza los datos a la izquierda 2 bits
    assign o_shifted = {i_data[29:0], 2'b00};
endmodule