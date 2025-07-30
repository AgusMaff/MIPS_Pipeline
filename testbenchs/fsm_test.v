`timescale 1ns / 1ps

module tb_debugunit_pipeline;

    // Parámetros
    localparam NB_REG = 32;
    localparam NB_R_INT = 341;

    // Señales de reloj y reset
    reg clk = 0;
    reg reset = 1;

    // Señales para debug_unit <-> pipeline (outputs de debug_unit)
    wire [NB_REG-1:0] inst_data;
    wire [NB_REG-1:0] inst_addr;
    wire inst_mem_write_en;
    wire inst_mem_read_en;
    wire mips_reset;
    wire halt_wire;
    wire [NB_REG-1:0] reg_data_wire;
    wire [NB_REG-1:0] mem_data_wire;
    wire [NB_R_INT-1:0] latches_data_wire;
    wire idle_led;
    wire start_led;
    wire running_led;
    wire uart_tx_bit;

    // Instancia de PIPELINE
    PIPELINE pipeline_inst (
        .i_clk(clk),
        .i_reset(reset | mips_reset),
        .i_du_data(inst_data),
        .i_du_inst_addr_wr(inst_addr),
        .i_du_write_en(inst_mem_write_en),
        .i_du_read_en(inst_mem_read_en),
        .o_du_halt(halt_wire),
        .o_du_regs_mem_data(reg_data_wire),
        .o_du_mem_data(mem_data_wire),
        .o_du_if_id_data(latches_data_wire[340:277]),
        .o_du_id_ex_data(latches_data_wire[276:147]),
        .o_du_ex_m_data(latches_data_wire[146:71]),
        .o_du_m_wb_data(latches_data_wire[70:0])
    );

    // Instancia de debug_unit (usa solo los inputs definidos en tu código)
    reg tb_uart_rx_data_in = 0;

    debug_unit #(
        .NB_REG(NB_REG),
        .NB_R_INT(NB_R_INT)
    ) debug_unit_inst (
        .i_du_clk(clk),
        .i_du_reset(reset),
        .i_uart_rx_data_in(tb_uart_rx_data_in),
        .i_du_halt(halt_wire),
        .i_reg_data(reg_data_wire),
        .i_mem_data(mem_data_wire),
        .i_latches_data(latches_data_wire),

        .o_uart_tx_data_out(uart_tx_bit), // Ignorado
        .o_mips_inst_data(inst_data),
        .o_mips_inst_mem_addr_wr(inst_addr),
        .o_mips_inst_mem_write_en(inst_mem_write_en),
        .o_mips_inst_mem_read_en(inst_mem_read_en),
        .o_mips_reset(mips_reset),
        .o_tx_confirmation(), // Ignorado
        .o_rx_confirmation(), // Ignorado
        .o_idle_led(idle_led),        // Ignorado
        .o_start_led(start_led),       // Ignorado
        .o_running_led(running_led)      // Ignorado
    );

    // Registro para guardar los bits transmitidos por UART TX
    reg [9:0] tx_bits_log;
    integer tx_bit_cnt = 0;

    // Registro para guardar los bits recibidos por UART RX
    reg [9:0] rx_bits_log;
    integer rx_bit_cnt = 0;

    // Monitoreo de transmisión UART TX
    always @(posedge clk) begin
        $display("TX bit %0d: %b", tx_bit_cnt, uart_tx_bit);
    end

    // Monitoreo de recepción UART RX
    always @(posedge clk) begin
        $display("RX bit %0d: %b", rx_bit_cnt, tb_uart_rx_data_in);
    end

    task send_uart_byte;
        input [7:0] data;
        integer i;
        begin
            // Start bit (0)
            tb_uart_rx_data_in = 1'b0;
            rx_bits_log[rx_bit_cnt] = tb_uart_rx_data_in;
            rx_bit_cnt = rx_bit_cnt + 1;
            #104;

            // Data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                tb_uart_rx_data_in = data[i];
                rx_bits_log[rx_bit_cnt] = tb_uart_rx_data_in;
                rx_bit_cnt = rx_bit_cnt + 1;
                #104;
            end

            // Stop bit (1)
            tb_uart_rx_data_in = 1'b1;
            rx_bits_log[rx_bit_cnt] = tb_uart_rx_data_in;
            rx_bit_cnt = rx_bit_cnt + 1;
            #104;
        end
    endtask


    // Generador de clock
    always #5 clk = ~clk;

    // Secuencia de prueba
    initial begin
        $display("=== Testbench DebugUnit <-> PIPELINE ===");
        reset = 1;
        #20
        reset = 0;

        // Simular envio de comando START
         send_uart_byte(8'h02); // Comando START
         #200;

        // Simular envio de RESET
        // send_uart_byte(8'h0D); // Comando RESET
        // #200;

        // Esperar ejecución secuencial
        // #200;

        // Esperar a que el pipeline indique halt
        wait (halt_wire == 1);
        $display("Pipeline HALT detectado.");

        // Leer registros y memoria
        $display("Registros: %h", reg_data_wire);
        $display("Memoria: %h", mem_data_wire);

        $finish;
    end

endmodule