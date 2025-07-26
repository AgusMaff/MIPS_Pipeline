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
    // Memoria de instrucciones (256 bytes = 64 palabras de 32 bits)
    reg [7:0] memory [0:255];

    integer j;

    wire [31:0] read_base_addr = addr;
    wire [31:0] write_base_addr = addr_wr;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Resetea la memoria a ceros
            for (j = 0; j < 256; j = j + 1) begin
                memory[j] <= 8'b0;
            end
        end else if (write_en) begin
            // Escribe datos en la memoria
            memory[write_base_addr] <= data[7:0];
            memory[write_base_addr + 1] <= data[15:8];
            memory[write_base_addr + 2] <= data[23:16];
            memory[write_base_addr + 3] <= data[31:24];
        end
    end

    // Lectura de la instrucción
    assign instruction = read_en ?
        {memory[read_base_addr + 3], memory[read_base_addr + 2], memory[read_base_addr + 1], memory[read_base_addr]} : 
                32'b0;

endmodule