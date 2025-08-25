`timescale 1ns / 1ps

module third_program();

    reg i_clk;
    reg i_clk_en; // Enable clock signal
    reg i_reset;
    reg [31:0] i_du_data;
    reg [31:0] i_du_inst_addr_wr;
    reg [7:0] i_du_mem_addr;
    reg [4:0] i_du_reg_addr;
    reg i_du_write_en;
    reg i_du_read_en;
    wire o_du_halt; // Señal de parada (HALT)
    wire [31:0] o_du_if_id_pc_plus_4;
    wire [31:0] o_du_if_id_instruction;
    wire [31:0] o_du_id_ex_data_1;
    wire [31:0] o_du_id_ex_data_2;
    wire [4:0] o_du_id_ex_rs;
    wire [4:0] o_du_id_ex_rt;
    wire [4:0] o_du_id_ex_rd;
    wire [5:0] o_du_id_ex_function_code;
    wire [31:0] o_du_id_ex_extended_beq_offset;
    wire o_du_id_ex_reg_dest;
    wire o_du_id_ex_alu_src;
    wire [3:0] o_du_id_ex_alu_op;
    wire o_du_id_ex_mem_read;
    wire o_du_id_ex_mem_write;
    wire o_du_id_ex_mem_to_reg;
    wire o_du_id_ex_reg_write;
    wire [2:0] o_du_id_ex_bhw_type;
    wire [4:0] o_du_ex_m_rd;
    wire [31:0] o_du_ex_m_alu_result;
    wire [31:0] o_du_ex_m_write_data;
    wire o_du_ex_m_mem_read;
    wire o_du_ex_m_mem_write;
    wire o_du_ex_m_mem_to_reg;
    wire o_du_ex_m_reg_write;
    wire [2:0] o_du_ex_m_bhw_type;
    wire [31:0] o_du_m_wb_read_data;
    wire [31:0] o_du_m_wb_alu_result;
    wire [4:0] o_du_m_wb_rd;
    wire o_du_m_wb_reg_write;
    wire [31:0] o_du_regs_mem_data;
    wire [31:0] o_du_mem_data;

    //Señales de control
    wire pcsrc; // Señal de selección de PC
    wire jump; // Señal de salto
    wire jumpSel; // Bit de control para JR
    wire flush_idex; // Señal de flush
    wire stall; // Señal de stall
    wire end_program;
    reg halt_latched; // Registro para latchear la señal de parada

    // Etapa IF
    wire [31:0] if_beq_jump_dir; // Dirección de salto para BEQ
    wire [31:0] if_id_pc_plus_4; // PC + 4
    wire [31:0] if_id_instruction; // Instrucción leída de la memoria de instrucciones
    
    // Etapa ID
    wire [31:0] id_pc_plus_4; // PC + 4 para la etapa ID
    wire [4:0] id_rs; // Registro fuente rs
    wire [4:0] id_rt; // Registro fuente rt
    wire [4:0] id_rd; // Registro destino rd
    wire [15:0] id_beq_offset; // Offset para la instrucción BEQ
    wire [5:0] id_opcode; // Opcode de la instrucción
    wire [5:0] id_function_code; // Código de función de la instrucción
    wire [31:0] id_instruction; // Instrucción leída

    wire [31:0] id_ex_data_1; // Dato 1 de la etapa ID/EX
    wire [31:0] id_ex_data_2; // Dato 2 de la etapa ID/EX
    wire [4:0] id_ex_rs; // Registro fuente rs de la etapa ID/EX
    wire [4:0] id_ex_rt; // Registro fuente rt de la etapa ID/EX
    wire [4:0] id_ex_rd; // Registro destino rd de la etapa ID/EX
    wire [5:0] id_ex_function_code; // Código de función de la etapa ID/EX
    wire [31:0] id_ex_extended_beq_offset; // Offset extendido para la instrucción BEQ de la etapa ID/EX
    wire id_ex_reg_dest; // Señal de destino del registro
    wire id_ex_alu_src; // Señal de origen de la ALU
    wire [3:0] id_ex_alu_op; // Operación de la ALU
    wire id_ex_mem_read; // Señal de lectura de memoria
    wire id_ex_mem_write; // Señal de escritura de memoria
    wire id_ex_mem_to_reg; // Señal de escritura de registro desde memoria
    wire id_ex_reg_write; // Señal de escritura de registro
    wire id_ex_isJal; // Señal de salto JAL
    wire id_ex_jalSel; // Señal de selección para JALR
    wire [31:0] id_ex_pc_plus_8; // PC + 8 para la etapa ID/EX
    wire [2:0] id_ex_bhw_type; // Tipo de instrucción (Byte, Halfword, Word)
    wire id_ex_halt; // Señal de parada

    //Etapa EX
    wire [31:0] ex_data_1; // Dato 1 de la etapa ID/EX
    wire [31:0] ex_data_2; // Dato 2 de la etapa ID/EX
    wire [4:0] ex_rs; // Registro fuente rs de la etapa ID/EX
    wire [4:0] ex_rt; // Registro fuente rt de la etapa ID/EX
    wire [4:0] ex_rd; // Registro destino rd de la etapa ID/EX
    wire [5:0] ex_function_code; // Código de función de la etapa ID/EX
    wire [31:0] ex_extended_beq_offset; // Offset extendido para la instrucción BEQ de la etapa ID/EX
    wire ex_reg_dest; // Señal de destino del registro de la etapa ID/EX
    wire ex_alu_src; // Señal de origen de la ALU de la etapa ID/EX
    wire [3:0] ex_alu_op; // Operación de la ALU de la etapa ID/EX
    wire ex_read; // Señal de lectura de memoria de la etapa ID/EX
    wire ex_write; // Señal de escritura de memoria de la etapa ID/EX
    wire ex_to_reg; // Señal de escritura de registro desde memoria de la etapa ID/EX
    wire ex_isJal; // Señal de escritura de registro de la etapa ID/EX
    wire ex_jalSel; // Señal de selección para JALR
    wire [31:0] ex_pc_plus_8; // PC + 8 para la etapa ID/EX
    wire [2:0] ex_bhw_type; // Tipo de instrucción (Byte, Halfword, Word) de la etapa ID/EX
    wire ex_halt; // Señal de parada de la etapa ID/EX

    wire [4:0] ex_m_rd; // Registro destino rd de la etapa ID/EX
    wire [31:0] ex_m_alu_result; // Resultado de la ALU de la etapa ID/EX
    wire [31:0] ex_m_write_data; // Datos a escribir en memoria de
    wire ex_m_mem_read; // Señal de lectura de memoria de la etapa ID/EX
    wire ex_m_mem_write; // Señal de escritura de memoria de la etapa ID/EX
    wire ex_m_mem_to_reg; // Señal de escritura de registro desde memoria de la etapa ID/EX
    wire ex_m_reg_write; // Señal de escritura de registro de la etapa ID/EX
    wire ex_m_isJal; // Señal de escritura de registro de la etapa ID/EX
    wire [31:0] ex_m_pc_plus_8; // PC + 8 para la etapa ID/EX
    wire [2:0] ex_m_bhw_type; // Tipo de instrucción (Byte, Halfword, Word) de la etapa ID/EX
    wire ex_m_halt; // Señal de parada de la etapa ID/EX

    // Etapa MEM
    wire [31:0] m_alu_result;
    wire [31:0] m_write_data;
    wire [4:0]  m_rd;
    wire m_mem_read;
    wire m_mem_write;
    wire m_mem_to_reg;
    wire m_reg_write;
    wire m_isJal;
    wire [31:0] m_pc_plus_8; // PC + 8 para la etapa MEM
    wire [2:0] m_bhw_type;
    wire m_halt;

    wire [31:0] m_wb_read_data; // Datos leídos de memoria para la etapa WB
    wire [4:0] m_wb_rd; // Registro destino para la etapa WB
    wire [31:0] m_wb_alu_result; // Resultado de la ALU para la etapa WB
    wire m_wb_mem_to_reg; // Señal de escritura de registro desde memoria para la etapa WB
    wire m_wb_reg_write; // Señal de escritura de registro para la etapa WB
    wire m_wb_isJal; // Señal de escritura de registro para la etapa WB
    wire [31:0] m_wb_pc_plus_8; // PC + 8 para la etapa WB
    wire m_wb_halt; // Señal de parada para la etapa WB

    // Etapa WB
    wire [31:0] wb_data; // Datos a escribir en el registro
    wire [31:0] wb_write_data; // Datos a escribir en el registro
    wire [4:0] wb_rd; // Registro destino para la etapa WB
    wire wb_reg_write; // Señal de escritura de registro para la etapa WB
    wire wb_mem_to_reg; // Señal de escritura de registro desde memoria para la etapa WB
    wire [31:0] wb_alu_result; // Resultado de la ALU para la etapa WB
    wire wb_isJal;
    wire [31:0] wb_pc_plus_8; // PC + 8 para la etapa WB
    wire wb_halt; // Señal de parada para la etapa WB

    // Regs and Mem data wires
    wire [31:0] reg_data_wire; // Datos de los registros
    wire [31:0] mem_data_wire; // Datos de la memoria

    IF if_stage (
        .i_clk(i_clk),
        .i_clk_en(i_clk_en & ~halt_latched), // Enable clock signal
        .i_reset(i_reset),
        .i_stall(stall), // No stall signal for now
        .i_pcsrc(pcsrc), // No branch taken for now
        .i_jump(jump), // No jump for now
        .i_write_en(i_du_write_en), // No write enable for instruction memory
        .i_read_en(i_du_read_en), // Always read from instruction memory
        .i_data(i_du_data), // No data to write in instruction memory
        .i_addr_wr(i_du_inst_addr_wr), // No address to write in instruction memory
        .i_beq_dir(if_beq_jump_dir), // No branch direction for now
        .i_prev_instruction(id_instruction), // Previous instruction for debug unit
        .i_jr_jump_addr(id_ex_data_1), // Jump address for JR
        .i_jumpSel(jumpSel), // Jump select signal for JR

        .o_pc_plus_4(if_id_pc_plus_4), // Output PC + 4 (not connected)
        .o_instruction(if_id_instruction) // Output instruction (not connected)
    );

    IF_ID if_id_segmentation_register (
        .clk(i_clk), // Clock signal, not latched if halted
        .clk_en(i_clk_en & ~halt_latched), // Enable clock signal
        .reset(i_reset),
        .if_pc_plus_4(if_id_pc_plus_4), // PC + 4 from IF stage (not connected)
        .if_instruction(if_id_instruction), // Instruction from IF stage (not connected)
        .stall(stall | halt_latched), // No stall signal for now
        .flush(flush_idex | jump | jumpSel), // Flush signal for ID/EX stage

        .id_pc_plus_4(id_pc_plus_4), // Output PC + 4 for ID stage (not connected)
        .id_rs(id_rs), // Output rs for ID stage (not connected)
        .id_rt(id_rt), // Output rt for ID stage (not connected)
        .id_rd(id_rd), // Output rd for ID stage (not connected)
        .id_beq_offset(id_beq_offset), // Output BEQ offset for ID stage (not connected)
        .id_opcode(id_opcode), // Output opcode for ID stage (not connected)
        .id_function_code(id_function_code), // Output function code for ID stage (not connected)
        .id_instruction(id_instruction)
    );

    ID id_stage (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_rs(id_rs), // rs input (not connected)
        .i_rt(id_rt), // rt input (not connected)
        .i_rd(id_rd), // rd input (not connected)
        .i_data_write(wb_write_data), // Data to write in register file (not connected)
        .i_m_wb_rd(wb_rd), // Write back rd from MEM stage (not connected)
        .i_m_wb_reg_write(wb_reg_write), // Write back reg write signal from MEM stage (not connected)
        .i_pc_plus_4(id_pc_plus_4), // PC + 4 from IF_ID stage (not connected)
        .i_beq_offset(id_beq_offset), // BEQ offset from IF_ID stage (not connected)
        .i_opcode(id_opcode), // Opcode from IF_ID stage (not connected)
        .i_function_code(id_function_code), // Function code from IF_ID stage (not connected)
        .i_id_ex_reg_write(ex_reg_write), // Reg write signal from EX stage (not connected)
        .i_id_ex_mem_read(ex_read), // Mem read signal from EX stage (not connected)
        .i_ex_m_alu_result(ex_m_alu_result), // ALU result from EX/MEM stage (not connected)
        .i_m_alu_result(m_alu_result), // ALU result from MEM stage (not connected)
        .i_mem_data_readed(m_wb_read_data), // Read data from MEM stage (not connected)
        .i_m_mem_read(m_mem_read), // Mem read signal from MEM stage (not connected)
        .i_ex_rd(ex_m_rd), // rd from EX/MEM stage (not connected)
        .i_m_rd(m_rd), // rd from MEM stage (not connected)
        .i_id_ex_rt(ex_rt), // rt from ID/EX stage (not connected)
        .i_ex_reg_write(ex_reg_write), // Reg write signal from EX/MEM stage (not connected)
        .i_m_reg_write(m_reg_write), // Reg write signal from MEM/WB stage (not connected)
        .i_m_memtoreg(m_mem_to_reg), // Mem to reg signal from EX/MEM stage (not connected)
        .i_du_reg_addr(i_du_reg_addr), // Register address for debug unit

        .o_pc_src(pcsrc), // Output pcsrc signal
        .o_data_1(id_ex_data_1), // Output data 1 for ID stage (not connected)
        .o_data_2(id_ex_data_2), // Output data 2 for ID stage (not connected)
        .o_rs(id_ex_rs), // Output rs for ID stage (not connected)
        .o_rt(id_ex_rt), // Output rt for ID stage (not connected)
        .o_rd(id_ex_rd), // Output rd for ID stage (not connected)
        .o_function_code(id_ex_function_code), // Output function code for ID stage (not connected)
        .o_extended_beq_offset(id_ex_extended_beq_offset), // Output extended BEQ offset for ID stage (not connected)
        .o_beq_jump_dir(if_beq_jump_dir), // Output BEQ jump direction
        .o_reg_dest(id_ex_reg_dest), // Output reg dest signal for ID stage (not connected)
        .o_alu_src(id_ex_alu_src), // Output ALU src signal for ID stage (not connected)
        .o_alu_op(id_ex_alu_op), // Output ALU operation for ID stage (not connected)
        .o_mem_read(id_ex_mem_read), // Output mem read signal for ID stage (not connected)
        .o_mem_write(id_ex_mem_write), // Output mem write signal for ID stage (not connected)
        .o_mem_to_reg(id_ex_mem_to_reg), // Output mem to reg signal for ID stage (not connected)
        .o_reg_write(id_ex_reg_write), // Output reg write signal for ID stage (not connected)
        .o_jump(jump), // Output jump signal for ID stage (not connected)
        .o_isJal(id_ex_isJal), // Output isJal signal for ID stage (not connected)
        .o_pc_plus_8(id_ex_pc_plus_8), // Output PC + 8 for ID stage (not connected)
        .o_jalSel(id_ex_jalSel), // Output jalSel signal for ID stage (not connected)
        .o_jumpSel(jumpSel), // Output jump select signal for JR
        .o_bhw_type(id_ex_bhw_type), // Output bhw type signal for
        .o_flush(flush_idex), // Output flush ID/EX signal for ID stage (not connected)
        .o_stall(stall), // Output stall signal for ID stage (not connected)p signal for ID stage (not connected)
        .o_halt(id_ex_halt), // Output halt signal for ID stage (not connected)
        .o_du_reg_data(reg_data_wire)
    );  
    
    ID_EX id_ex_segmentation_register (
        .clk(i_clk),
        .clk_en(i_clk_en), // Enable clock signal
        .reset(i_reset),
        .id_dato_1(id_ex_data_1), // Data 1 from ID stage (not connected)
        .id_dato_2(id_ex_data_2), // Data 2 from ID stage (not connected)
        .id_rs(id_ex_rs), // rs from ID stage (not connected)
        .id_rt(id_ex_rt), // rt from ID stage (not connected)
        .id_rd(id_ex_rd), // rd from ID stage (not connected)
        .id_extended_beq_offset(id_ex_extended_beq_offset), // Extended BEQ offset from ID stage (not connected)
        .id_function_code(id_ex_function_code), // Function code from ID stage (not connected)
        .id_ex_reg_dst(id_ex_reg_dest), // Reg dest signal from ID stage (not connected)
        .id_ex_alu_src(id_ex_alu_src), // ALU src signal from ID stage (not connected)
        .id_ex_alu_op(id_ex_alu_op), // ALU operation from ID stage (not connected)
        .id_m_mem_read(id_ex_mem_read), // Mem read signal from ID stage (not connected)
        .id_m_mem_write(id_ex_mem_write), // Mem write signal from ID stage (not connected)
        .id_wb_mem_to_reg(id_ex_mem_to_reg), // Mem to reg signal from ID stage (not connected)
        .id_wb_reg_write(id_ex_reg_write), // Reg write signal from ID stage (not connected)
        .id_ex_isJal(id_ex_isJal), // JAL signal from ID stage (not connected)
        .id_ex_jalSel(id_ex_jalSel), // JALR signal from ID stage (not connected)
        .id_ex_pc_plus_8(id_ex_pc_plus_8), // PC + 8 for ID/EX stage (not connected)
        .id_bhw_type(id_ex_bhw_type), // BHW type signal from ID stage (not connected)
        .id_ex_halt(id_ex_halt), // Halt signal from ID stage (not connected)
        .id_stall(stall), // Stall signal for ID/EX stage

        .ex_dato_1(ex_data_1), // Output data 1 for EX stage (not connected)
        .ex_dato_2(ex_data_2), // Output data 2 for EX stage (not connected)
        .ex_rs(ex_rs), // Output rs for EX stage (not connected)
        .ex_rt(ex_rt), // Output rt for EX stage (not connected)
        .ex_rd(ex_rd), // Output rd for EX stage (not connected)
        .ex_function_code(ex_function_code), // Output function code for EX stage (not connected)
        .ex_extended_beq_offset(ex_extended_beq_offset), // Output extended BEQ offset for EX stage (not connected)
        .ex_reg_dst(ex_reg_dest), // Output reg dest signal for EX stage (not connected)
        .ex_alu_src(ex_alu_src), // Output ALU src signal for EX stage (not connected)
        .ex_alu_op(ex_alu_op), // Output ALU operation for EX stage (not connected)
        .ex_m_mem_read(ex_read), // Output mem read signal for EX stage (not connected)
        .ex_m_mem_write(ex_write), // Output mem write signal for EX stage (not connected)
        .ex_wb_mem_to_reg(ex_to_reg), // Output mem to reg signal for EX stage (not connected)
        .ex_wb_reg_write(ex_reg_write), // Output reg write signal for EX stage (not connected)
        .ex_isJal(ex_isJal), // Output isJal signal for EX stage (not connected)
        .ex_jalSel(ex_jalSel), // Output jalSel signal for EX stage (not connected)
        .ex_pc_plus_8(ex_pc_plus_8), // Output PC + 8 for EX stage (not connected)
        .ex_bhw_type(ex_bhw_type), // Output bhw type signal for EX stage (not connected)
        .ex_halt(ex_halt) // Output halt signal for EX stage (not connected)
    );  

    EX ex_stage (
        .i_id_ex_data_1(ex_data_1), // Data 1 from ID stage (not connected)
        .i_id_ex_data_2(ex_data_2), // Data 2 from ID stage (not connected)
        .i_id_ex_rs(ex_rs), // rs from ID stage (not connected)
        .i_id_ex_rt(ex_rt), // rt from ID stage (not connected)
        .i_id_ex_rd(ex_rd), // rd from ID stage (not connected)
        .i_id_ex_function_code(ex_function_code), // Function code from ID stage (not connected)
        .i_id_ex_extended_beq_offset(ex_extended_beq_offset), // Extended BEQ offset from ID stage (not connected)
        .i_id_ex_reg_dst(ex_reg_dest), // Reg dest signal from ID stage (not connected)
        .i_id_ex_alu_src(ex_alu_src), // ALU src signal from ID stage (not connected)
        .i_id_ex_alu_op(ex_alu_op), // ALU operation from ID stage (not connected)
        .i_id_ex_mem_read(ex_read), // Mem read signal from ID stage (not connected)
        .i_id_ex_mem_write(ex_write), // Mem write signal from ID stage (not connected)
        .i_id_ex_mem_to_reg(ex_to_reg), // Mem to reg signal from ID stage (not connected)
        .i_id_ex_reg_write(ex_reg_write), // Reg write signal from ID stage (not connected)
        .i_m_wb_data_write(m_wb_read_data), // Data to write in register file (not connected)
        .i_ex_m_alu_result(m_alu_result), // ALU result from EX stage (not connected)
        .i_ex_m_reg_write(m_reg_write), // Reg write signal from EX stage (not connected)
        .i_ex_m_rd(m_rd), // rd from EX stage (not connected)
        .i_m_wb_reg_write(m_wb_reg_write), // Reg write signal from MEM stage (not connected)
        .i_m_wb_rd(m_wb_rd), // Write back rd from MEM stage (not connected)
        .i_id_ex_isJal(ex_isJal), // JAL signal from EX stage (not connected)
        .i_id_ex_jalSel(ex_jalSel), // JALR signal from EX stage (not connected)
        .i_id_ex_pc_plus_8(ex_pc_plus_8), // PC + 8 for EX stage (not connected)
        .i_ex_m_bhw_type(ex_bhw_type), // BHW type signal from EX stage (not connected)
        .i_ex_m_halt(ex_halt), // Halt signal from EX stage (not connected)

        .o_ex_m_alu_result(ex_m_alu_result), // Output ALU result for EX stage (not connected)
        .o_ex_m_write_data(ex_m_write_data), // Output write data for EX stage
        .o_ex_m_rd(ex_m_rd), // Output rd for EX stage (not connected)
        .o_ex_m_mem_read(ex_m_mem_read), // Output mem read signal for EX stage (not connected)
        .o_ex_m_mem_write(ex_m_mem_write), // Output mem write signal for EX stage (not connected)
        .o_ex_m_mem_to_reg(ex_m_mem_to_reg), // Output mem to reg signal for EX stage (not connected)
        .o_ex_m_reg_write(ex_m_reg_write), // Output reg write signal for EX stage (not connected)
        .o_ex_m_isJal(ex_m_isJal), // Output isJal signal for EX stage (not connected)
        .o_ex_m_pc_plus_8(ex_m_pc_plus_8), // Output PC + 8 for EX stage (not connected)
        .o_ex_m_bhw_type(ex_m_bhw_type), // Output bhw type signal for EX stage (not connected)
        .o_ex_m_halt(ex_m_halt) // Output halt signal for EX stage (not connected)
    );

    EX_M ex_m_segmentation_register (
        .i_clk(i_clk),
        .i_clk_en(i_clk_en), // Enable clock signal
        .i_reset(i_reset),
        .i_ex_alu_result(ex_m_alu_result), // ALU result from EX
        .i_ex_write_data(ex_m_write_data), // Write data from EX stage
        .i_ex_rd(ex_m_rd), // rd from EX stage
        .i_ex_m_mem_read(ex_m_mem_read), // Mem read signal from EX stage
        .i_ex_m_mem_write(ex_m_mem_write), // Mem write signal from EX stage
        .i_ex_m_mem_to_reg(ex_m_mem_to_reg), // Mem to reg signal
        .i_ex_m_reg_write(ex_m_reg_write), // Reg write signal from EX stage
        .i_ex_m_isJal(ex_m_isJal), // isJal signal from EX stage
        .i_ex_m_pc_plus_8(ex_m_pc_plus_8), // PC + 8 from EX stage
        .i_ex_m_bhw_type(ex_m_bhw_type), // BHW type signal from EX stage
        .i_ex_m_halt(ex_m_halt), // Halt signal from EX stage

        .o_ex_m_alu_result(m_alu_result), // Output ALU result for MEM stage
        .o_ex_m_write_data(m_write_data), // Output write data for MEM stage
        .o_ex_m_rd(m_rd), // Output rd for MEM stage
        .o_ex_m_mem_read(m_mem_read), // Output mem read signal for MEM stage
        .o_ex_m_mem_write(m_mem_write), // Output mem write signal for MEM stage
        .o_ex_m_mem_to_reg(m_mem_to_reg), // Output mem to reg signal
        .o_ex_m_reg_write(m_reg_write), // Output reg write signal for MEM stage
        .o_ex_m_isJal(m_isJal), // Output isJal signal for MEM stage
        .o_ex_m_pc_plus_8(m_pc_plus_8), // Output PC + 8 for MEM stage
        .o_ex_m_bhw_type(m_bhw_type), // Output bhw type signal for MEM stage
        .o_ex_m_halt(m_halt) // Output halt signal for MEM stage
    );

    MEM mem_stage (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_mem_alu_result_or_addr(m_alu_result),
        .i_mem_write_data(m_write_data),
        .i_mem_rd(m_rd),
        .i_m_mem_read(m_mem_read),
        .i_m_mem_write(m_mem_write),
        .i_m_mem_to_reg(m_mem_to_reg),
        .i_m_reg_write(m_reg_write),
        .i_m_isJal(m_isJal),
        .i_m_pc_plus_8(m_pc_plus_8), // PC + 8 from EX stage
        .i_m_bhw_type(m_bhw_type),
        .i_du_mem_addr(i_du_mem_addr), // Address for debug unit
        .i_m_halt(m_halt),

        .o_m_wb_read_data(m_wb_read_data),
        .o_m_rd(m_wb_rd),
        .o_m_wb_rd(m_wb_rd),
        .o_m_wb_alu_result(m_wb_alu_result),
        .o_m_wb_mem_to_reg(m_wb_mem_to_reg),
        .o_m_wb_reg_write(m_wb_reg_write),
        .o_du_mem_data(mem_data_wire), // Data read from memory for debug unit
        .o_m_wb_isJal(m_wb_isJal),           // JAL signal for debug unit
        .o_m_wb_pc_plus_8(m_wb_pc_plus_8), // PC + 8 for WB stage
        .o_m_wb_halt(m_wb_halt)          // Halt signal for WB stage
    );

    M_WB m_wb_segmentation_register (
        .i_clk(i_clk),
        .i_clk_en(i_clk_en), // Enable clock signal
        .i_reset(i_reset),
        .i_m_read_data(m_wb_read_data),
        .i_m_rd(m_wb_rd),
        .i_m_alu_result(m_wb_alu_result),
        .i_m_mem_to_reg(m_wb_mem_to_reg),
        .i_m_reg_write(m_wb_reg_write),
        .i_m_isJal(m_wb_isJal),
        .i_m_pc_plus_8(m_wb_pc_plus_8),
        .i_m_halt(m_wb_halt),

        .o_wb_data(wb_data),
        .o_wb_rd(wb_rd),
        .o_wb_mem_to_reg(wb_mem_to_reg),
        .o_wb_reg_write(wb_reg_write),
        .o_wb_alu_result(wb_alu_result),
        .o_wb_isJal(wb_isJal),
        .o_wb_pc_plus_8(wb_pc_plus_8),
        .o_wb_halt(wb_halt)
    );

    WB wb_stage (
        .i_wb_data(wb_data),
        .i_wb_mem_to_reg(wb_mem_to_reg),
        .i_wb_alu_result(wb_alu_result),
        .i_wb_pc_plus_8(wb_pc_plus_8), // PC + 4 from IF stage
        .i_wb_halt(wb_halt),
        .i_wb_isJal(wb_isJal),

        .o_wb_write_data(wb_write_data),
        .o_wb_halt(end_program)
    );

    always @(*) begin
        if (i_reset)
            halt_latched <= 1'b0;
        else if (end_program)
            halt_latched <= 1'b1;
    end

    initial i_clk = 0;
    always #5 i_clk = ~i_clk;

    initial begin 
        i_reset = 1;
        i_clk_en = 0; // Enable clock signal
        i_du_data = 32'h00000000; // No data to write in debug
        i_du_inst_addr_wr = 32'h00000000; // No address to write in debug
        i_du_mem_addr = 8'h00; // No address to write in debug memory
        i_du_reg_addr = 5'b00000; // No register address to write in debug
        i_du_write_en = 0; // No write enable for debug unit
        i_du_read_en = 0; // Always read from debug unit
        #10 i_reset = 0; // Release reset after 10 time units

        i_du_data = 32'b001001_00001_00010_0000000000000001; // ADDIU instruction
        i_du_inst_addr_wr = 32'd0; // Address to write instruction
        i_du_mem_addr = 8'h00; // Address to write instruction in debug memory
        i_du_reg_addr = 5'd8;
        i_du_write_en = 1; // Enable write for debug unit
        i_du_read_en = 0; // Enable read for debug unit
        #10 i_du_write_en = 0; // Disable write for debug unit

        i_du_data = 32'b001001_00001_00011_0000000000000001; // ADDIU instruction
        i_du_inst_addr_wr = 32'd4; // Address to write instruction
        i_du_mem_addr = 8'h00; // Address to write instruction in debug memory
        i_du_reg_addr = 5'd8;
        i_du_write_en = 1; // Enable write for debug unit
        i_du_read_en = 0; // Enable read for debug unit
        #10 i_du_write_en = 0; // Disable write for debug unit

        i_du_data = 32'b000011_00000000000000000000000111; // JAL instruction
        i_du_inst_addr_wr = 32'd8; // Address to write instruction
        i_du_mem_addr = 8'h00; // Address to write instruction in debug memory
        i_du_reg_addr = 5'd0;
        i_du_write_en = 1; // Enable write for debug unit
        i_du_read_en = 0; // Enable read for debug unit
        #10 i_du_write_en = 0; // Disable write for debug unit

        i_du_data = 32'b001001_00001_00000_0000000000000000; // ADDIU instruction
        i_du_inst_addr_wr = 32'd12; // Address to write instruction
        i_du_mem_addr = 8'h00; // Address to write instruction in debug memory
        i_du_reg_addr = 5'd4;
        i_du_write_en = 1; // Enable write for debug unit
        i_du_read_en = 0; // Enable read for debug unit
        #10 i_du_write_en = 0; // Disable write for debug unit

        i_du_data = 32'b001001_00001_00000_0000000000000000; // ADDIU instruction
        i_du_inst_addr_wr = 32'd16; // Address to write instruction
        i_du_mem_addr = 8'h00; // Address to write instruction in debug memory
        i_du_reg_addr = 5'd4;
        i_du_write_en = 1; // Enable write for debug unit
        i_du_read_en = 0; // Enable read for debug unit
        #10 i_du_write_en = 0; // Disable write for debug unit

        i_du_data = 32'b001001_00001_00000_0000000000000000; // ADDIU instruction
        i_du_inst_addr_wr = 32'd20; // Address to write instruction
        i_du_mem_addr = 8'h00; // Address to write instruction in debug memory
        i_du_reg_addr = 5'd4;
        i_du_write_en = 1; // Enable write for debug unit
        i_du_read_en = 0; // Enable read for debug unit
        #10 i_du_write_en = 0; // Disable write for debug unit

        i_du_data = 32'b001001_00001_00000_0000000000000000; // ADDIU instruction
        i_du_inst_addr_wr = 32'd24; // Address to write instruction
        i_du_mem_addr = 8'h00; // Address to write instruction in debug memory
        i_du_reg_addr = 5'd4;
        i_du_write_en = 1; // Enable write for debug unit
        i_du_read_en = 0; // Enable read for debug unit
        #10 i_du_write_en = 0; // Disable write for debug unit
        
        i_du_data = 32'b001001_00010_00010_0000000000000001; // ADDIU instruction
        i_du_inst_addr_wr = 32'd28; // Address to write instruction
        i_du_mem_addr = 8'h00; // Address to write instruction in debug memory
        i_du_reg_addr = 5'd8;
        i_du_write_en = 1; // Enable write for debug unit
        i_du_read_en = 0; // Enable read for debug unit
        #10 i_du_write_en = 0; // Disable write for debug unit

        i_du_data = 32'b001001_00011_00011_0000000000000001; // ADDIU instruction
        i_du_inst_addr_wr = 32'd32; // Address to write instruction
        i_du_mem_addr = 8'h00; // Address to write instruction in debug memory
        i_du_reg_addr = 5'd8;
        i_du_write_en = 1; // Enable write for debug unit
        i_du_read_en = 0; // Enable read for debug unit
        #10 i_du_write_en = 0; // Disable write for debug unit

        i_du_data = 32'b000110_11111_000000000000001000001; // JR instruction
        i_du_inst_addr_wr = 32'd36; // Address to write instruction
        i_du_mem_addr = 8'h00; // Address to write instruction in debug memory
        i_du_reg_addr = 5'd8;
        i_du_write_en = 1; // Enable write for debug unit
        i_du_read_en = 0; // Enable read for debug unit
        #10 i_du_write_en = 0; // Disable write for debug unit

        i_du_data = 32'b001001_00001_00000_0000000000000000; // ADDIU instruction
        i_du_inst_addr_wr = 32'd40; // Address to write instruction
        i_du_mem_addr = 8'h00; // Address to write instruction in debug memory
        i_du_reg_addr = 5'd4;
        i_du_write_en = 1; // Enable write for debug unit
        i_du_read_en = 0; // Enable read for debug unit
        #10 i_du_write_en = 0; // Disable write for debug unit

        i_du_data = 32'hFC000000; // ADDIU instruction
        i_du_inst_addr_wr = 32'd44; // Address to write instruction
        i_du_mem_addr = 8'h00; // Address to write instruction in debug memory
        i_du_reg_addr = 5'd4;
        i_du_write_en = 1; // Enable write for debug unit
        i_du_read_en = 0; // Enable read for debug unit
        #10 i_du_write_en = 0; // Disable write for debug unit

        i_du_read_en = 1; // Enable read for debug unit
        i_clk_en = 1;
        #10; 
        i_clk_en = 0; 
        #10
        i_clk_en = 1;
        #10; 
        i_clk_en = 0; 
        #10
        i_clk_en = 1;
        #10; 
        i_clk_en = 0; 
        #10
        i_clk_en = 1;
        #10; 
        i_clk_en = 0; 
        #10
        i_clk_en = 1;
        #10; 
        i_clk_en = 0; 
        #10
        i_clk_en = 1;
        #10; 
        i_clk_en = 0; 
        #10
        i_clk_en = 1;
        #10; 
        i_clk_en = 0; 
        #10
        i_clk_en = 1;
        #10; 
        i_clk_en = 0; 
        #10
        i_clk_en = 1;
        #10; 
        i_clk_en = 0; 
        #10
        i_clk_en = 1;
        #10; 
        i_clk_en = 0; 
        #10
        i_clk_en = 1;
        #10; 
        i_clk_en = 0; 
        #10
        i_clk_en = 1;
        #10; 
        i_clk_en = 0; 
        #10
        i_clk_en = 1;
        #10; 
        i_clk_en = 0; 
        #10
        i_clk_en = 1;
        #10; 
        i_clk_en = 0; 
        #10
        i_clk_en = 1;
        #10; 
        i_clk_en = 0;
        #10;
        i_clk_en = 1;
        #10; 
        i_clk_en = 0;
        #10;
        i_clk_en = 1;
        #10; 
        i_clk_en = 0;
        #10;
        i_clk_en = 1;
        #10; 
        i_clk_en = 0;
        #10;
        i_clk_en = 1;
        #10; 
        i_clk_en = 0;
        #10;
        i_clk_en = 1;
        #10; 
        i_clk_en = 0;
        #10;
        i_clk_en = 1;
        #10; 
        i_clk_en = 0;
        i_du_read_en = 0; // Disable read for debug unit
        #100; // Wait for some time to observe the behavior
        $finish; // End simulation
    end


endmodule