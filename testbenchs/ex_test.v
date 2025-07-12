`timescale 1ns / 1ps

module ex_test;

    reg [31:0] i_id_ex_data_1;
    reg [31:0] i_id_ex_data_2;
    reg [4:0]  i_id_ex_rs;
    reg [4:0]  i_id_ex_rt;
    reg [4:0]  i_id_ex_rd;
    reg [4:0]  i_ex_m_rd;
    reg [4:0]  i_m_wb_rd;
    reg        i_ex_m_reg_write;
    reg        i_m_wb_reg_write;
    reg [31:0] i_ex_m_alu_result;
    reg [31:0] i_m_wb_data_write;
    reg [31:0] i_id_ex_extended_beq_offset;
    reg        i_id_ex_alu_src;
    reg        i_id_ex_reg_dst;
    reg [3:0]  i_id_ex_alu_op;
    reg [4:0]  i_id_ex_function_code;

    wire [1:0] forward_a;
    wire [1:0] forward_b;
    wire [31:0] operando_a;
    wire [31:0] data_2;
    wire [31:0] operando_b;
    wire [4:0]  o_ex_m_rd;
    wire [5:0]  alu_control_signal;
    wire [31:0] o_ex_m_alu_result;

    // Instancia de la unidad de redireccionamiento
    FORWARDING_UNIT_EX forwarding_unit (
        .id_ex_rs(i_id_ex_rs),
        .id_ex_rt(i_id_ex_rt),
        .ex_mem_rd(i_ex_m_rd),
        .mem_wb_rd(i_m_wb_rd),
        .ex_mem_reg_write(i_ex_m_reg_write),
        .mem_wb_reg_write(i_m_wb_reg_write),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    // Multiplexores para los operandos
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

    initial begin
        // Simula una situación de forwarding desde WB
        // Supongamos que $v0 (registro 2) fue escrito en WB y ahora lo necesita la instrucción en EX
        i_id_ex_data_1 = 32'h00000000; // Valor original de $v0 (no usado por forwarding)
        i_id_ex_data_2 = 32'h00000003; // Valor original de $v1
        i_id_ex_rs = 2; // $v0
        i_id_ex_rt = 3; // $v1
        i_id_ex_rd = 4; // $a0
        i_ex_m_rd = 0; // No coincide, no hay forwarding desde EX/MEM
        i_m_wb_rd = 2; // $v0, coincide con rs
        i_ex_m_reg_write = 0;
        i_m_wb_reg_write = 1; // WB va a escribir en $v0
        i_ex_m_alu_result = 32'h12345678; // Valor en EX/MEM (no usado)
        i_m_wb_data_write = 32'hDEADBEEF; // Valor que debe ser redireccionado
        i_id_ex_extended_beq_offset = 32'h00000000;
        i_id_ex_alu_src = 0; // Usar data_2
        i_id_ex_reg_dst = 1; // Usar rd
        i_id_ex_alu_op = 4'b0010; // ADD
        i_id_ex_function_code = 6'b100000; // ADD

        #10;
        $display("forward_a = %b (esperado 10)", forward_a);
        $display("forward_b = %b (esperado 00)", forward_b);
        $display("operando_a = %h (esperado DEADBEEF)", operando_a);
        $display("operando_b = %h (esperado 00000003)", operando_b);
        $display("ALU result = %h", o_ex_m_alu_result);

        #10 $finish;
    end

endmodule