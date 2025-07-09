`timescale 1ns / 1ps

module ex_addi_tb;

    reg clk;
    reg reset;
    reg [31:0] id_ex_data_1;              // Primer operando (valor de $t0)
    reg [31:0] id_ex_data_2;              // Segundo operando (no usado en addi)
    reg [4:0]  id_ex_rs;
    reg [4:0]  id_ex_rt;
    reg [4:0]  id_ex_rd;
    reg [5:0]  id_ex_function_code;
    reg [31:0] id_ex_extended_beq_offset; // Inmediato extendido (5)
    reg        id_ex_reg_dst;
    reg        id_ex_alu_src;
    reg [3:0]  id_ex_alu_op;
    reg        id_ex_mem_read;
    reg        id_ex_mem_write;
    reg        id_ex_mem_to_reg;
    reg        id_ex_reg_write;
    reg [31:0] m_wb_data_write;
    reg [31:0] ex_m_alu_result;
    reg        ex_m_reg_write;
    reg [4:0]  ex_m_rd;
    reg        m_wb_reg_write;
    reg [4:0]  m_wb_rd;

    wire [31:0] ex_m_alu_result_out;
    wire [31:0] ex_m_write_data_out;
    wire [4:0]  ex_m_rd_out;
    wire        ex_m_mem_read_out;
    wire        ex_m_mem_write_out;
    wire        ex_m_mem_to_reg_out;
    wire        ex_m_reg_write_out;

    // Instancia de la etapa EX
    EX uut (
        .i_clk(clk),
        .i_reset(reset),
        .i_id_ex_data_1(id_ex_data_1),
        .i_id_ex_data_2(id_ex_data_2),
        .i_id_ex_rs(id_ex_rs),
        .i_id_ex_rt(id_ex_rt),
        .i_id_ex_rd(id_ex_rd),
        .i_id_ex_function_code(id_ex_function_code),
        .i_id_ex_extended_beq_offset(id_ex_extended_beq_offset),
        .i_id_ex_reg_dst(id_ex_reg_dst),
        .i_id_ex_alu_src(id_ex_alu_src),
        .i_id_ex_alu_op(id_ex_alu_op),
        .i_id_ex_mem_read(id_ex_mem_read),
        .i_id_ex_mem_write(id_ex_mem_write),
        .i_id_ex_mem_to_reg(id_ex_mem_to_reg),
        .i_id_ex_reg_write(id_ex_reg_write),
        .i_m_wb_data_write(m_wb_data_write),
        .i_ex_m_alu_result(ex_m_alu_result),
        .i_ex_m_reg_write(ex_m_reg_write),
        .i_ex_m_rd(ex_m_rd),
        .i_m_wb_reg_write(m_wb_reg_write),
        .i_m_wb_rd(m_wb_rd),
        .o_ex_m_alu_result(ex_m_alu_result_out),
        .o_ex_m_write_data(ex_m_write_data_out),
        .o_ex_m_rd(ex_m_rd_out),
        .o_ex_m_mem_read(ex_m_mem_read_out),
        .o_ex_m_mem_write(ex_m_mem_write_out),
        .o_ex_m_mem_to_reg(ex_m_mem_to_reg_out),
        .o_ex_m_reg_write(ex_m_reg_write_out)
    );

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // Inicialización
        reset = 1;
        id_ex_data_1 = 0; // $t0 = 0
        id_ex_data_2 = 0;
        id_ex_rs = 8;     // $t0
        id_ex_rt = 9;     // $t1
        id_ex_rd = 9;     // $t1
        id_ex_function_code = 6'bxxxxxx; // No importa para ADDI
        id_ex_extended_beq_offset = 5;   // Inmediato = 5
        id_ex_reg_dst = 0; // Para ADDI, rt es destino
        id_ex_alu_src = 1; // Usar inmediato
        id_ex_alu_op = 4'b1000; // ADDI
        id_ex_mem_read = 0;
        id_ex_mem_write = 0;
        id_ex_mem_to_reg = 0;
        id_ex_reg_write = 1;
        m_wb_data_write = 0;
        ex_m_alu_result = 0;
        ex_m_reg_write = 0;
        ex_m_rd = 0;
        m_wb_reg_write = 0;
        m_wb_rd = 0;

        #10;
        reset = 0;

        #10;
        $display("Resultado esperado: 5");
        $display("ALU result: %d", ex_m_alu_result_out);
        $finish;
    end

endmodule