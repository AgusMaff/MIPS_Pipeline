`timescale 1ns / 1ps

module M_WB (
    input wire i_clk,
    input wire i_clk_en, // Habilitar señal de reloj
    input wire i_reset,
    input wire [31:0] i_m_read_data,            // Datos leídos de memoria
    input wire [4:0]  i_m_rd,                   // ID del registro destino
    input wire [31:0] i_m_alu_result,           // Resultado de la ALU de la etapa MEM
    input wire        i_m_mem_to_reg,           // Señal de escritura de registro desde memoria
    input wire        i_m_reg_write,            // Señal de escritura de registro
    input wire        i_m_isJal,                // Señal de escritura de registro para instrucciones JAL
    input wire [31:0] i_m_pc_plus_8,          // PC + 4 de la etapa MEM
    input wire        i_m_halt,                 // Señal de parada de la etapa MEM

    output reg [31:0] o_wb_data,                   // Datos a escribir en el registro
    output reg [4:0]  o_wb_rd,                     // ID del registro destino
    output reg        o_wb_mem_to_reg,             // Señal de escritura de registro desde memoria
    output reg        o_wb_reg_write,                // Señal de escritura de registro
    output reg [31:0] o_wb_alu_result,            // Resultado de la ALU de la etapa MEM
    output reg        o_wb_isJal,                 // Señal de escritura de registro para instrucciones JAL
    output reg [31:0] o_wb_pc_plus_8,          // PC + 4 de la etapa MEM
    output reg        o_wb_halt                   // Señal de parada de la etapa WB
);

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_data <= 32'b0;
            o_wb_rd <= 5'b0;
            o_wb_mem_to_reg <= 1'b0;
            o_wb_reg_write <= 1'b0;
            o_wb_alu_result <= 32'b0; // Resetea el resultado de la ALU
            o_wb_halt <= 1'b0;
            o_wb_isJal <= 1'b0;
            o_wb_pc_plus_8 <= 32'b0; // Resetea el PC + 4
        end else if (i_clk_en) begin
            o_wb_data <= i_m_read_data; // Datos leídos de memoria
            o_wb_rd <= i_m_rd;          // ID del registro destino
            o_wb_mem_to_reg <= i_m_mem_to_reg; // Señal de escritura de registro desde memoria
            o_wb_reg_write <= i_m_reg_write;   // Señal de escritura de registro
            o_wb_alu_result <= i_m_alu_result; // Resultado de la ALU de la etapa MEM
            o_wb_halt <= i_m_halt; // Señal de parada de la etapa WB
            o_wb_isJal <= i_m_isJal; // Señal de escritura de registro para instrucciones JAL
            o_wb_pc_plus_8 <= i_m_pc_plus_8; // PC + 4 de la etapa MEM
        end
    end

endmodule