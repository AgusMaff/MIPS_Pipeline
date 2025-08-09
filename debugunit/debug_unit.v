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

    input [31:0]          i_if_id_pc_plus_4,
    input [31:0]          i_if_id_instruction,

    input [31:0]          i_id_ex_data_1,
    input [31:0]          i_id_ex_data_2,
    input [4:0]           i_id_ex_rs,
    input [4:0]           i_id_ex_rt,
    input [4:0]           i_id_ex_rd,
    input [5:0]           i_id_ex_function_code,
    input [31:0]          i_id_ex_extended_beq_offset,
    input                 i_id_ex_reg_dest,
    input                 i_id_ex_mem_read,
    input                 i_id_ex_mem_write,
    input                 i_id_ex_reg_write,
    input                 i_id_ex_alu_src,
    input                 i_id_ex_mem_to_reg,
    input [3:0]           i_id_ex_alu_op,
    input [2:0]           i_id_ex_bhw_type,

    input [4:0]           i_ex_m_rd,
    input [31:0]          i_ex_m_alu_result,
    input [31:0]          i_ex_m_write_data,
    input                 i_ex_m_mem_read,
    input                 i_ex_m_mem_write,
    input                 i_ex_m_reg_write,
    input                 i_ex_m_mem_to_reg,
    input [2:0]           i_ex_m_bhw_type,

    input [4:0]           i_m_wb_rd,
    input [31:0]          i_m_wb_alu_result,
    input [31:0]          i_m_wb_read_data,
    input                 i_m_wb_reg_write,

    output                o_uart_tx_data_out,
    output [NB_REG-1:0]   o_mips_inst_data,
    output [7:0]          o_mips_inst_mem_addr_wr,
    output                o_mips_inst_mem_write_en,
    output                o_mips_inst_mem_read_en,
    output                o_mips_reset,
    output [4:0]          o_du_reg_addr_sel,
    output [7:0]          o_du_mem_addr_sel,
    output                o_idle_led,
    output                o_start_led, 
    output                o_running_led, // LED indicating the system is running
    output                o_step_mode,
    output                o_clk_en // Clock enable signal
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
localparam RECEIVE_LATCH        = 5'b10011;
localparam SEND_IFID_LATCH      = 5'b10100;
localparam SEND_IDEX_LATCH      = 5'b10101;
localparam SEND_EXM_LATCH       = 5'b10110;
localparam SEND_MWB_LATCH       = 5'b10111;
localparam STEP                 = 5'b11000;

// Comandos UART
localparam LOAD_INSTRUCTION_CMD = 8'h02;
localparam RUN_CMD              = 8'h05;
localparam RESET_CMD            = 8'h0F;
localparam READ_REG_CMD         = 8'h06;
localparam READ_MEM_CMD         = 8'h07;
localparam READ_LATCH_CMD       = 8'h08;
localparam READ_IFID_LATCH_CMD  = 8'h09;
localparam READ_IDEX_LATCH_CMD  = 8'h0A;
localparam READ_EXM_LATCH_CMD   = 8'h0B;
localparam READ_MWB_LATCH_CMD   = 8'h0C;
localparam STEP_CMD             = 8'h0D;
localparam HALT_CODE            = 32'hFC000000;

// Registros
reg [4:0] state, next_state;
reg [4:0] waiting_state, next_waiting_state;
reg [1:0] counter, next_counter;
reg [7:0] latches_bytes_count, next_latches_bytes_count;
reg [NB_REG-1:0] inst_to_mem, next_inst_to_mem; 
reg [7:0] addr_inst, next_addr_inst; 
reg [DBIT-1:0] data_to_tx, next_data_to_tx; 
reg [2:0] ifid_byte_counter, next_ifid_byte_counter;
reg [4:0] idex_byte_counter, next_idex_byte_counter;
reg [3:0] exm_byte_counter, next_exm_byte_counter;
reg [3:0] mwb_byte_counter, next_mwb_byte_counter;
reg idle_led, start_led, running_led;
reg step_mode, next_step_mode;
reg cicle_done, next_cicle_done;

wire [63:0] if_id_latch_data;
wire [135:0] idex_latch_data;
wire [79:0] exm_latch_data;
wire [71:0] mwb_latch_data;

assign if_id_latch_data = {i_if_id_pc_plus_4, i_if_id_instruction};

