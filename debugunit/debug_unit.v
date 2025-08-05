module debug_unit 
#(
    parameter NB_REG  = 32,
    parameter NB_R_INT= 341,
    parameter DBIT    = 8 ,
    parameter SB_TICK = 16,
    parameter DVSR    = 163,
    parameter DVSR_BITS= 8  ,
    parameter FIFO_W  = 5  
) 
(
    input                 i_du_clk,
    input                 i_du_reset,
    input                 i_uart_rx_data_in,
    input                 i_du_halt,
    input  [NB_REG-1:0]   i_reg_data,
    input  [NB_REG-1:0]   i_mem_data,
    input  [NB_R_INT-1:0] i_latches_data,

    output                o_uart_tx_data_out,
    output [NB_REG-1:0]   o_mips_inst_data,
    output [NB_REG-1:0]   o_mips_inst_mem_addr_wr,
    output                o_mips_inst_mem_write_en,
    output                o_mips_inst_mem_read_en,
    output                o_mips_reset,
    output [4:0]          o_du_reg_addr_sel,
    output [31:0]         o_du_mem_addr_sel,
    output                o_idle_led,
    output                o_start_led, 
    output                o_running_led // LED indicating the system is running
);

// UART interface
wire du_rx_buffer_empty;
wire du_tx_buffer_full;
wire [DBIT-1:0] du_data_readed_from_rx_fifo;
wire [DBIT-1:0] du_data_to_write_on_tx_fifo;
wire du_read_uart_signal, du_write_uart_signal;

UART #(
    .DBIT     (DBIT   ),      
    .SB_TICK  (SB_TICK),      
    .DVSR     (DVSR   ),      
    .DVSR_BITS (DVSR_BITS),      
    .FIFO_W   (FIFO_W)       
) u_uart (
    .clk     (i_du_clk),  
    .reset   (i_du_reset),  
    .rd_uart (du_read_uart_signal),  
    .wr_uart (du_write_uart_signal),  
    .rx      (i_uart_rx_data_in),  
    .w_data  (du_data_to_write_on_tx_fifo),  
    .tx_full (du_tx_buffer_full),  
    .rx_empty(du_rx_buffer_empty),  
    .tx      (o_uart_tx_data_out),  
    .r_data  (du_data_readed_from_rx_fifo)
);

// Estados
localparam IDLE                 = 5'b00001;
localparam START                = 5'b00010;
localparam LOAD_INSTRUCTION     = 5'b00011;
localparam WRITE_INST           = 5'b00101;
localparam RUN                  = 5'b00110;
localparam SEND_REG_DATA        = 5'b01000;
localparam WAIT_RX              = 5'b01011;
localparam WAIT_TX              = 5'b01100;
localparam RESET                = 5'b01101;
localparam RECEIVE_REG_ADDR     = 5'b10000;
localparam SEND_MEM_DATA        = 5'b10001;
localparam RECEIVE_MEM_ADDR     = 5'b10010;
localparam SEND_LATCHES         = 5'b10011;
localparam WAIT_LATCH_ACK       = 5'b10100;

// Comandos UART
localparam LOAD_INSTRUCTION_CMD = 8'h02;
localparam RUN_CMD              = 8'h05;
localparam RESET_CMD            = 8'h0C;
localparam READ_REG_CMD         = 8'h06;
localparam READ_MEM_CMD         = 8'h07;
localparam READ_LATCHES_CMD     = 8'h08;
localparam HALT_CODE            = 32'hFC000000;

// Registros
reg [4:0] state, next_state;
reg [4:0] waiting_state, next_waiting_state;
reg [1:0] counter, next_counter;
reg [7:0] latches_bytes_count, next_latches_bytes_count;
reg [NB_REG-1:0] inst_to_mem, next_inst_to_mem; 
reg [NB_REG-1:0] addr_inst, next_addr_inst; 
reg [DBIT-1:0] data_to_tx, next_data_to_tx; 
reg idle_led, start_led, running_led;

// Señales de control
reg read_uart_reg, write_uart_reg, write_mem_reg, read_mem_reg, enable_reg, reset_mips_reg;

// Registro de estado
always @(posedge i_du_clk) begin
    if (i_du_reset) begin
        state <= IDLE;
        waiting_state <= IDLE;
        counter <= 2'b00;
        inst_to_mem <= 0;
        addr_inst <= 0;
        latches_bytes_count <= 0;
    end
    else begin
        state <= next_state;
        waiting_state <= next_waiting_state;
        counter <= next_counter;
        inst_to_mem <= next_inst_to_mem;
        addr_inst <= next_addr_inst;
        latches_bytes_count <= next_latches_bytes_count;
    end
end

