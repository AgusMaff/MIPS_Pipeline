`timescale 1ns / 1ps

module insmem_tb;

    reg         clk;
    reg         reset;
    reg         write_en;
    reg         read_en;
    reg  [31:0] data;
    reg  [31:0] addr;
    reg  [31:0] addr_wr;
    wire [31:0] o_instruction;

    // Instancia del módulo INSMEM
    INSMEM dut (
        .clk(clk),
        .reset(reset),
        .write_en(write_en),
        .read_en(read_en),
        .data(data),
        .addr(addr),
        .addr_wr(addr_wr),
        .instruction(o_instruction)
    );

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // Inicialización
        reset = 1;
        write_en = 0;
        read_en = 0;
        data = 0;
        addr = 0;
        addr_wr = 0;
        #12;
        reset = 0;

        // Escribir instrucción 1 en la dirección 0
        @(negedge clk);
        data = 32'h20080005; addr_wr = 32'd0; write_en = 1;
        @(posedge clk);
        @(negedge clk); write_en = 0;

        // Escribir instrucción 2 en la dirección 4
        data = 32'h2009000A; addr_wr = 32'd4; write_en = 1;
        @(posedge clk);
        @(negedge clk); write_en = 0;

        // Escribir instrucción 3 en la dirección 8
        data = 32'h200A000F; addr_wr = 32'd8; write_en = 1;
        @(posedge clk);
        @(negedge clk); write_en = 0;

        // Leer instrucción 1
        read_en = 1; addr = 32'd0;
        #10;
        $display("Instrucción en 0: %h", o_instruction);

        // Leer instrucción 2
        addr = 32'd4;
        #10;
        $display("Instrucción en 4: %h", o_instruction);

        // Leer instrucción 3
        addr = 32'd8;
        #10;
        $display("Instrucción en 8: %h", o_instruction);

        // Leer dirección vacía
        addr = 32'd12;
        #10;
        $display("Instrucción en 12: %h", o_instruction);

        $finish;
    end

endmodule