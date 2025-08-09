`timescale 1ns / 1ps

module PC(
    input  wire         clk,         // Reloj
    input  wire         clk_en,      // Habilitar señal de reloj
    input  wire         reset,       // Reset
    input  wire [7:0]  next_pc,     // Siguiente PC
    input  wire         stall,       // Señal de stall para agregar latencia
    input  wire         write_en,    // Señal de escritura en memoria de instrucciones
    output wire [7:0]  pc           // PC actual
);

    reg [7:0] pc_reg;

    // Inicialización del PC
    initial begin
        pc_reg =  {7{1'b0}}; // Comienza en 0
    end

    // Proceso de actualización del PC
    always @(posedge clk or posedge reset) begin
        if (reset || write_en) begin
            pc_reg <=  {7{1'b0}}; // Resetea el PC a 0
        end else if (stall) begin
            // Si hay un stall, no actualiza el PC
            pc_reg <= pc_reg; // Mantiene el valor actual del PC
        end else if (clk_en) begin
            pc_reg <= next_pc; // Actualiza el PC al siguiente valor
        end
    end

    assign pc = pc_reg; // Salida del PC actual
endmodule