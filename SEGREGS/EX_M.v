`timescale 1ns / 1ps

module EX_M (
    input wire i_clk,
    input wire i_reset,
    input wire [31:0] i_ex_alu_result,            // Resultado de la ALU de la etapa EX
    input wire [31:0] i_ex_write_data,            // Datos a escribir en memoria
    input wire [4:0]  i_ex_rd,                    // ID del registro destino
    input wire        i_ex_m_mem_read,            // Señal de lectura de memoria
    input wire        i_ex_m_mem_write,           // Señal de escritura de memoria
    input wire        i_ex_m_mem_to_reg,          // Señal de escritura de registro
    input wire        i_ex_m_reg_write,           // Señal de escritura de registro

    output reg [31:0] o_ex_m_alu_result,          // Resultado de la ALU
    output reg [31:0] o_ex_m_write_data,          // Datos a escribir en memoria
    output reg [4:0]  o_ex_m_rd,                  // ID del registro destino
    output reg        o_ex_m_mem_read,            // Señal de lectura de memoria
    output reg        o_ex_m_mem_write,           // Señal de escritura de memoria
    output reg        o_ex_m_mem_to_reg,          // Señal de escritura de registro
    output reg        o_ex_m_reg_write            // Señal de escritura de registro
);

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            o_ex_m_alu_result <= 32'b0;
            o_ex_m_write_data <= 32'b0;
            o_ex_m_rd <= 5'b0;
            o_ex_m_mem_read <= 1'b0;
            o_ex_m_mem_write <= 1'b0;
            o_ex_m_mem_to_reg <= 1'b0;
            o_ex_m_reg_write <= 1'b0;
        end else begin
            o_ex_m_alu_result <= i_ex_alu_result;
            o_ex_m_write_data <= i_ex_write_data;
            o_ex_m_rd <= i_ex_rd;
            o_ex_m_mem_read <= i_ex_m_mem_read;
            o_ex_m_mem_write <= i_ex_m_mem_write;
            o_ex_m_mem_to_reg <= i_ex_m_mem_to_reg;
            o_ex_m_reg_write <= i_ex_m_reg_write;
        end
    end

endmodule