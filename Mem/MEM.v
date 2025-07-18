`timescale 1ns / 1ps

module MEM (
    input wire i_clk,
    input wire i_reset,
    input wire [31:0] i_mem_alu_result_or_addr,            // Resultado de la ALU de la etapa MEM
    input wire [31:0] i_mem_write_data,            // Datos a escribir en memoria
    input wire [4:0]  i_mem_rd,                    // ID del registro destino
    input wire        i_m_mem_read,            // Señal de lectura de memoria
    input wire        i_m_mem_write,           // Señal de escritura de memoria
    input wire        i_m_mem_to_reg,          // Señal de escritura de registro
    input wire        i_m_reg_write,           // Señal de escritura de registro
    input wire [2:0]  i_m_bhw_type,          // Tipo de instrucción (Byte, Halfword, Word)

    output wire [31:0] o_m_wb_read_data,
    output wire [4:0]  o_m_rd,             // ID del registro destino
    output wire [4:0]  o_m_wb_rd,
    output wire [31:0] o_m_wb_alu_result,     // Resultado de la ALU de la etapa MEM
    output wire        o_m_wb_mem_to_reg,     // Señal de escritura de registro
    output wire        o_m_wb_reg_write      // Señal de escritura de registro
);

    // Memoria de datos (1016 bytes = 254 palabras de 32 bits)
    reg [7:0] memory [0:1015];
    reg [31:0] read_data; // Registro para almacenar los datos leídos de memoria

    integer j;

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            // Resetea la memoria a ceros
            for (j = 0; j < 1016; j = j + 1) begin
                memory[j] <= 8'b0;
                read_data <= 32'b0; // Resetea el registro de datos leídos
            end
        end else if (i_m_mem_write) begin //Almacenamiento
            case(i_m_bhw_type[2:0])
                3'b001: begin // Word
                    memory[i_mem_alu_result_or_addr]     <= i_mem_write_data[7:0];
                    memory[i_mem_alu_result_or_addr + 1] <= i_mem_write_data[15:8];
                    memory[i_mem_alu_result_or_addr + 2] <= i_mem_write_data[23:16];
                    memory[i_mem_alu_result_or_addr + 3] <= i_mem_write_data[31:24];
                end
                3'b010: begin // Halfword
                    memory[i_mem_alu_result_or_addr]     <= i_mem_write_data[7:0];
                    memory[i_mem_alu_result_or_addr + 1] <= i_mem_write_data[15:8];
                end
                3'b100: begin // Byte
                    memory[i_mem_alu_result_or_addr]     <= i_mem_write_data[7:0];
                end
            endcase
        end else if (i_m_mem_read) begin //Carga
            case(i_m_bhw_type[2:0])
                3'b001: begin // Word
                    read_data <= {memory[i_mem_alu_result_or_addr + 3],
                                  memory[i_mem_alu_result_or_addr + 2],
                                  memory[i_mem_alu_result_or_addr + 1],
                                  memory[i_mem_alu_result_or_addr]};
                end
                3'b010: begin // Halfword
                    read_data <= {memory[i_mem_alu_result_or_addr + 1],
                                  memory[i_mem_alu_result_or_addr]};
                end
                3'b100: begin // Byte
                    read_data <= {24'b0, memory[i_mem_alu_result_or_addr]};
                end
                default: begin
                    read_data <= 32'b0;
                end
            endcase
        end
    end

    // Lectura de datos de memoria
    assign o_m_wb_read_data = read_data;
    
    assign o_m_wb_alu_result = i_mem_alu_result_or_addr;
    assign o_m_wb_rd = i_mem_rd;
    assign o_m_rd = i_mem_rd;
    assign o_m_wb_mem_to_reg = i_m_mem_to_reg;
    assign o_m_wb_reg_write = i_m_reg_write;
endmodule