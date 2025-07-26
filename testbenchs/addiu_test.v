`timescale 1ns / 1ps

module addiu_test;

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

    // Clock generator
    initial i_clk = 0;
    always #5 i_clk = ~i_clk;

    // Monitor de señales de debug
    initial begin
        $display("Tiempo | PC+4/IF | IF/ID | ID/EX | EX/MEM | MEM/WB | RegData | MemData | HALT");
        $monitor("%4t | %h | %h | %h | %h | %h | %h | %h | %b",
            $time, w_IF_ID[63:32], w_IF_ID[31:0], w_ID_EX[129:98], w_EX_M[75:44], w_M_WB[70:39], reg_data_wire, mem_data_wire, halt_wire);
    end

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

        // Cargar instrucción ADDIU en la memoria de instrucciones (opcode 0x09)
        // Ejemplo: ADDIU $t0, $zero, 5  => 001001 00000 01000 0000000000000101
        @(negedge i_clk);
        i_du_write_en = 1;
        i_du_read_en = 0;
        i_du_data = 32'b001001_00001_01000_0000000000000101; // ADDIU $t0, $zero, 5
        i_du_addr_wr = 0;
        @(negedge i_clk);
        i_du_write_en = 0;
        i_du_read_en = 1;

        // Leer el registro $t0 (número 8) usando la interfaz de debug
        @(negedge i_clk);
        i_du_addr_wr = 8; // $t0
        @(negedge i_clk);
        i_du_read_en = 0;

        // Esperar a que la instrucción pase por el pipeline
        repeat(10) @(posedge i_clk);

        // Leer el registro $t0 nuevamente
        i_du_read_en = 1;
        i_du_addr_wr = 8;
        @(negedge i_clk);
        i_du_read_en = 0;

        // Leer memoria de datos en la dirección 0
        @(negedge i_clk);
        i_du_read_en = 1;
        i_du_addr_wr = 0;
        @(negedge i_clk);
        i_du_read_en = 0;

        // Esperar algunos ciclos y finalizar
        repeat(10) @(posedge i_clk);

        $finish;
    end

endmodule