// Lógica de próximo estado
always @(*) begin  
    next_state = state;
    next_counter = counter;
    next_addr_inst = addr_inst;
    next_inst_to_mem = inst_to_mem;
    next_waiting_state = waiting_state;
    next_data_to_tx = data_to_tx;
    next_latches_bytes_count = latches_bytes_count;
    
    case (state)
        IDLE: begin
            next_addr_inst = 0;
            next_counter = 0;
            if (!du_rx_buffer_empty) begin
                next_state = START;
            end
        end
        
        START: begin
            if (du_rx_buffer_empty) begin
                next_state = WAIT_RX;
                next_waiting_state = START;
            end
            else if (du_data_readed_from_rx_fifo == LOAD_INSTRUCTION_CMD) begin
                next_state = LOAD_INSTRUCTION;
            end
            else if (du_data_readed_from_rx_fifo == RUN_CMD) begin
                next_state = RUN;
            end
            else if (du_data_readed_from_rx_fifo == READ_REG_CMD) begin
                next_state = RECEIVE_REG_ADDR;
            end else if (du_data_readed_from_rx_fifo == READ_MEM_CMD) begin
                next_state = RECEIVE_MEM_ADDR;
            end
            else if (du_data_readed_from_rx_fifo == READ_LATCHES_CMD) begin
                next_state = SEND_LATCHES;
            end
            else if (du_data_readed_from_rx_fifo == RESET_CMD) begin
                next_state = RESET;
            end
            else begin
                next_state = IDLE;
            end
        end
        
        LOAD_INSTRUCTION: begin
            if (du_rx_buffer_empty) begin
                next_state = WAIT_RX;
                next_waiting_state = LOAD_INSTRUCTION;
            end
            else begin
                next_inst_to_mem = {inst_to_mem[23:0], du_data_readed_from_rx_fifo};
                next_counter = counter + 1;
                
                if (counter == 2'b11) begin
                    next_counter = 0;
                    next_state = WRITE_INST;
                end
                else begin
                    next_state = LOAD_INSTRUCTION;
                end
            end
        end
        
        WRITE_INST: begin
            if (inst_to_mem == HALT_CODE) begin
                next_state = START;
            end
            else begin
                next_addr_inst = addr_inst + 4;
                next_state = LOAD_INSTRUCTION;
            end
        end
        
        RUN: begin
            if (i_du_halt) begin
                // Cuando termina la ejecución, empieza a enviar datos
                next_counter = 0;
                next_addr_inst = 0;
                next_state = IDLE;
            end
        end

        RECEIVE_REG_ADDR: begin
            if (du_rx_buffer_empty) begin
                next_state = WAIT_RX;
                next_waiting_state = RECEIVE_REG_ADDR;
            end
            else begin
                next_addr_inst = du_data_readed_from_rx_fifo[4:0]; // Dirección del registro a leer
                next_state = SEND_REG_DATA; // Espera para enviar los datos del registro
                next_counter = 0; // Reiniciar el contador
            end
        end
        
        SEND_REG_DATA: begin
            if (du_tx_buffer_full) begin
                next_state = WAIT_TX;
                next_waiting_state = SEND_REG_DATA;
            end
            else begin
                next_counter = counter + 1;
                
                if (counter == 2'b11) begin
                    next_counter = 0;
                    next_state = IDLE;
                end
            end
        end

        RECEIVE_MEM_ADDR: begin
            if (du_rx_buffer_empty) begin
                next_state = WAIT_RX;
                next_waiting_state = RECEIVE_MEM_ADDR;
            end
            else begin
                next_addr_inst = du_data_readed_from_rx_fifo[7:0]; // Dirección de memoria a leer
                next_state = SEND_MEM_DATA; // Espera para leer la memoria
                next_counter = 0; // Reiniciar el contador
            end
        end

        SEND_MEM_DATA: begin
            if (du_tx_buffer_full) begin
                next_state = WAIT_TX;
                next_waiting_state = SEND_MEM_DATA;
            end
            else begin
                next_counter = counter + 1;
                
                if (counter == 2'b11) begin
                    next_counter = 0;
                    next_state = IDLE;
                end
            end
        end

        // En la lógica de próximo estado:
        SEND_LATCHES: begin
            if (du_tx_buffer_full) begin
                next_state = WAIT_TX;
                next_waiting_state = SEND_LATCHES;
            end
            else begin
                next_latches_bytes_count = latches_bytes_count + 1;

                case (counter)
                    2'b00: begin // IF/ID (8 bytes)
                        if (latches_bytes_count == 7) begin
                            next_latches_bytes_count = 0;
                            next_counter = counter + 1;
                            next_state = WAIT_LATCH_ACK;
                        end
                    end
                    2'b01: begin // ID/EX (17 bytes)
                        if (latches_bytes_count == 16) begin
                            next_latches_bytes_count = 0;
                            next_counter = counter + 1;
                            next_state = WAIT_LATCH_ACK;
                        end
                    end
                    2'b10: begin // EX/M (10 bytes)
                        if (latches_bytes_count == 9) begin
                            next_latches_bytes_count = 0;
                            next_counter = counter + 1;
                            next_state = WAIT_LATCH_ACK;
                        end
                    end
                    2'b11: begin // M/WB (9 bytes)
                        if (latches_bytes_count == 8) begin
                            next_latches_bytes_count = 0;
                            next_counter = 0;
                            next_state = IDLE;
                        end
                    end
                endcase
            end
        end

        WAIT_LATCH_ACK: begin
            if (du_rx_buffer_empty) begin
                next_state = WAIT_RX;
                next_waiting_state = WAIT_LATCH_ACK;
            end
            else if (du_data_readed_from_rx_fifo == 8'h01) begin
                next_state = SEND_LATCHES;
            end
            else begin
                next_state = IDLE; // Error en confirmación
            end
        end
        
        WAIT_RX: begin
            if (!du_rx_buffer_empty) begin
                next_state = waiting_state;
            end
        end
        
        WAIT_TX: begin
            if (!du_tx_buffer_full) begin
                next_state = waiting_state;
            end
        end
        
        RESET: begin
            next_state = IDLE;
            next_addr_inst = 0;
        end
        
        default: begin
            next_state = IDLE;
        end
    endcase
end

// Lógica de salida
always @(*) begin
    case (state)
        IDLE: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b0;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            enable_reg = 1'b0;
            reset_mips_reg = 1'b0;   
            idle_led = 1'b1;
            start_led = 1'b0;
            running_led = 1'b0; // LED indicating the system is idle
            data_to_tx = 8'b0; // No data to transmit in IDLE state
        end
        
        START, LOAD_INSTRUCTION, RECEIVE_REG_ADDR, RECEIVE_MEM_ADDR, WAIT_LATCH_ACK: begin
            read_uart_reg = 1'b1;
            write_uart_reg = 1'b0;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            enable_reg = 1'b0;
            reset_mips_reg = 1'b0;    
            idle_led = 1'b0;
            start_led = 1'b1;
            running_led = 1'b0; // LED indicating the system is starting
            data_to_tx = 8'b0; // No data to transmit in these states
        end
        
        SEND_REG_DATA: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b1;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            enable_reg = 1'b0;
            reset_mips_reg = 1'b0;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b0; // LED indicating the system is running
            //Seleccionar el byte a enviar basado en counter ACTUAL
            case (counter)
                2'b00: data_to_tx = i_reg_data[31:24]; // MSB
                2'b01: data_to_tx = i_reg_data[23:16];
                2'b10: data_to_tx = i_reg_data[15:8];
                2'b11: data_to_tx = i_reg_data[7:0];   // LSB
            endcase
        end

        SEND_MEM_DATA: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b1;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            enable_reg = 1'b0;
            reset_mips_reg = 1'b0;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b0; // LED indicating the system is running
            //Seleccionar el byte a enviar basado en counter ACTUAL
            case (counter)
                2'b00: data_to_tx = i_mem_data[31:24]; // MSB
                2'b01: data_to_tx = i_mem_data[23:16];
                2'b10: data_to_tx = i_mem_data[15:8];
                2'b11: data_to_tx = i_mem_data[7:0];   // LSB
            endcase
        end

        // En la lógica de salida para SEND_LATCHES:
        SEND_LATCHES: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b1;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            enable_reg = 1'b0;
            reset_mips_reg = 1'b0;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b0;

            case (counter)
                2'b00: begin // IF/ID (64 bits - bits 340:277)
                    case (latches_bytes_count)
                        0: data_to_tx = i_latches_data[340:333];  // MSB
                        1: data_to_tx = i_latches_data[332:325];
                        2: data_to_tx = i_latches_data[324:317];
                        3: data_to_tx = i_latches_data[316:309];
                        4: data_to_tx = i_latches_data[308:301];
                        5: data_to_tx = i_latches_data[300:293];
                        6: data_to_tx = i_latches_data[292:285];
                        7: data_to_tx = i_latches_data[284:277];  // LSB
                        default: data_to_tx = 8'h00;
                    endcase
                end
                2'b01: begin // ID/EX (130 bits - bits 276:147)
                    case (latches_bytes_count)
                        0:  data_to_tx = i_latches_data[276:269];  // MSB
                        1:  data_to_tx = i_latches_data[268:261];
                        2:  data_to_tx = i_latches_data[260:253];
                        3:  data_to_tx = i_latches_data[252:245];
                        4:  data_to_tx = i_latches_data[244:237];
                        5:  data_to_tx = i_latches_data[236:229];
                        6:  data_to_tx = i_latches_data[228:221];
                        7:  data_to_tx = i_latches_data[220:213];
                        8:  data_to_tx = i_latches_data[212:205];
                        9:  data_to_tx = i_latches_data[204:197];
                        10: data_to_tx = i_latches_data[196:189];
                        11: data_to_tx = i_latches_data[188:181];
                        12: data_to_tx = i_latches_data[180:173];
                        13: data_to_tx = i_latches_data[172:165];
                        14: data_to_tx = i_latches_data[164:157];
                        15: data_to_tx = i_latches_data[156:149];
                        16: data_to_tx = {i_latches_data[148:147], 6'b000000}; // Solo 2 bits válidos + 6 ceros
                        default: data_to_tx = 8'h00;
                    endcase
                end
                2'b10: begin // EX/M (76 bits - bits 146:71)
                    case (latches_bytes_count)
                        0: data_to_tx = i_latches_data[146:139];  // MSB
                        1: data_to_tx = i_latches_data[138:131];
                        2: data_to_tx = i_latches_data[130:123];
                        3: data_to_tx = i_latches_data[122:115];
                        4: data_to_tx = i_latches_data[114:107];
                        5: data_to_tx = i_latches_data[106:99];
                        6: data_to_tx = i_latches_data[98:91];
                        7: data_to_tx = i_latches_data[90:83];
                        8: data_to_tx = i_latches_data[82:75];
                        9: data_to_tx = {i_latches_data[74:71], 4'b0000}; // Solo 4 bits válidos + 4 ceros
                        default: data_to_tx = 8'h00;
                    endcase
                end
                2'b11: begin // M/WB (70 bits - bits 70:1)
                    case (latches_bytes_count)
                        0: data_to_tx = i_latches_data[70:63];   // MSB
                        1: data_to_tx = i_latches_data[62:55];
                        2: data_to_tx = i_latches_data[54:47];
                        3: data_to_tx = i_latches_data[46:39];
                        4: data_to_tx = i_latches_data[38:31];
                        5: data_to_tx = i_latches_data[30:23];
                        6: data_to_tx = i_latches_data[22:15];
                        7: data_to_tx = i_latches_data[14:7];
                        8: data_to_tx = {i_latches_data[6:1], 2'b00}; // Solo 6 bits válidos + 2 ceros
                        default: data_to_tx = 8'h00;
                    endcase
                end
            endcase
        end
        
        WRITE_INST: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b0;
            write_mem_reg = 1'b1;
            read_mem_reg = 1'b0;
            enable_reg = 1'b0;
            reset_mips_reg = 1'b0;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b0; // LED indicating the system is running
            data_to_tx = 8'b0; // No data to transmit in WRITE_INST state
        end
        
        RUN: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b0;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b1;
            enable_reg = 1'b1;
            reset_mips_reg = 1'b0;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b1; // LED indicating the system is running
            data_to_tx = 8'b0; // No data to transmit in RUN state
        end

        WAIT_RX, WAIT_TX: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b0;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            enable_reg = 1'b0;
            reset_mips_reg = 1'b0;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b0; // LED indicating the system is idle
            data_to_tx = 8'b0; // No data to transmit in WAIT states
        end
        
        RESET: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b0;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            enable_reg = 1'b0;
            reset_mips_reg = 1'b1;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b0; // LED indicating the system is idle
            data_to_tx = 8'b0; // No data to transmit in RESET state
        end
        
        default: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b0;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            enable_reg = 1'b0;
            reset_mips_reg = 1'b0;
            idle_led = 1'b1;
            start_led = 1'b0;
            running_led = 1'b0; // LED indicating the system is idle
            data_to_tx = 8'b0; // No data to transmit in default state
        end 
    endcase
end

// Asignaciones de salida
assign du_read_uart_signal = read_uart_reg;
assign du_write_uart_signal = write_uart_reg;
assign du_data_to_write_on_tx_fifo = data_to_tx;
assign o_mips_inst_data = inst_to_mem;
assign o_mips_inst_mem_addr_wr = addr_inst;
assign o_mips_inst_mem_write_en = write_mem_reg;
assign o_mips_inst_mem_read_en = read_mem_reg;
assign o_mips_reset = reset_mips_reg;
assign o_du_reg_addr_sel = addr_inst[4:0]; // Asignación de dirección de registro
assign o_du_mem_addr_sel = addr_inst; // Asignación de dirección de memoria

// LEDs de debug
assign o_idle_led = idle_led;
assign o_start_led = start_led;
assign o_running_led = running_led;

endmodule