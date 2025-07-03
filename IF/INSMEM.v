`timescale 1ns / 1ps

module INSMEM(
    input wire         clk,         // Reloj
    input wire         reset,       // Reset
    input wire         write_en,    // Señal para habilitar escritura
    input wire         read_en,     // Señal para habilitar lectura
    input wire  [31:0] data,        // Datos a escribir
    input wire  [31:0] addr,        // Dirección de lectura
    input  wire [31:0] addr_wr,     // Direccion de escritura (no se usa en lectura)
    output wire [31:0] instruction  // Instrucción leída
);
    // Memoria de instrucciones (1024 bytes = 256 instrucciones de 32 bits)
    reg [7:0] memory [0:1023];

    integer j;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Resetea la memoria a ceros
            for (j = 0; j < 1024; j = j + 1) begin
                memory[j] <= 8'b0;
            end
        end else if (write_en) begin
            // Escribe datos en la memoria
            memory[addr_wr] <= data[7:0];
            memory[addr_wr + 1] <= data[15:8];
            memory[addr_wr + 2] <= data[23:16];
            memory[addr_wr + 3] <= data[31:24];
        end
    end

    // Lectura de la instrucción
    assign instruction = read_en ?
        {memory[addr + 3], memory[addr + 2], memory[addr + 1], memory[addr]} : 
                32'b0;

endmodule