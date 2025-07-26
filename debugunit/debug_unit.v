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
    input               i_du_clk,
    input               i_du_reset,
    input               i_uart_rx_data_in,
    input               i_du_halt,
    input [NB_REG-1:0]  i_reg_data,
    input [NB_REG-1:0]  i_mem_data,
    input [NB_R_INT-1:0] i_latches_data,

    output              o_uart_tx_data_out,
    output[NB_REG-1:0]  o_mips_inst_data,
    output[NB_REG-1:0]  o_mips_inst_mem_addr_wr,
    output              o_mips_inst_mem_write_en,
    output              o_mips_inst_mem_read_en,
    output              o_mips_reset,
    output              o_tx_confirmation,
    output              o_rx_confirmation,
    output              o_idle_led,
    output              o_start_led, 
    output              o_running_led // LED indicating the system is running
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
localparam IDLE           = 4'b0001;
localparam START          = 4'b0010;
localparam LOAD_INSTRUCTION = 4'b0011;
localparam SEND_ACK       = 4'b0100;
localparam WRITE_INST     = 4'b0101;
localparam RUN            = 4'b0110;
localparam SEND_REG       = 4'b0111;
localparam SEND           = 4'b1000;
localparam SEND_M         = 4'b1001;
localparam SEND_REG_INT   = 4'b1010;
localparam WAIT_RX        = 4'b1011;
localparam WAIT_TX        = 4'b1100;
localparam RESET          = 4'b1101;

// Comandos UART
localparam LOAD_INSTRUCTION_CMD = 8'h02;
localparam RUN_CMD        = 8'h05;
localparam RESET_CMD      = 8'h0C;
localparam ACK_BYTE       = 8'hAA;
localparam HALT_CODE      = 32'hFC000000;

