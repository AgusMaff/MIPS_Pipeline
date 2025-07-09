`timescale 1ns / 1ps

module EX ( 
    input wire        i_clk,
    input wire        i_reset,
    input wire [31:0] i_id_ex_data_1,              // Primer operando
    input wire [31:0] i_id_ex_data_2,              // Segundo operando
    input wire [4:0]  i_id_ex_rs,                  // ID del registro fuente
    input wire [4:0]  i_id_ex_rt,                  // ID del registro destino
    input wire [4:0]  i_id_ex_rd,                  // ID del registro destino
    input wire [4:0]  i_id_ex_function_code,       // Código de función
    input wire [31:0] i_id_ex_extended_beq_offset, // Offset extend
    input wire        i_id_ex_reg_dst,             // Señal de destino del registro
    input wire        i_id_ex_alu_src,             // Señal de origen de la ALU
    input wire [3:0]  i_id_ex_alu_op,              // Operación ALU de la unidad de control
    input wire        i_id_ex_mem_read,            // Señal de lectura de memoria
    input wire        i_id_ex_mem_write,           // Señal de escritura de memoria
    input wire        i_id_ex_mem_to_reg,          // Señal de escritura de registro
    input wire        i_id_ex_reg_write,           // Señal de escritura de registro
    input wire [31:0] i_m_wb_data_write,                   // ID del registro destino de la etapa MEM
    input wire [31:0] i_ex_m_alu_result,           // Resultado de la ALU de la etapa EX/MEM
    input wire        i_ex_m_reg_write,            // Señal de escritura de registro de la etapa EX/MEM
    input wire [4:0]  i_ex_m_rd,              // ID del registro destino de la etapa EX/MEM
    input wire        i_m_wb_reg_write,            // Señal de escritura de registro de la etapa MEM/WB
    input wire [4:0]  i_m_wb_rd,                   // ID del registro destino de la etapa MEM/WB

    output wire [31:0] o_ex_m_alu_result,          // Resultado de la ALU
    output wire [31:0] o_ex_m_write_data,          // Datos a escribir en memoria
    output wire [4:0]  o_ex_m_rd,                  // ID del registro
    output wire        o_ex_m_mem_read,            // Señal de escritura de memoria
    output wire        o_ex_m_mem_write,           // Señal de lectura de memoria
    output wire        o_ex_m_mem_to_reg,          // Señal de escritura de registro
    output wire        o_ex_m_reg_write           // Señal de escritura de registro
);

    wire [1:0] forward_a; // Control de forwarding para el operando A
    wire [1:0] forward_b; // Control de forwarding para el operando B
    wire [31:0] operando_a;   
    wire [31:0] data_2;
    wire [31:0] operando_b;
    wire [5:0] alu_control_signal; // Señal de control de la ALU

    assign o_ex_m_write_data = data_2; // Datos a escribir en memoria
    assign o_ex_m_mem_read = i_id_ex_mem_read; // Señal de lectura de memoria
    assign o_ex_m_mem_write = i_id_ex_mem_write; // Señal de escritura de memoria
    assign o_ex_m_mem_to_reg = i_id_ex_mem_to_reg; // Señal de escritura de registro
    assign o_ex_m_reg_write = i_id_ex_reg_write; // Señal de escritura de registro

    FORWARDING_UNIT_EX forwarding_unit (
        .id_ex_rs(i_id_ex_rs),
        .id_ex_rt(i_id_ex_rt),
        .ex_mem_rd(i_id_ex_mem_rd),
        .mem_wb_rd(i_m_wb_rd),
        .ex_mem_reg_write(i_ex_m_reg_write),
        .mem_wb_reg_write(i_m_wb_reg_write),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    MUX3TO1 mux_data_1 (
        .input_1(i_id_ex_data_1),
        .input_2(i_ex_m_alu_result), 
        .input_3(i_m_wb_data_write),
        .selection_bit(forward_a),
        .mux(operando_a)
    );

    MUX3TO1 mux_data_2 (
        .input_1(i_id_ex_data_2),
        .input_2(i_ex_m_alu_result), 
        .input_3(i_m_wb_data_write),
        .selection_bit(forward_b),
        .mux(data_2)
    );

    MUX2TO1 mux_alu_src (
        .input_1(data_2),
        .input_2(i_id_ex_extended_beq_offset),
        .selection_bit(i_id_ex_alu_src),
        .mux(operando_b)
    );

    MUX2TO1_EX mux_reg_dst (
        .input_1(i_id_ex_rt),
        .input_2(i_id_ex_rd),
        .selection_bit(i_id_ex_reg_dst),
        .mux(o_ex_m_rd)
    );

    ALU_CONTROL alu_control (
        .alu_op(i_id_ex_alu_op),
        .function_code(i_id_ex_function_code), 
        .alu_control(alu_control_signal)
    );

    ALU alu_ex ( 
        .data_a(operando_a),
        .data_b(operando_b),
        .operation(alu_control_signal),
        .result(o_ex_m_alu_result)
    );

endmodule