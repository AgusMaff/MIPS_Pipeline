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
    input wire [31:0]  i_du_mem_addr,          // Dirección de memoria para la unidad de depuración

    output wire [31:0] o_m_wb_read_data,
    output wire [4:0]  o_m_rd,             // ID del registro destino
    output wire [4:0]  o_m_wb_rd,
    output wire [31:0] o_m_wb_alu_result,     // Resultado de la ALU de la etapa MEM
    output wire        o_m_wb_mem_to_reg,     // Señal de escritura de registro
    output wire        o_m_wb_reg_write,      // Señal de escritura de registro
    output wire [31:0] o_du_mem_data // Datos leídos de memoria para la unidad de depuración
);

    wire [31:0] mem_data_out;
    wire [31:0] mem_data_in;
    reg  [31:0] data_to_mem;
    reg  [31:0] read_data; // Registro para almacenar los datos leídos de memoria

    MEMDATA mem_data (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .mem_addr(i_mem_alu_result_or_addr), // Dirección de memoria
        .mem_data_in(mem_data_in), // Datos a escribir en memoria
        .mem_write_enable(i_m_mem_write), // Señal de escritura de memoria
        .du_mem_addr(i_du_mem_addr), // Dirección de memoria para la unidad de depuración

        .mem_data_out(mem_data_out), // Datos leídos de memoria
        .du_mem_data(o_du_mem_data) // Datos leídos de memoria para la unidad de depuración
    );

    always @(*) begin
        if (i_m_mem_read) begin // Carga (lectura)
            case(i_m_bhw_type[2:0])
                3'b001: begin // LW
                    read_data = mem_data_out; // Datos leídos de memoria
                end
                3'b010: begin // LH
                    read_data = {{16{mem_data_out[15]}}, mem_data_out[15:0]};
                end
                3'b100: begin // LB
                    read_data = {{24{mem_data_out[7]}}, mem_data_out[7:0]};
                end
                3'b101: begin //LWU
                    read_data = mem_data_out; // Datos leídos de memoria sin signo
                end
                3'b111: begin // LHU
                    read_data = {16'b0, mem_data_out[15:0]};
                end
                3'b110: begin // LBU
                    read_data = {24'b0, mem_data_out[7:0]};
                end
                default: begin
                    read_data = 32'b0;
                end
            endcase
        end else if (i_m_mem_write) begin // Almacenamiento (escritura)
            case(i_m_bhw_type[2:0])
                3'b001: begin // SW
                    data_to_mem = i_mem_write_data;
                end
                3'b010: begin // SH
                    data_to_mem = {16'b0, i_mem_write_data[15:0]};
                end
                3'b100: begin // SB
                    data_to_mem = {24'b0, i_mem_write_data[7:0]};
                end
                default: begin
                    data_to_mem = 32'b0;
                end
            endcase
        end
    end

    // Lectura de datos de memoria
    assign o_m_wb_read_data = read_data;

    assign mem_data_in = data_to_mem;
    
    assign o_m_wb_alu_result = i_mem_alu_result_or_addr;

    assign o_m_wb_rd = i_mem_rd;

    assign o_m_rd = i_mem_rd;

    assign o_m_wb_mem_to_reg = i_m_mem_to_reg;

    assign o_m_wb_reg_write = i_m_reg_write;
endmodule