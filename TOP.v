module TOP 
#(
    parameter NB_REG = 32 ,
    parameter NB_IFID =64 ,
    parameter NB_IDEX =130,
    parameter NB_EXM  =76 ,
    parameter NB_MWB  =71 ,
    parameter NB_R_INT=341
) 
(
    input               clk       ,
    input               reset     ,
    input               uart_rx        ,

    output              uart_tx        ,
    output              [3:0] debugger_leds
);
    wire clk_50mhz;
    wire halt_wire;
    wire [NB_REG-1:0] reg_data_wire;
    wire [NB_REG-1:0] mem_data_wire;
    wire [NB_REG-1:0] inst_to_load;
    wire [31:0] addr_to_load;
    wire [4:0] reg_addr_to_read;
    wire [7:0] mem_addr_to_read;
    wire inst_mem_write_enable;
    wire inst_mem_read_enable;
    wire reset_from_du;
    wire step_mode_wire;
    wire clk_enable;

    wire [31:0] if_id_pc_plus_4, if_id_instruction;

    wire [31:0] id_ex_data_1, id_ex_data_2;
    wire [4:0]  id_ex_rs, id_ex_rt, id_ex_rd;
    wire [5:0]  id_ex_function_code;
    wire [31:0] extended_beq_offset;
    wire id_ex_reg_dest, id_ex_mem_read, id_ex_mem_write, id_ex_reg_write, id_ex_alu_src, id_ex_mem_to_reg;
    wire [3:0] id_ex_alu_op;
    wire [2:0] id_ex_bhw_type;

    wire [4:0] ex_m_rd;
    wire ex_m_reg_write, ex_m_mem_read, ex_m_mem_write, ex_m_mem_to_reg;
    wire [31:0] ex_m_alu_result, ex_m_write_data;
    wire [2:0] ex_m_bhw_type;

    wire [31:0] m_wb_read_data, m_wb_alu_result;
    wire m_wb_reg_write;
    wire [4:0] m_wb_rd;


    clk_wiz_0 u_clk_wiz_0
    (
     // Clock out ports
           .clk_out1(clk_50mhz),
     // Status and control signals
           .reset(reset),
           .locked(),
    // Clock in ports
           .clk_in1(clk)
    );

    debug_unit #(
        .NB_REG   (NB_REG),
        .NB_R_INT (NB_R_INT),
        .DBIT     (8  ),
        .SB_TICK  (16 ),
        .DVSR     (163), //50mhz 50mhz/(19200*16)
        .DVSR_BITS (8  ),
        .FIFO_W   (5  )
    )
    debug_unit
    (
        .i_du_clk(clk_50mhz),
        .i_du_reset(reset),
        .i_uart_rx_data_in(uart_rx),
        .i_du_halt(halt_wire),
        .i_reg_data(reg_data_wire),
        .i_mem_data(mem_data_wire),
        .i_if_id_instruction(if_id_instruction),
        .i_if_id_pc_plus_4(if_id_pc_plus_4),

        .i_id_ex_data_1(id_ex_data_1),
        .i_id_ex_data_2(id_ex_data_2),
        .i_id_ex_rs(id_ex_rs),
        .i_id_ex_rt(id_ex_rt),
        .i_id_ex_rd(id_ex_rd),
        .i_id_ex_function_code(id_ex_function_code),
        .i_id_ex_extended_beq_offset(extended_beq_offset),
        .i_id_ex_reg_dest(id_ex_reg_dest),
        .i_id_ex_mem_read(id_ex_mem_read),
        .i_id_ex_mem_write(id_ex_mem_write),
        .i_id_ex_reg_write(id_ex_reg_write),
        .i_id_ex_alu_src(id_ex_alu_src),
        .i_id_ex_mem_to_reg(id_ex_mem_to_reg),
        .i_id_ex_alu_op(id_ex_alu_op),
        .i_id_ex_bhw_type(id_ex_bhw_type),

        .i_ex_m_rd(ex_m_rd),
        .i_ex_m_reg_write(ex_m_reg_write),
        .i_ex_m_mem_read(ex_m_mem_read),
        .i_ex_m_mem_write(ex_m_mem_write),
        .i_ex_m_mem_to_reg(ex_m_mem_to_reg),
        .i_ex_m_alu_result(ex_m_alu_result),
        .i_ex_m_write_data(ex_m_write_data),
        .i_ex_m_bhw_type(ex_m_bhw_type),

        .i_m_wb_read_data(m_wb_read_data),
        .i_m_wb_alu_result(m_wb_alu_result),
        .i_m_wb_reg_write(m_wb_reg_write),
        .i_m_wb_rd(m_wb_rd),

        .o_uart_tx_data_out(uart_tx),
        .o_mips_inst_data(inst_to_load),
        .o_mips_inst_mem_addr_wr(addr_to_load),
        .o_mips_inst_mem_write_en(inst_mem_write_enable),
        .o_mips_inst_mem_read_en(inst_mem_read_enable),
        .o_mips_reset(reset_from_du),
        .o_du_reg_addr_sel(reg_addr_to_read),
        .o_du_mem_addr_sel(mem_addr_to_read), 
        .o_idle_led(debugger_leds[0]), // LED indicating idle state
        .o_start_led(debugger_leds[1]), // LED indicating start state
        .o_running_led(debugger_leds[2]),
        .o_step_mode(step_mode_wire),
        .o_clk_en(clk_enable) // Clock enable signal
    );

    assign debugger_leds[3] = halt_wire;

    PIPELINE pipeline (
        .i_clk(clk_50mhz),
        .i_clk_en(clk_enable), // Habilitar señal de reloj
        .i_reset(reset | reset_from_du), // Reset signal from debug unit
        .i_du_data(inst_to_load),
        .i_du_inst_addr_wr(addr_to_load),
        .i_du_mem_addr(mem_addr_to_read),
        .i_du_reg_addr(reg_addr_to_read),
        .i_du_write_en(inst_mem_write_enable),
        .i_du_read_en(inst_mem_read_enable),
    
        .o_du_halt(halt_wire), // Señal de parada (HALT)
        .o_du_if_id_pc_plus_4(if_id_pc_plus_4),
        .o_du_if_id_instruction(if_id_instruction),

        .o_du_id_ex_data_1(id_ex_data_1),
        .o_du_id_ex_data_2(id_ex_data_2),
        .o_du_id_ex_rs(id_ex_rs),
        .o_du_id_ex_rt(id_ex_rt),
        .o_du_id_ex_rd(id_ex_rd),
        .o_du_id_ex_function_code(id_ex_function_code),
        .o_du_id_ex_extended_beq_offset(extended_beq_offset),
        .o_du_id_ex_reg_dest(id_ex_reg_dest),
        .o_du_id_ex_mem_read(id_ex_mem_read),
        .o_du_id_ex_mem_write(id_ex_mem_write),
        .o_du_id_ex_reg_write(id_ex_reg_write),
        .o_du_id_ex_alu_src(id_ex_alu_src),
        .o_du_id_ex_mem_to_reg(id_ex_mem_to_reg),
        .o_du_id_ex_alu_op(id_ex_alu_op),
        .o_du_id_ex_bhw_type(id_ex_bhw_type),

        .o_du_ex_m_rd(ex_m_rd),
        .o_du_ex_m_reg_write(ex_m_reg_write),
        .o_du_ex_m_mem_read(ex_m_mem_read),
        .o_du_ex_m_mem_write(ex_m_mem_write),
        .o_du_ex_m_mem_to_reg(ex_m_mem_to_reg),
        .o_du_ex_m_alu_result(ex_m_alu_result),
        .o_du_ex_m_write_data(ex_m_write_data),
        .o_du_ex_m_bhw_type(ex_m_bhw_type),

        .o_du_m_wb_read_data(m_wb_read_data),
        .o_du_m_wb_alu_result(m_wb_alu_result),
        .o_du_m_wb_reg_write(m_wb_reg_write),
        .o_du_m_wb_rd(m_wb_rd),

        .o_du_regs_mem_data(reg_data_wire),
        .o_du_mem_data(mem_data_wire)
    );

endmodule