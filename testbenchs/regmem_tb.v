`timescale 1ns / 1ps

module regmem_tb;

    reg         clk;
    reg         reset;
    reg  [4:0]  rs;
    reg  [4:0]  rt;
    reg  [31:0] write_data;
    reg  [4:0]  reg_addr;
    reg         write_enable;
    wire [31:0] data_1;
    wire [31:0] data_2;

    // Instancia del módulo REGMEM
    REGMEM dut (
        .clk(clk),
        .reset(reset),
        .rs(rs),
        .rt(rt),
        .write_data(write_data),
        .reg_addr(reg_addr),
        .write_enable(write_enable),
        .data_1(data_1),
        .data_2(data_2)
    );

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // Inicialización
        reset = 1;
        write_enable = 0;
        write_data = 0;
        reg_addr = 0;
        rs = 0;
        rt = 0;
        #10;
        reset = 0;

        // Escribir 0xAAAA_BBBB en el registro 1
        @(negedge clk);
        write_enable = 1; reg_addr = 5'd1; write_data = 32'hAAAA_BBBB;
        @(negedge clk);
        write_enable = 0;

        // Escribir 0x1234_5678 en el registro 2
        @(negedge clk);
        write_enable = 1; reg_addr = 5'd2; write_data = 32'h1234_5678;
        @(negedge clk);
        write_enable = 0;

        // Leer registros 1 y 2
        rs = 5'd1;
        rt = 5'd2;
        #10;
        $display("Lectura: data_1 (reg1) = %h, data_2 (reg2) = %h", data_1, data_2);

        // Escribir 0xDEADBEEF en el registro 10
        @(negedge clk);
        write_enable = 1; reg_addr = 5'd10; write_data = 32'hDEAD_BEEF;
        @(negedge clk);
        write_enable = 0;

        // Leer registros 10 y 1
        rs = 5'd10;
        rt = 5'd1;
        #10;
        $display("Lectura: data_1 (reg10) = %h, data_2 (reg1) = %h", data_1, data_2);

        $finish;
    end

endmodule