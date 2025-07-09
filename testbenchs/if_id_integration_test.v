`timescale 1ns / 1ps

module if_id_integration_test;

    // Señales de control y dato
    reg         clk;
    reg         reset;
    reg         stall;
    reg         pcsrc;
    reg         jump;
    reg         write_en;
    reg         read_en;
    reg  [31:0] data;
    reg  [31:0] addr_wr;
    reg  [31:0] beq_dir;

    // IF outputs
    wire [31:0] if_pc_plus_4;
    wire [31:0] if_instruction;

    // IF/ID outputs
    wire [31:0] id_pc_plus_4;
    wire [4:0]  id_rs;
    wire [4:0]  id_rt;
    wire [4:0]  id_rd;
    wire [15:0] id_beq_offset;
    wire [4:0]  id_opcode;
    wire [4:0]  id_function_code;

    // ID outputs
    wire        o_pc_src;
    wire [31:0] o_data_1;
    wire [31:0] o_data_2;
    wire [4:0]  o_rs;
    wire [4:0]  o_rt;
    wire [4:0]  o_rd;
    wire [4:0]  o_function_code;
    wire [31:0] o_extended_beq_offset;
    wire [31:0] o_beq_jump_dir;
    wire        o_reg_dest;
    wire        o_alu_src;
    wire [3:0]  o_alu_op;
    wire        o_mem_read;
    wire        o_mem_write;
    wire        o_mem_to_reg;
    wire        o_reg_write;
    wire        o_jump;
    wire        o_flush_idex;
    wire        o_stall;

    // ID/EX outputs
    wire [31:0] ex_dato_1;
    wire [31:0] ex_dato_2;
    wire [4:0]  ex_rs;
    wire [4:0]  ex_rt;
    wire [4:0]  ex_rd;
    wire [31:0] ex_extended_beq_offset;
    wire        ex_reg_dst;
    wire        ex_alu_src;
    wire [2:0]  ex_alu_op;
    wire        ex_m_mem_read;
    wire        ex_m_mem_write;
    wire        ex_wb_mem_to_reg;
    wire        ex_wb_reg_write;

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Instancia IF
    IF if_stage (
        .i_clk(clk),
        .i_reset(reset),
        .i_stall(stall),
        .i_pcsrc(pcsrc),
        .i_jump(jump),
        .i_write_en(write_en),
        .i_read_en(read_en),
        .i_data(data),
        .i_addr_wr(addr_wr),
        .i_beq_dir(beq_dir),
        .o_pc_plus_4(if_pc_plus_4),
        .o_instruction(if_instruction)
    );

    // Instancia IF/ID
    IF_ID if_id_reg (
        .clk(clk),
        .reset(reset),
        .if_pc_plus_4(if_pc_plus_4),
        .if_instruction(if_instruction),
        .flush_idex(1'b0), // No flush en esta prueba
        .stall(1'b0),      // No stall en esta prueba
        .id_pc_plus_4(id_pc_plus_4),
        .id_rs(id_rs),
        .id_rt(id_rt),
        .id_rd(id_rd),
        .id_beq_offset(id_beq_offset),
        .id_opcode(id_opcode),
        .id_function_code(id_function_code)
    );

    // Instancia ID
    ID id_stage (
        .i_clk(clk),
        .i_reset(reset),
        .i_rs(id_rs),
        .i_rt(id_rt),
        .i_rd(id_rd),
        .i_data_write(32'b0), // No writeback en esta prueba
        .i_m_wb_rd(5'b0),
        .i_m_wb_reg_write(1'b0),
        .i_pc_plus_4(id_pc_plus_4),
        .i_beq_offset(id_beq_offset),
        .i_opcode({1'b0, id_opcode}), // Ajusta si tu opcode es de 6 bits
        .i_function_code({1'b0, id_function_code}), // Ajusta si tu funct es de 6 bits
        .i_id_ex_reg_write(1'b0),
        .i_id_ex_mem_read(1'b0),
        .i_ex_alu_result(32'b0),
        .i_ex_m_rd(5'b0),
        .i_id_ex_rt(5'b0),
        .i_ex_m_reg_write(1'b0),
        .i_ex_m_memtoreg(1'b0),
        .o_pc_src(o_pc_src),
        .o_data_1(o_data_1),
        .o_data_2(o_data_2),
        .o_rs(o_rs),
        .o_rt(o_rt),
        .o_rd(o_rd),
        .o_function_code(o_function_code),
        .o_extended_beq_offset(o_extended_beq_offset),
        .o_beq_jump_dir(o_beq_jump_dir),
        .o_reg_dest(o_reg_dest),
        .o_alu_src(o_alu_src),
        .o_alu_op(o_alu_op),
        .o_mem_read(o_mem_read),
        .o_mem_write(o_mem_write),
        .o_mem_to_reg(o_mem_to_reg),
        .o_reg_write(o_reg_write),
        .o_jump(o_jump),
        .o_flush_idex(o_flush_idex),
        .o_stall(o_stall)
    );

    // Instancia ID/EX
    ID_EX id_ex_reg (
        .clk(clk),
        .reset(reset),
        .id_dato_1(o_data_1),
        .id_dato_2(o_data_2),
        .id_rs(o_rs),
        .id_rt(o_rt),
        .id_rd(o_rd),
        .id_extended_beq_offset(o_extended_beq_offset),
        .id_ex_reg_dst(o_reg_dest),
        .id_ex_alu_src(o_alu_src),
        .id_ex_alu_op(o_alu_op),
        .id_m_mem_read(o_mem_read),
        .id_m_mem_write(o_mem_write),
        .id_wb_mem_to_reg(o_mem_to_reg),
        .id_wb_reg_write(o_reg_write),
        .ex_dato_1(ex_dato_1),
        .ex_dato_2(ex_dato_2),
        .ex_rs(ex_rs),
        .ex_rt(ex_rt),
        .ex_rd(ex_rd),
        .ex_extended_beq_offset(ex_extended_beq_offset),
        .ex_reg_dst(ex_reg_dst),
        .ex_alu_src(ex_alu_src),
        .ex_alu_op(ex_alu_op),
        .ex_m_mem_read(ex_m_mem_read),
        .ex_m_mem_write(ex_m_mem_write),
        .ex_wb_mem_to_reg(ex_wb_mem_to_reg),
        .ex_wb_reg_write(ex_wb_reg_write)
    );

    // Proceso de prueba
    initial begin
        // Inicialización
        reset = 1;
        stall = 0;
        pcsrc = 0;
        jump = 0;
        write_en = 0;
        read_en = 0;
        data = 0;
        addr_wr = 0;
        beq_dir = 0;
        #12;
        reset = 0;

        // Escribir instrucción tipo R: add $t1, $t2, $t3 (opcode=0, rs=10, rt=11, rd=9, funct=32)
        // instrucción: 000000 01010 01011 01001 00000 100000
        // binario:     000000 01010 01011 01001 00000 100000
        // hex:         0x014B4820
        @(negedge clk);
        write_en = 1; read_en = 0;
        data = 32'h014B4820;
        addr_wr = 0;
        @(negedge clk);
        write_en = 0; read_en = 1;

        // Esperar a que la instrucción pase por el pipeline
        repeat(6) @(posedge clk);

        $display("---- IF/ID/ID_EX Integration Test ----");
        $display("IF:    PC+4=%h  INSTR=%h", if_pc_plus_4, if_instruction);
        $display("IF_ID: PC+4=%h  rs=%d rt=%d rd=%d beq_offset=%h opcode=%h funct=%h",
            id_pc_plus_4, id_rs, id_rt, id_rd, id_beq_offset, id_opcode, id_function_code);
        $display("ID:    o_data_1=%h o_data_2=%h o_rs=%d o_rt=%d o_rd=%d o_function_code=%h o_alu_op=%b o_reg_write=%b",
            o_data_1, o_data_2, o_rs, o_rt, o_rd, o_function_code, o_alu_op, o_reg_write);
        $display("ID_EX: ex_dato_1=%h ex_dato_2=%h ex_rs=%d ex_rt=%d ex_rd=%d ex_alu_op=%b ex_wb_reg_write=%b",
            ex_dato_1, ex_dato_2, ex_rs, ex_rt, ex_rd, ex_alu_op, ex_wb_reg_write);

        $finish;
    end

    // Monitor para debug
    initial begin
        $monitor("t=%0dns | IF_ID: rs=%d rt=%d rd=%d opcode=%h funct=%h | ID: o_rs=%d o_rt=%d o_rd=%d o_alu_op=%b o_reg_write=%b",
            $time, id_rs, id_rt, id_rd, id_opcode, id_function_code, o_rs, o_rt, o_rd, o_alu_op, o_reg_write);
    end

endmodule


