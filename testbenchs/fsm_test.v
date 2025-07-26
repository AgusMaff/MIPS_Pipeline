`timescale 1ns / 1ps

module tb_debug_unit_rx;

    reg clk = 0;
    reg reset = 1;
    reg uart_rx = 1;
    reg halt = 0;
    reg [31:0] reg_data = 32'hAABBCCDD;
    reg [31:0] mem_data = 32'h11223344;
    reg [340:0] latches_data = {341{1'b0}};

    wire uart_tx;
    wire [31:0] mips_inst_data;
    wire [31:0] mips_inst_mem_addr_wr;
    wire mips_inst_mem_write_en;
    wire mips_inst_mem_read_en;
    wire mips_reset;
    wire tx_confirmation;
    wire rx_confirmation;
    wire idle_led;
    wire start_led;

    // Clock generation
    always #5 clk = ~clk; // 100 MHz

    debug_unit uut (
        .i_du_clk(clk),
        .i_du_reset(reset),
        .i_uart_rx_data_in(uart_rx),
        .i_du_halt(halt),
        .i_reg_data(reg_data),
        .i_mem_data(mem_data),
        .i_latches_data(latches_data),
        .o_uart_tx_data_out(uart_tx),
        .o_mips_inst_data(mips_inst_data),
        .o_mips_inst_mem_addr_wr(mips_inst_mem_addr_wr),
        .o_mips_inst_mem_write_en(mips_inst_mem_write_en),
        .o_mips_inst_mem_read_en(mips_inst_mem_read_en),
        .o_mips_reset(mips_reset),
        .o_tx_confirmation(tx_confirmation),
        .o_rx_confirmation(rx_confirmation),
        .o_idle_led(idle_led),
        .o_start_led(start_led)
    );

    // Simula la llegada de un byte UART (start bit + 8 bits + stop bit)
    task uart_send_byte(input [7:0] data);
        integer i;
        begin
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = data[i];
                #(16*10);
            end
        end
    endtask

    initial begin
        // Reset inicial
        #100;
        reset = 0;

        // Verifica que arranca en IDLE
        $display("Estado inicial: IDLE_LED=%b START_LED=%b", idle_led, start_led);

        // Simula llegada de comando LOAD_INSTRUCTION (0x02)
        uart_rx = 0; // Start bit
        #(16*10);
        uart_send_byte(8'h02);
        uart_rx = 1; // Stop bit
        #(16*10);
        #500;

        // Verifica que pasa a START (debería prender el LED de start)
        $display("Después de recibir comando: IDLE_LED=%b START_LED=%b", idle_led, start_led);

        // Simula llegada de primer byte de instrucción (ejemplo: 0x24)
        uart_rx = 0; // Start bit
        #(16*10);
        uart_send_byte(8'h24);
        uart_rx = 1; // Stop bit
        #(16*10);
        #500;

        // Verifica que pasa a LOAD_INSTRUCTION (debería prender RX confirmation y START_LED)
        $display("Después de recibir primer byte de instrucción: IDLE_LED=%b START_LED=%b RX_CONFIRMATION=%b", idle_led, start_led, rx_confirmation);

        $finish;
    end

endmodule