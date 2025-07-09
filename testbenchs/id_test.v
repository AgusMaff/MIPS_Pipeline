`timescale 1ns / 1ps

module id_tb;

    // Entradas generales
    reg         clk;
    reg         reset;
    reg  [4:0]  rs, rt, rd;
    reg  [31:0] data_write;
    reg  [4:0]  m_wb_rd;
    reg         m_wb_reg_write;
    reg  [31:0] pc_plus_4;
    reg  [15:0] beq_offset;
    reg  [5:0]  opcode;
    reg  [5:0]  function_code;
    reg         id_ex_reg_write;
    reg         id_ex_mem_read;
    reg  [31:0] ex_alu_result;
    reg  [4:0]  ex_m_rd;
    reg  [4:0]  id_ex_rt;
    reg         ex_m_reg_write;
    reg         ex_m_memtoreg;

    // Wires intermedios para debug
    wire [31:0] data_1, data_2;
    wire        branch;
    wire        reg_dest, alu_src, mem_read, mem_write, mem_to_reg, reg_write, jump;
    wire [2:0]  alu_op;
    wire        flush_idex, stall;
    wire        forward_a, forward_b;
    wire [31:0] o_data_1, o_data_2;
    wire [31:0] extended_beq_offset;
    wire [31:0] shifted_extended_beq_offset;
    wire [31:0] beq_jump_dir;
    wire        comparator_result;
    wire        pc_src;

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // REGMEM
    REGMEM regmem (
        .clk(clk),
        .reset(reset),
        .rs(rs),
        .rt(rt),
        .write_data(data_write),
        .reg_addr(m_wb_rd),
        .write_enable(m_wb_reg_write),
        .data_1(data_1),
        .data_2(data_2)
    );

    // CONTROL_UNIT
    CONTROL_UNIT control_unit (
        .enable(1'b1),
        .op_code(opcode),
        .branch(branch),
        .reg_dest(reg_dest),
        .alu_src(alu_src),
        .alu_op(alu_op),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .reg_write(reg_write),
        .jump(jump)
    );

    // HAZARD_UNIT
    HAZARD_UNIT hazard_unit (
        .branch(branch),
        .if_id_rs(rs),
        .if_id_rt(rt),
        .id_ex_rt(id_ex_rt),
        .ex_m_rd(ex_m_rd),
        .id_ex_mem_read(id_ex_mem_read),
        .id_ex_regwrite(id_ex_reg_write),
        .ex_m_memtoreg(ex_m_memtoreg),
        .flush_idex(flush_idex),
        .stall(stall)
    );

    // FORWARDING_UNIT_ID
    FORWARDING_UNIT_ID forwarding_unit_id (
        .rs_id(rs),
        .rt_id(rt),
        .rd_ex_m(ex_m_rd),
        .reg_write_ex_m(ex_m_reg_write),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    // MUX2TO1 para forwarding
    MUX2TO1 mux_forward_a (
        .input_1(data_1),
        .input_2(ex_alu_result),
        .selection_bit(forward_a),
        .mux(o_data_1)
    );

    MUX2TO1 mux_forward_b (
        .input_1(data_2),
        .input_2(ex_alu_result),
        .selection_bit(forward_b),
        .mux(o_data_2)
    );

    // SIGN_EXTEND
    SIGN_EXTEND sign_extend (
        .in(beq_offset),
        .out(extended_beq_offset)
    );

    // SHFT2L_ID
    SHFT2L_ID shft2l_id (
        .shift(extended_beq_offset),
        .shifted_data(shifted_extended_beq_offset)
    );

    // ALU para BEQ jump dir
    ALU adder (
        .data_a(pc_plus_4),
        .data_b(shifted_extended_beq_offset),
        .operation(4'b0011),
        .result(beq_jump_dir)
    );

    // COMPARATOR
    COMPARATOR comparator (
        .data_a(o_data_1),
        .data_b(o_data_2),
        .equal(comparator_result)
    );

    // AND para branch
    AND_ID and_id (
        .a(branch),
        .b(comparator_result),
        .result(pc_src)
    );

    // Proceso de prueba
    initial begin
        // Inicialización
        reset = 1;
        m_wb_reg_write = 0;
        data_write = 0;
        m_wb_rd = 0;
        rs = 0; rt = 0; rd = 0;
        opcode = 6'b000000;
        function_code = 6'b000000;
        beq_offset = 16'b0;
        pc_plus_4 = 32'd100;
        id_ex_reg_write = 0;
        id_ex_mem_read = 0;
        ex_alu_result = 32'hDEADBEEF;
        ex_m_rd = 0;
        id_ex_rt = 0;
        ex_m_reg_write = 0;
        ex_m_memtoreg = 0;
        #12;
        reset = 0;

        // Escribir en registro 1 y 2
        @(negedge clk);
        m_wb_reg_write = 1; m_wb_rd = 5'd1; data_write = 32'hAAAA_BBBB;
        @(negedge clk);
        m_wb_reg_write = 1; m_wb_rd = 5'd2; data_write = 32'h1234_5678;
        @(negedge clk);
        m_wb_reg_write = 0;

        // Leer registros 1 y 2
        rs = 5'd1; rt = 5'd2;
        #10;
        $display("Lectura: data_1 = %h, data_2 = %h", data_1, data_2);

        // Prueba de forwarding: simula que el resultado de la ALU de EX coincide con rs
        ex_m_rd = 5'd1; ex_m_reg_write = 1; ex_alu_result = 32'hCAFEBABE;
        #10;
        $display("Forwarding: o_data_1 = %h (debería ser CAFEBABE), o_data_2 = %h", o_data_1, o_data_2);

        // Prueba de hazard: simula un load-use hazard
        id_ex_mem_read = 1; id_ex_rt = 5'd1;
        #10;
        $display("Hazard: flush_idex = %b, stall = %b", flush_idex, stall);
        id_ex_mem_read = 0;

        // Prueba de branch y comparación
        opcode = 6'b000100; // suponer que esto activa branch
        rs = 5'd1; rt = 5'd1; // ambos iguales
        #10;
        $display("Branch: branch = %b, comparator_result = %b, pc_src = %b", branch, comparator_result, pc_src);

        $finish;
    end

    // Debug: muestra todas las señales relevantes
    initial begin
        $display("t | rs | rt | data_1 | data_2 | o_data_1 | o_data_2 | branch | flush | stall | forward_a | forward_b | pc_src");
        $monitor("%0dns | %d | %d | %h | %h | %h | %h | %b | %b | %b | %b | %b | %b",
            $time, rs, rt, data_1, data_2, o_data_1, o_data_2, branch, flush_idex, stall, forward_a, forward_b, pc_src);
    end

endmodule