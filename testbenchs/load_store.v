`timescale 1ns / 1ps

module load_test;

    reg i_clk;
    reg i_reset;
    reg [31:0] i_du_data;
    reg [31:0] i_du_addr_wr;
    reg i_du_write_en;
    reg i_du_read_en;

    wire halt_wire;
    wire [63:0] w_IF_ID;
    wire [129:0] w_ID_EX;
    wire [75:0]  w_EX_M;
    wire [70:0]  w_M_WB;
    wire [31:0] reg_data_wire;
    wire [31:0] mem_data_wire;
    reg  [31:0] mem_addr_to_read;
    reg [31:0] reg_addr_to_read;

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
        .o_du_if_id_data(w_IF_ID), // Datos de la etapa IF/ID
        .o_du_id_ex_data(w_ID_EX), // Datos de la etapa ID/EX
        .o_du_ex_m_data(w_EX_M), // Datos de la etapa EX/MEM
        .o_du_m_wb_data(w_M_WB), // Datos de la etapa MEM/WB
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
        i_du_data = 32'h24430001; // ADDIU $v0, $v1, 65535
        i_du_addr_wr = 0;
        @(negedge i_clk);
        i_du_write_en = 1;
        i_du_read_en = 0;
        i_du_data = 32'hAC030004; // SW $v1 , 4($zero)
        i_du_addr_wr = 4;
        @(negedge i_clk);
        i_du_write_en = 1;
        i_du_read_en = 0;
        i_du_data = 32'hFC000000; // HALT
        i_du_addr_wr = 8;
        @(negedge i_clk);
        i_du_write_en = 0;
        i_du_read_en = 1;
        // Esperar a que la instrucción pase por el pipeline
        repeat(16) @(posedge i_clk);
        @(negedge i_clk);
        i_du_write_en = 0;
        i_du_read_en = 0;
        mem_addr_to_read = 32'd0;
        @(negedge i_clk);
        i_du_write_en = 0;
        i_du_read_en = 0;
        mem_addr_to_read = 32'd4;
        @(negedge i_clk);
        i_du_write_en = 0;
        i_du_read_en = 0;
        mem_addr_to_read = 32'd8;

        @(negedge i_clk);
        i_du_write_en = 0;
        i_du_read_en = 0;
        @(negedge i_clk);
        i_du_addr_wr = 32'h09;

        repeat(16) @(posedge i_clk);

        $finish;
    end

endmodule