// Registros
reg [3:0] state, next_state;
reg [3:0] waiting_state, next_waiting_state;
reg [1:0] counter, next_counter;
reg [NB_REG-1:0] inst_to_mem, next_inst_to_mem; 
reg [NB_REG-1:0] addr_inst, next_addr_inst; 
reg [DBIT-1:0] data_to_tx, next_data_to_tx; 
reg tx_confirmation, rx_confirmation, idle_led, start_led, running_led;

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
        data_to_tx <= 8'b0;
    end
    else begin
        state <= next_state;
        waiting_state <= next_waiting_state;
        counter <= next_counter;
        inst_to_mem <= next_inst_to_mem;
        addr_inst <= next_addr_inst;
        data_to_tx <= next_data_to_tx;
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
                next_state = SEND_ACK;
                next_waiting_state = LOAD_INSTRUCTION;
                next_data_to_tx = ACK_BYTE;
            end
            else if (du_data_readed_from_rx_fifo == RUN_CMD) begin
                next_state = SEND_ACK;
                next_waiting_state = RUN;
                next_data_to_tx = ACK_BYTE;
            end
            else if (du_data_readed_from_rx_fifo == RESET_CMD) begin
                next_state = RESET;
            end
            else begin
                next_state = IDLE;
            end
        end
        
        SEND_ACK: begin
            if (du_tx_buffer_full) begin
                next_state = WAIT_TX;
            end
            else begin
                next_state = waiting_state;
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
                next_data_to_tx = ACK_BYTE;
                
                if (counter == 2'b11) begin
                    next_counter = 0;
                    next_state = SEND_ACK;
                    next_waiting_state = WRITE_INST;
                end
                else begin
                    next_state = SEND_ACK;
                    next_waiting_state = LOAD_INSTRUCTION;
                end
            end
        end
        
        WRITE_INST: begin
            if (inst_to_mem == HALT_CODE) begin
                next_state = START;
                next_addr_inst = 0;
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
                next_state = SEND_REG;
            end
        end

        SEND: begin
            if(du_tx_buffer_full)begin
                next_state = WAIT_TX;
                next_waiting_state = SEND;
            end
            else begin
                next_data_to_tx = i_reg_data[(31-counter[1:0]*8)-:8];
                next_counter = counter + 1;
                next_state = SEND_REG;
            end
        end
        
        SEND_REG: begin
            if (du_tx_buffer_full) begin
                next_state = WAIT_TX;
                next_waiting_state = SEND_REG;
            end
            else begin
                // Envía registros byte a byte (big endian)
                next_data_to_tx = i_reg_data[(31-counter*8) -: 8];
                next_counter = counter + 1;
                
                if (counter == 2'b11) begin
                    // Completó el envío de un registro de 32 bits
                    next_counter = 0;
                    if (addr_inst == 31) begin
                        // Terminó de enviar todos los 32 registros
                        next_addr_inst = 0;
                        next_state = SEND_M;
                    end
                    else begin
                        // Pasa al siguiente registro
                        next_addr_inst = addr_inst + 1;
                    end
                end
            end
        end
        
        SEND_M: begin
            if (du_tx_buffer_full) begin
                next_state = WAIT_TX;
                next_waiting_state = SEND_M;
            end
            else begin
                // Envía datos de memoria byte a byte (big endian)
                next_data_to_tx = i_mem_data[(31-counter*8) -: 8];
                next_counter = counter + 1;
                
                if (counter == 2'b11) begin
                    // Completó el envío de una palabra de 32 bits
                    next_counter = 0;
                    next_addr_inst = addr_inst + 4; // Direcciones de memoria van de 4 en 4
                    
                    if (addr_inst[6:0] == 8'd252) begin // 124 en decimal (31*4)
                        // Terminó de enviar toda la memoria (32 palabras)
                        next_addr_inst = 0;
                        next_state = SEND_REG_INT;
                    end
                end
            end
        end
        
        SEND_REG_INT: begin
            if (du_tx_buffer_full) begin
                next_state = WAIT_TX;
                next_waiting_state = SEND_REG_INT;
            end
            else begin
                // Envía registros internos byte a byte
                next_data_to_tx = i_latches_data[(340-addr_inst*8) -: 8];
                next_addr_inst = addr_inst + 1;
                
                if (addr_inst == 42) begin // 341 bits = 43 bytes (0 a 42)
                    // Terminó de enviar todos los registros internos
                    next_addr_inst = 0;
                    next_state = IDLE; // Vuelve a IDLE para esperar nuevos comandos
                end
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
            tx_confirmation = 1'b0;
            rx_confirmation = 1'b0;
            idle_led = 1'b1;
            start_led = 1'b0;
            running_led = 1'b0; // LED indicating the system is idle
        end
        
        START, LOAD_INSTRUCTION: begin
            read_uart_reg = 1'b1;
            write_uart_reg = 1'b0;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            enable_reg = 1'b0;
            reset_mips_reg = 1'b0;    
            tx_confirmation = 1'b0;
            rx_confirmation = 1'b1;
            idle_led = 1'b0;
            start_led = 1'b1;
            running_led = 1'b0; // LED indicating the system is starting
        end
        
        SEND_ACK, SEND_REG, SEND_M, SEND_REG_INT: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b1;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            enable_reg = 1'b0;
            reset_mips_reg = 1'b0;
            tx_confirmation = 1'b1;
            rx_confirmation = 1'b0;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b0; // LED indicating the system is running
        end
        
        WRITE_INST: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b0;
            write_mem_reg = 1'b1;
            read_mem_reg = 1'b0;
            enable_reg = 1'b0;
            reset_mips_reg = 1'b0;
            tx_confirmation = 1'b0;
            rx_confirmation = 1'b0;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b0; // LED indicating the system is running
        end
        
        RUN: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b0;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b1;
            enable_reg = 1'b1;
            reset_mips_reg = 1'b0;
            tx_confirmation = 1'b0;
            rx_confirmation = 1'b0;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b1; // LED indicating the system is running
        end
        
        WAIT_RX: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b0;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            enable_reg = 1'b0;
            reset_mips_reg = 1'b0;
            tx_confirmation = 1'b0;
            rx_confirmation = 1'b1;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b0; // LED indicating the system is idle
        end
        
        WAIT_TX, SEND: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b0;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            enable_reg = 1'b0;
            reset_mips_reg = 1'b0;
            tx_confirmation = 1'b1;
            rx_confirmation = 1'b0;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b0; // LED indicating the system is idle
        end
        
        RESET: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b0;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            enable_reg = 1'b0;
            reset_mips_reg = 1'b1;
            tx_confirmation = 1'b0;
            rx_confirmation = 1'b0;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b0; // LED indicating the system is idle
        end
        
        default: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b0;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            enable_reg = 1'b0;
            reset_mips_reg = 1'b0;
            tx_confirmation = 1'b0;
            rx_confirmation = 1'b0;
            idle_led = 1'b1;
            start_led = 1'b0;
            running_led = 1'b0; // LED indicating the system is idle
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

// LEDs de debug
assign o_tx_confirmation = tx_confirmation;
assign o_rx_confirmation = rx_confirmation;
assign o_idle_led = idle_led;
assign o_start_led = start_led;
assign o_running_led = running_led;

endmodule