assign idex_latch_data = {i_id_ex_data_1, i_id_ex_data_2, 
                          i_id_ex_rs, i_id_ex_rt, i_id_ex_rd,
                          i_id_ex_function_code, i_id_ex_extended_beq_offset,
                          i_id_ex_reg_dest, i_id_ex_mem_read,
                          i_id_ex_mem_write, i_id_ex_reg_write,
                          i_id_ex_alu_src, i_id_ex_mem_to_reg,
                          i_id_ex_alu_op, i_id_ex_bhw_type, 6'b0}; 

assign exm_latch_data = {i_ex_m_rd, i_ex_m_alu_result, 
                         i_ex_m_write_data, i_ex_m_mem_read,
                         i_ex_m_mem_write, i_ex_m_reg_write,
                         i_ex_m_mem_to_reg, i_ex_m_bhw_type, 4'b0};

assign mwb_latch_data = {i_m_wb_rd, i_m_wb_alu_result, 
                         i_m_wb_read_data, i_m_wb_reg_write, 2'b0};

// Señales de control
reg read_uart_reg, write_uart_reg, write_mem_reg, read_mem_reg, reset_mips_reg;

// Registro de estado
always @(posedge i_du_clk) begin
    if (i_du_reset) begin
        state <= IDLE;
        waiting_state <= IDLE;
        counter <= 2'b00;
        inst_to_mem <= 0;
        addr_inst <= 0;
        cicle_done <= 1'b0; 
        ifid_byte_counter <= 0;
        idex_byte_counter <= 0;
        exm_byte_counter <= 0;
        mwb_byte_counter <= 0;
    end
    else begin
        state <= next_state;
        waiting_state <= next_waiting_state;
        counter <= next_counter;
        inst_to_mem <= next_inst_to_mem;
        addr_inst <= next_addr_inst;
        cicle_done <= next_cicle_done;
        ifid_byte_counter <= next_ifid_byte_counter;
        idex_byte_counter <= next_idex_byte_counter;
        exm_byte_counter <= next_exm_byte_counter;
        mwb_byte_counter <= next_mwb_byte_counter;
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
    next_cicle_done = cicle_done;
    next_ifid_byte_counter = ifid_byte_counter;
    next_idex_byte_counter = idex_byte_counter;
    next_exm_byte_counter = exm_byte_counter;
    next_mwb_byte_counter = mwb_byte_counter;
    
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
            else if (du_data_readed_from_rx_fifo == READ_LATCH_CMD) begin
                next_state = RECEIVE_LATCH;
            end
            else if (du_data_readed_from_rx_fifo == STEP_CMD) begin
                next_state = STEP;
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

        STEP: begin
            next_state = IDLE;
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

        RECEIVE_LATCH: begin
            if (du_rx_buffer_empty) begin
                next_state = WAIT_RX;
                next_waiting_state = RECEIVE_LATCH;
            end
            else begin
                if(du_data_readed_from_rx_fifo == READ_IFID_LATCH_CMD) begin
                    next_state = SEND_IFID_LATCH; // IF/ID latch
                end
                else if(du_data_readed_from_rx_fifo == READ_IDEX_LATCH_CMD) begin
                    next_state = SEND_IDEX_LATCH; // ID/EX latch
                end
                else if(du_data_readed_from_rx_fifo == READ_EXM_LATCH_CMD) begin
                    next_state = SEND_EXM_LATCH; // EX/M latch
                end
                else if(du_data_readed_from_rx_fifo == READ_MWB_LATCH_CMD) begin
                    next_state = SEND_MWB_LATCH; // M/WB latch
                end
                else begin
                    next_state = IDLE; // Comando no reconocido, vuelve a IDLE
                end
            end
        end

        SEND_IFID_LATCH: begin
            if (du_tx_buffer_full) begin
                next_state = WAIT_TX;
                next_waiting_state = SEND_IFID_LATCH;
            end
            else begin
                next_ifid_byte_counter = ifid_byte_counter + 1;

                if (ifid_byte_counter == 3'b111) begin
                    next_ifid_byte_counter = 0;
                    next_state = IDLE; // Vuelve a IDLE después de enviar los datos
                end
            end
        end

        SEND_IDEX_LATCH: begin
            if (du_tx_buffer_full) begin
                next_state = WAIT_TX;
                next_waiting_state = SEND_IDEX_LATCH;
            end
            else begin
                next_idex_byte_counter = idex_byte_counter + 1;

                if (idex_byte_counter == 5'b10000) begin
                    next_idex_byte_counter = 0;
                    next_state = IDLE; // Vuelve a IDLE después de enviar los datos
                end
            end
        end

        SEND_EXM_LATCH: begin
            if (du_tx_buffer_full) begin
                next_state = WAIT_TX;
                next_waiting_state = SEND_EXM_LATCH;
            end
            else begin
                next_exm_byte_counter = exm_byte_counter + 1;

                if (exm_byte_counter == 4'b1010) begin
                    next_exm_byte_counter = 0;
                    next_state = IDLE; // Vuelve a IDLE después de enviar los datos
                end
            end
        end

        SEND_MWB_LATCH: begin
            if (du_tx_buffer_full) begin
                next_state = WAIT_TX;
                next_waiting_state = SEND_MWB_LATCH;
            end
            else begin
                next_mwb_byte_counter = mwb_byte_counter + 1;

                if (mwb_byte_counter == 4'b1001) begin
                    next_mwb_byte_counter = 0;
                    next_state = IDLE; // Vuelve a IDLE después de enviar los datos
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
            reset_mips_reg = 1'b0;   
            idle_led = 1'b1;
            start_led = 1'b0;
            running_led = 1'b0; // LED indicating the system is idle
            data_to_tx = 8'b0; // No data to transmit in IDLE state
            step_mode = 1'b0;
        end
        
        START, LOAD_INSTRUCTION, RECEIVE_REG_ADDR, RECEIVE_MEM_ADDR, RECEIVE_LATCH: begin
            read_uart_reg = 1'b1;
            write_uart_reg = 1'b0;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            reset_mips_reg = 1'b0;    
            idle_led = 1'b0;
            start_led = 1'b1;
            running_led = 1'b0; // LED indicating the system is starting
            data_to_tx = 8'b0; // No data to transmit in these states
            step_mode = 1'b0;
        end
        
        SEND_REG_DATA: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b1;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            reset_mips_reg = 1'b0;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b0; // LED indicating the system is running
            step_mode = 1'b0;
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
            reset_mips_reg = 1'b0;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b0; // LED indicating the system is running
            step_mode = 1'b0;
            //Seleccionar el byte a enviar basado en counter ACTUAL
            case (counter)
                2'b00: data_to_tx = i_mem_data[31:24]; // MSB
                2'b01: data_to_tx = i_mem_data[23:16];
                2'b10: data_to_tx = i_mem_data[15:8];
                2'b11: data_to_tx = i_mem_data[7:0];   // LSB
            endcase
        end

        // En la lógica de salida para SEND_LATCHES:
        SEND_IFID_LATCH: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b1;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            reset_mips_reg = 1'b0;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b0;
            step_mode = 1'b0;
            case (ifid_byte_counter)
                3'b000: data_to_tx = if_id_latch_data[63:56]; // MSB
                3'b001: data_to_tx = if_id_latch_data[55:48];
                3'b010: data_to_tx = if_id_latch_data[47:40];
                3'b011: data_to_tx = if_id_latch_data[39:32];
                3'b100: data_to_tx = if_id_latch_data[31:24];
                3'b101: data_to_tx = if_id_latch_data[23:16];
                3'b110: data_to_tx = if_id_latch_data[15:8];
                3'b111: data_to_tx = if_id_latch_data[7:0];   // LSB
            endcase
        end

        SEND_IDEX_LATCH: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b1;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            reset_mips_reg = 1'b0;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b0;
            step_mode = 1'b0;
            case (idex_byte_counter)
                5'b00000: data_to_tx = idex_latch_data[135:128]; // MSB
                5'b00001: data_to_tx = idex_latch_data[127:120];
                5'b00010: data_to_tx = idex_latch_data[119:112];
                5'b00011: data_to_tx = idex_latch_data[111:104];
                5'b00100: data_to_tx = idex_latch_data[103:96];
                5'b00101: data_to_tx = idex_latch_data[95:88];
                5'b00110: data_to_tx = idex_latch_data[87:80];
                5'b00111: data_to_tx = idex_latch_data[79:72];
                5'b01000: data_to_tx = idex_latch_data[71:64];
                5'b01001: data_to_tx = idex_latch_data[63:56];
                5'b01010: data_to_tx = idex_latch_data[55:48];
                5'b01011: data_to_tx = idex_latch_data[47:40];
                5'b01100: data_to_tx = idex_latch_data[39:32];
                5'b01101: data_to_tx = idex_latch_data[31:24];
                5'b01110: data_to_tx = idex_latch_data[23:16];
                5'b01111: data_to_tx = idex_latch_data[15:8];
                5'b10000: data_to_tx = idex_latch_data[7:0];   // LSB
            endcase
        end

        SEND_EXM_LATCH: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b1;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            reset_mips_reg = 1'b0;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b0;
            step_mode = 1'b0;
            case (exm_byte_counter)
                4'b0000: data_to_tx = exm_latch_data[79:72]; // MSB
                4'b0001: data_to_tx = exm_latch_data[71:64];
                4'b0010: data_to_tx = exm_latch_data[63:56];
                4'b0011: data_to_tx = exm_latch_data[55:48];
                4'b0100: data_to_tx = exm_latch_data[47:40];
                4'b0101: data_to_tx = exm_latch_data[39:32];
                4'b0110: data_to_tx = exm_latch_data[31:24];
                4'b0111: data_to_tx = exm_latch_data[23:16];
                4'b1000: data_to_tx = exm_latch_data[15:8];
                4'b1001: data_to_tx = exm_latch_data[7:0];   // LSB
            endcase
        end

        SEND_MWB_LATCH: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b1;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            reset_mips_reg = 1'b0;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b0;
            step_mode = 1'b0;
            case (mwb_byte_counter)
                4'b0000: data_to_tx = mwb_latch_data[71:64]; // MSB
                4'b0001: data_to_tx = mwb_latch_data[63:56];
                4'b0010: data_to_tx = mwb_latch_data[55:48];
                4'b0011: data_to_tx = mwb_latch_data[47:40];
                4'b0100: data_to_tx = mwb_latch_data[39:32];
                4'b0101: data_to_tx = mwb_latch_data[31:24];
                4'b0110: data_to_tx = mwb_latch_data[23:16];
                4'b0111: data_to_tx = mwb_latch_data[15:8];
                4'b1000: data_to_tx = mwb_latch_data[7:0];   // LSB
            endcase
        end
        
        WRITE_INST: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b0;
            write_mem_reg = 1'b1;
            read_mem_reg = 1'b0;
            reset_mips_reg = 1'b0;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b0; // LED indicating the system is running
            data_to_tx = 8'b0; // No data to transmit in WRITE_INST state
            step_mode = 1'b0;
        end
        
        RUN: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b0;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b1;
            reset_mips_reg = 1'b0;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b1; // LED indicating the system is running
            data_to_tx = 8'b0; // No data to transmit in RUN state
            step_mode = 1'b0;
        end

        STEP: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b0;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b1; // Leer memoria solo si se ha completado un ciclo
            reset_mips_reg = 1'b0;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b1; // LED indicating the system is idle
            data_to_tx = 8'b0; // No data to transmit in STEP state
            step_mode = 1'b1;
        end

        WAIT_RX, WAIT_TX: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b0;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            reset_mips_reg = 1'b0;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b0; // LED indicating the system is idle
            data_to_tx = 8'b0; // No data to transmit in WAIT states
            step_mode = 1'b0;
        end
        
        RESET: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b0;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            reset_mips_reg = 1'b1;
            idle_led = 1'b0;
            start_led = 1'b0;
            running_led = 1'b0; // LED indicating the system is idle
            data_to_tx = 8'b0; // No data to transmit in RESET state
            step_mode = 1'b0;
        end
        
        default: begin
            read_uart_reg = 1'b0;
            write_uart_reg = 1'b0;
            write_mem_reg = 1'b0;
            read_mem_reg = 1'b0;
            reset_mips_reg = 1'b0;
            idle_led = 1'b1;
            start_led = 1'b0;
            running_led = 1'b0; // LED indicating the system is idle
            data_to_tx = 8'b0; // No data to transmit in default state
            step_mode = 1'b0;
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
assign o_step_mode = step_mode;
assign o_clk_en = read_mem_reg;

// LEDs de debug
assign o_idle_led = idle_led;
assign o_start_led = start_led;
assign o_running_led = running_led;

endmodule