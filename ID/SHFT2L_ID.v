`timescale 1ns / 1ps

module SHFT2L_ID(
    input  wire [31:0] shift,       // Datos de entrada para desplazar 2 bits a la izquierda
    output wire [31:0] shifted_data // Direccion de salto incondicional (i_pc_plus_4 + i_shift)
);

    // Desplazar los 26 bits a la izquierda 2 posiciones
    assign shifted_data = { shift, 2'b00 };

endmodule
