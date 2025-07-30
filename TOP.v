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
    input               clock       ,
    input               i_reset     ,
    input               RsRx        ,

    output              RsTx        ,
    output              idle_led    ,
    output              halt_led    ,
    output              start_led   , // LED indicating the start state
    output              running_led // LED indicating the system is running
);
    wire clk_50mhz;
    wire halt_wire;
    wire [NB_REG-1:0] reg_data_wire;
    wire [NB_REG-1:0] mem_data_wire;
    wire [NB_R_INT-1:0] latches_data_wire;
    wire [NB_REG-1:0] inst_to_load;
    wire [NB_REG-1:0] addr_to_load;
    wire [4:0] reg_addr_to_read;
    wire [31:0] mem_addr_to_read;
    wire inst_mem_write_enable;
    wire inst_mem_read_enable;
    wire reset_from_du;
    wire [NB_IFID-1:0] w_IF_ID;
    wire [NB_IDEX-1:0] w_ID_EX;
    wire [NB_EXM-1:0]  w_EX_M ;
    wire [NB_MWB-1:0]  w_M_WB ;


    clk_wiz_0 u_clk_wiz_0
    (
     // Clock out ports
           .clk_out1(clk_50mhz),
     // Status and control signals
           .reset(i_reset),
           .locked(),
    // Clock in ports
           .clk_in1(clock)
    );

    assign latches_data_wire = {w_IF_ID, w_ID_EX, w_EX_M, w_M_WB};
    assign halt_led = halt_wire;

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
        .i_du_reset(i_reset),
        .i_uart_rx_data_in(RsRx),
        .i_du_halt(halt_wire),
        .i_reg_data(reg_data_wire),
        .i_mem_data(mem_data_wire),
        .i_latches_data(latches_data_wire),

        .o_uart_tx_data_out(RsTx),
        .o_mips_inst_data(inst_to_load),
        .o_mips_inst_mem_addr_wr(addr_to_load),
        .o_mips_inst_mem_write_en(inst_mem_write_enable),
        .o_mips_inst_mem_read_en(inst_mem_read_enable),
        .o_mips_reset(reset_from_du),
        .o_du_reg_addr_sel(reg_addr_to_read),
        .o_du_mem_addr_sel(mem_addr_to_read), 
        .o_idle_led(idle_led), // LED indicating idle state
        .o_start_led(start_led), // LED indicating start state
        .o_running_led(running_led) // LED indicating the system is running
    );

    PIPELINE pipeline (
        .i_clk(clk_50mhz),
        .i_reset(i_reset | reset_from_du), // Reset signal from debug unit
        .i_du_data(inst_to_load),
        .i_du_inst_addr_wr(addr_to_load),
        .i_du_mem_addr(mem_addr_to_read),
        .i_du_reg_addr(reg_addr_to_read),
        .i_du_write_en(inst_mem_write_enable),
        .i_du_read_en(inst_mem_read_enable),
    
        .o_du_halt(halt_wire), // Señal de parada (HALT)
        .o_du_if_id_data(w_IF_ID), // Datos de la etapa IF/ID
        .o_du_id_ex_data(w_ID_EX), // Datos de la etapa ID/EX
        .o_du_ex_m_data(w_EX_M), // Datos de la etapa EX/MEM
        .o_du_m_wb_data(w_M_WB), // Datos de la etapa MEM/WB
        .o_du_regs_mem_data(reg_data_wire),
        .o_du_mem_data(mem_data_wire)
    );

endmodule