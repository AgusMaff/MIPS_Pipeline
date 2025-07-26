`timescale 1ns / 1ps

module tb_uart_rx;

    reg clk = 0;
    reg reset = 1;
    reg rx = 1;
    wire s_tick;
    wire rx_done_tick;
    wire [7:0] dout;

    // Parámetros del generador de baudrate
    localparam NB = 8;
    localparam M = 2; // Ajusta según tu clock y baudrate

    // Instancia del generador de baudrate
    baud_rate_gen #(
        .NB(NB),
        .M(M)
    ) baud_gen (
        .clk(clk),
        .reset(reset),
        .max_tick(s_tick),
        .q()
    );

    // Instancia del receptor UART
    uart_rx uut (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .s_tick(s_tick),
        .rx_done_tick(rx_done_tick),
        .dout(dout)
    );

    // Generación de clock
    always #5 clk = ~clk; // 100 MHz

    // Tarea para enviar un byte UART (start bit, 8 bits, stop bit)
    task uart_send_byte(input [7:0] data);
        integer i;
        begin
            rx = 0; // Start bit
            repeat(16) @(posedge s_tick); // Espera SB_TICK ticks

            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                repeat(16) @(posedge s_tick); // Espera SB_TICK ticks por cada bit
            end

            rx = 1; // Stop bit
            repeat(16) @(posedge s_tick); // Espera SB_TICK ticks
        end
    endtask

    initial begin
        // Reset inicial
        #100;
        reset = 0;
        #50;

        // Enviar byte 0xA5
        $display("Enviando byte 0xA5...");
        uart_send_byte(8'h02);
        // Esperar a que rx_done_tick se active
        wait(rx_done_tick);
        $display("Byte recibido: %02X", dout);
        #10000
        // Enviar byte 0x3C
        $display("Enviando byte 0x3C...");
        uart_send_byte(8'h3C);
        wait(rx_done_tick);
        $display("Byte recibido: %02X", dout);

        #20000
        $finish;
    end

endmodule