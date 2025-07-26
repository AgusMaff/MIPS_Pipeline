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
    wire [75:0]  w_EX_M ;
    wire [70:0]  w_M_WB ;
    wire [31:0] reg_data_wire;
    wire [31:0] mem_data_wire;

    PIPELINE pipeline (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_du_data(i_du_data),
        .i_du_inst_addr_wr(i_du_addr_wr),
        .i_du_write_en(i_du_write_en),
        .i_du_read_en(i_du_read_en),
    
        .o_du_halt(halt_wire),
        .o_du_if_id_data(w_IF_ID),
        .o_du_id_ex_data(w_ID_EX),
        .o_du_ex_m_data(w_EX_M),
        .o_du_m_wb_data(w_M_WB),
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
        i_du_data = 32'b001001_00010_00011_1111111111111111; // ADDI $v0, $v1, 65535
        i_du_addr_wr = 0;
        @(negedge i_clk);
        i_du_write_en = 1;
        i_du_read_en = 0;
        i_du_data = 32'b101011_00000_00011_0000000000000111; // SW $zero, $v1, 7
        i_du_addr_wr = 4;
        @(negedge i_clk);
        i_du_write_en = 1;
        i_du_read_en = 0;
        i_du_data = 32'b100000_00000_00100_0000000000000111; // LB $zero, $a0, 7
        i_du_addr_wr = 8;
        @(negedge i_clk);
        i_du_write_en = 1;
        i_du_read_en = 0;
        i_du_data = 32'b100001_00000_00101_0000000000000111; // LH $zero, $a1, 7
        i_du_addr_wr = 12;
        @(negedge i_clk);
        i_du_write_en = 1;
        i_du_read_en = 0;
        i_du_data = 32'b100011_00000_00111_0000000000000111; // LW $zero, $a2, 7
        i_du_addr_wr = 16;
        @(negedge i_clk);
        i_du_write_en = 1;
        i_du_read_en = 0;
        i_du_data = 32'b100100_00000_01001_0000000000000111; // LBU $zero, $a3, 7
        i_du_addr_wr = 20;
        @(negedge i_clk);
        i_du_write_en = 1;
        i_du_read_en = 0;
        i_du_data = 32'b111111_00000_00000_0000000000000000; // HALT
        i_du_addr_wr = 24;
        @(negedge i_clk);
        i_du_write_en = 1;
        i_du_read_en = 0;
        i_du_data = 32'b100101_00000_01010_0000000000000111; // LHU $zero, $a4, 7
        i_du_addr_wr = 28;
        @(negedge i_clk);
        i_du_write_en = 1;
        i_du_read_en = 0;
        i_du_data = 32'b100111_00000_01011_0000000000000111; // LWU $zero, $a5, 7
        i_du_addr_wr = 32;
        @(negedge i_clk);
        i_du_write_en = 1;
        i_du_read_en = 0;
        i_du_data = 32'b000000_01011_01010_01100_00000_100010; // SUB $a5, $a4, $a6
        i_du_addr_wr = 36;
        @(negedge i_clk);
        i_du_write_en = 0;
        i_du_read_en = 1;
        // Esperar a que la instrucción pase por el pipeline
        repeat(16) @(posedge i_clk);

        @(negedge i_clk);
        i_du_write_en = 0;
        i_du_read_en = 0;
        @(negedge i_clk);
        i_du_addr_wr = 32'h09;

        repeat(16) @(posedge i_clk);

        $finish;
    end

endmodule