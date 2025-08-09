`timescale 1ns / 1ps

module load_test;

    reg i_clk;
    reg i_reset;
    reg [31:0] i_du_data;
    reg [31:0] i_du_addr_wr;
    reg i_du_write_en;
    reg i_du_read_en;

    wire halt_wire;
    wire [31:0] reg_data_wire;
    wire [31:0] mem_data_wire;
    wire [7:0] inst_to_load;
    wire [7:0] addr_to_load;
    reg [4:0] reg_addr_to_read;
    reg [7:0] mem_addr_to_read;
    wire inst_mem_write_enable;
    wire inst_mem_read_enable;
    wire reset_from_du;

    wire [31:0] if_id_pc_plus_4;
    wire [31:0] if_id_instruction;

    wire [31:0] id_ex_data_1, id_ex_data_2;
    wire [4:0]  id_ex_rs, id_ex_rt, id_ex_rd;
    wire [5:0]  id_ex_function_code;
    wire [31:0] extended_beq_offset;
    wire id_ex_reg_dest, id_ex_mem_read, id_ex_mem_write, id_ex_reg_write, id_ex_alu_src, id_ex_mem_to_reg;
    wire [3:0] id_ex_alu_op;
    wire [2:0] id_ex_bhw_type;

    wire [4:0] ex_m_rd;
    wire ex_m_reg_write, ex_m_mem_read, ex_m_mem_write, ex_m_mem_to_reg;
    wire [31:0] ex_m_alu_result, ex_m_write_data;
    wire [2:0] ex_m_bhw_type;

    wire [31:0] m_wb_read_data, m_wb_alu_result;
    wire m_wb_reg_write;
    wire [4:0] m_wb_rd;

    PIPELINE pipeline (
        .i_clk(i_clk),
        .i_reset(i_reset), // Reset signal from debug unit
        .i_du_data(i_du_data),
        .i_du_inst_addr_wr(i_du_addr_wr),
        .i_du_mem_addr(mem_addr_to_read),
        .i_du_reg_addr(reg_addr_to_read),
        .i_du_write_en(i_du_write_en),
        .i_du_read_en(i_du_read_en),

        .o_du_halt(halt_wire), // Señal de parada (HALT)
        .o_du_if_id_pc_plus_4(if_id_pc_plus_4),
        .o_du_if_id_instruction(if_id_instruction),

        .o_du_id_ex_data_1(id_ex_data_1),
        .o_du_id_ex_data_2(id_ex_data_2),
        .o_du_id_ex_rs(id_ex_rs),
        .o_du_id_ex_rt(id_ex_rt),
        .o_du_id_ex_rd(id_ex_rd),
        .o_du_id_ex_function_code(id_ex_function_code),
        .o_du_id_ex_extended_beq_offset(extended_beq_offset),
        .o_du_id_ex_reg_dest(id_ex_reg_dest),
        .o_du_id_ex_mem_read(id_ex_mem_read),
        .o_du_id_ex_mem_write(id_ex_mem_write),
        .o_du_id_ex_reg_write(id_ex_reg_write),
        .o_du_id_ex_alu_src(id_ex_alu_src),
        .o_du_id_ex_mem_to_reg(id_ex_mem_to_reg),
        .o_du_id_ex_alu_op(id_ex_alu_op),
        .o_du_id_ex_bhw_type(id_ex_bhw_type),

        .o_du_ex_m_rd(ex_m_rd),
        .o_du_ex_m_reg_write(ex_m_reg_write),
        .o_du_ex_m_mem_read(ex_m_mem_read),
        .o_du_ex_m_mem_write(ex_m_mem_write),
        .o_du_ex_m_mem_to_reg(ex_m_mem_to_reg),
        .o_du_ex_m_alu_result(ex_m_alu_result),
        .o_du_ex_m_write_data(ex_m_write_data),
        .o_du_ex_m_bhw_type(ex_m_bhw_type),

        .o_du_m_wb_read_data(m_wb_read_data),
        .o_du_m_wb_alu_result(m_wb_alu_result),
        .o_du_m_wb_reg_write(m_wb_reg_write),
        .o_du_m_wb_rd(m_wb_rd),

        .o_du_regs_mem_data(reg_data_wire),
        .o_du_mem_data(mem_data_wire)
    );

    // Generador de clock
    initial i_clk = 0;
    always #5 i_clk = ~i_clk;

    // Test sequence
    initial begin
        // Reset y señales iniciales
        i_reset = 1;
        i_du_write_en = 0;
        i_du_read_en = 0;
        i_du_data = 0;
        i_du_addr_wr = 0;
        #12;
        i_reset = 0;

        // Cargar instrucción ADDI en la memoria de instrucciones
        @(negedge i_clk);
        i_du_write_en = 1;
        i_du_read_en = 0;
        i_du_data = 32'h2443FFFF; // ADDIU $v0, $v1, 65535
        i_du_addr_wr = 0;
        //@(negedge i_clk);
        //i_du_write_en = 1;
        //i_du_read_en = 0;
        //i_du_data = 32'hAC030004; // SW $v1 , 4($zero)
        //i_du_addr_wr = 4;
        @(negedge i_clk);
        i_du_write_en = 1;
        i_du_read_en = 0;
        i_du_data = 32'hFC000000; // HALT
        i_du_addr_wr = 4;
        @(negedge i_clk);
        i_du_write_en = 0;
        i_du_read_en = 1;
        // Esperar a que la instrucción pase por el pipeline
        repeat(16) @(posedge i_clk);
        @(negedge i_clk);
        i_du_write_en = 0;
        i_du_read_en = 0;
        mem_addr_to_read = 8'd0;
        @(negedge i_clk);
        i_du_write_en = 0;
        i_du_read_en = 0;
        mem_addr_to_read = 8'd4;
        @(negedge i_clk);
        i_du_write_en = 0;
        i_du_read_en = 0;
        mem_addr_to_read = 8'd8;

        @(negedge i_clk);
        i_du_write_en = 0;
        i_du_read_en = 0;
        @(negedge i_clk);
        i_du_addr_wr = 8'h09;

        repeat(16) @(posedge i_clk);
        $finish;
    end

endmodule