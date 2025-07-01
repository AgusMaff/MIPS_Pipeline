`timescale 1ns / 1ps

module INSMEM(
    input wire         i_clk,         // Reloj
    input wire         i_reset,       // Reset
    input wire         i_write_en,    // Señal para habilitar escritura
    input wire         i_read_en,     // Señal para habilitar lectura
    input wire  [31:0] i_data,        // Datos a escribir
    input wire  [31:0] i_addr,        // Dirección de escritura
    output wire [31:0] o_instruction  // Instrucción leída
);
    // Memoria de instrucciones (1024 bytes = 256 instrucciones de 32 bits)
    reg [7:0] memory [0:1023];

    integer j;

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            // Resetea la memoria a ceros
            for (j = 0; j < 1024; j = j + 1) begin
                memory[j] <= 8'b0;
            end
        end else if (i_write_en) begin
            // Escribe datos en la memoria
            memory[i_addr] <= i_data[7:0];
            memory[i_addr + 1] <= i_data[15:8];
            memory[i_addr + 2] <= i_data[23:16];
            memory[i_addr + 3] <= i_data[31:24];
        end
    end

    // Lectura de la instrucción
    assign o_instruction = i_read_en ?
        {memory[i_addr + 3], memory[i_addr + 2], memory[i_addr + 1], memory[i_addr]} : 
                32'b0;

endmodule