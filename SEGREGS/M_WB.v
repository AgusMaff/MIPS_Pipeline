`timescale 1ns / 1ps

module M_WB (
    input wire i_clk,
    input wire i_reset,
    input wire [31:0] i_m_read_data,            // Datos leídos de memoria
    input wire [4:0]  i_m_rd,                   // ID del registro destino
    input wire [31:0] i_m_alu_result,           // Resultado de la ALU de la etapa MEM
    input wire        i_m_mem_to_reg,           // Señal de escritura de registro desde memoria
    input wire        i_m_reg_write,            // Señal de escritura de registro

    output reg [31:0] o_wb_data,                   // Datos a escribir en el registro
    output reg [4:0]  o_wb_rd,                     // ID del registro destino
    output reg        o_wb_mem_to_reg,             // Señal de escritura de registro desde memoria
    output reg        o_wb_reg_write,                // Señal de escritura de registro
    output reg [31:0] o_wb_alu_result            // Resultado de la ALU de la etapa MEM
);

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_data <= 32'b0;
            o_wb_rd <= 5'b0;
            o_wb_mem_to_reg <= 1'b0;
            o_wb_reg_write <= 1'b0;
            o_wb_alu_result <= 32'b0; // Resetea el resultado de la ALU
        end else begin
            o_wb_data <= i_m_read_data; // Datos leídos de memoria
            o_wb_rd <= i_m_rd;          // ID del registro destino
            o_wb_mem_to_reg <= i_m_mem_to_reg; // Señal de escritura de registro desde memoria
            o_wb_reg_write <= i_m_reg_write;   // Señal de escritura de registro
            o_wb_alu_result <= i_m_alu_result; // Resultado de la ALU de la etapa MEM
        end
    end

endmodule