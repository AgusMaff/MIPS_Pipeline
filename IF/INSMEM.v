`timescale 1ns / 1ps

module INSMEM(
    input wire  [31:0] addr,        // Dirección (PC)
    output wire [31:0] instruction // Instrucción leída
);
    // Memoria de instrucciones (ROM)
    reg [31:0] mem [0:255]; // 256 palabras de 32 bits

    // Inicialización de la memoria con instrucciones
    initial begin
        for (integer i = 0; i < 256; i = i + 1) begin
            mem[i] = {32{1'b0}}; // Inicializar con NOP (No Operation)
        end

        // Cargar programa desde archivo
         $readmemh("/home/amaffini/Desktop/TP3 - Arqui/MIPS_Pipeline/instruction_mem/test_instr.mem", mem);
    end

    // Asignación de la instrucción leída desde la memoria
    assign instruction = mem[addr[9:2]]; // Asumiendo que addr es un múltiplo de 4
endmodule