`timescale 1ns / 1ps

module PC(
    input  wire        i_clk,         // Reloj
    input  wire        i_reset,       // Reset
    input  wire [31:0] i_next_pc,     // Siguiente PC
    input  wire        stall,         // Señal de stall para agregar latencia
    output reg [31:0] o_pc            // PC actual
);

    // Inicialización del PC
    initial begin
        o_pc =  {32{1'b0}}; // Comienza en 0
    end

    // Proceso de actualización del PC
    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            o_pc <=  {32{1'b0}}; // Resetea el PC a 0
        end else if (stall) begin
            // Si hay un stall, no actualiza el PC
            o_pc <= o_pc; // Mantiene el valor actual del PC
        end else begin
            o_pc <= i_next_pc; // Actualiza el PC al siguiente valor
        end
    end
endmodule