`timescale 1ns / 1ps

module if_pc_only_tb;

    // Entradas
    reg         clk;
    reg         reset;
    reg         write_en;
    reg         read_en;
    reg  [31:0] data;
    reg  [31:0] addr_wr;
    reg  [31:0] beq_dir;
    reg         stall;
    reg         pcsrc;
    reg         jump;

    // Salidas
    wire [31:0] pc_plus_4;
    wire [31:0] instruction;

    // Instancia del módulo IF
    IF dut (
        .i_clk(clk),
        .i_reset(reset),
        .i_stall(stall),
        .i_pcsrc(pcsrc),
        .i_jump(jump),
        .i_beq_dir(beq_dir),
        .i_write_en(write_en),
        .i_read_en(read_en),
        .i_data(data),
        .i_addr_wr(addr_wr),
        .o_pc_plus_4(pc_plus_4),
        .o_instruction(instruction)
    );

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Proceso de prueba
    initial begin
        // Inicialización
        reset = 1; stall = 0; pcsrc = 0; jump = 0;
        write_en = 0; read_en = 0; data = 0; addr_wr = 0; beq_dir = 0;
        #12;
        reset = 0;

        // Escribir instrucciones (agrega más para probar saltos)
        @(negedge clk); data = 32'h20080005; addr_wr = 32'd0; write_en = 1;
        @(posedge clk); @(negedge clk); write_en = 0;
        data = 32'h2009000A; addr_wr = 32'd4; write_en = 1;
        @(posedge clk); @(negedge clk); write_en = 0;
        data = 32'h200A000F; addr_wr = 32'd8; write_en = 1;
        @(posedge clk); @(negedge clk); write_en = 0;
        data = 32'h200B0014; addr_wr = 32'd12; write_en = 1;
        @(posedge clk); @(negedge clk); write_en = 0;
        data = 32'h200C0019; addr_wr = 32'd16; write_en = 1;
        @(posedge clk); @(negedge clk); write_en = 0;

        // Leer instrucciones normalmente
        read_en = 1;
        #30;

        // Simular salto BEQ (pcsrc=1): salta a dirección 12
        @(negedge clk);
        beq_dir = 32'd12;
        pcsrc = 1;
        #10;
        pcsrc = 0;

        // Deja correr algunos ciclos
        #30;

        // Simular salto JUMP (jump=1): salta a dirección 16
        @(negedge clk);
        jump = 1;
        // El valor de jump_dir lo calcula internamente el IF, así que solo activamos jump
        #10;
        jump = 0;

        // Deja correr algunos ciclos
        #40;

        $finish;
    end

    // Monitor para ver el avance del PC y la instrucción
    initial begin
        $display("Tiempo | Reset | PC+4      | Instruction");
        $monitor("%4dns |   %b   | %h | %h", $time, reset, pc_plus_4, instruction);
    end

endmodule