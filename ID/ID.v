`timescale 1ns / 1ps

module ID (
    input  wire        i_clk,
    input  wire        i_reset,
    input  wire [4:0]  i_rs,
    input  wire [4:0]  i_rt,
    input  wire [4:0]  i_rd,
    input  wire [31:0] i_data_write,
    input  wire [4:0]  i_m_wb_rd,
    input  wire        i_m_wb_reg_write,
    input  wire [31:0] i_pc_plus_4,
    input  wire [15:0] i_beq_offset,
    input  wire [5:0]  i_opcode,
    input  wire [5:0]  i_function_code,
    input  wire        i_id_ex_reg_write,
    input  wire        i_id_ex_mem_read,
    input  wire [31:0] i_ex_m_alu_result,
    input  wire [31:0] i_m_alu_result,
    input  wire [4:0]  i_ex_m_rd,
    input  wire [4:0]  i_m_rd,
    input  wire [4:0]  i_id_ex_rt,
    input  wire        i_ex_m_reg_write,
    input  wire        i_m_reg_write,
    input  wire        i_ex_m_memtoreg,
    input  wire [4:0]  i_du_reg_addr,

    output wire        o_pc_src,
    output wire [31:0] o_data_1,
    output wire [31:0] o_data_2,
    output wire [4:0]  o_rs,
    output wire [4:0]  o_rt,
    output wire [4:0]  o_rd,
    output wire [5:0]  o_function_code,
    output wire [31:0] o_extended_beq_offset,
    output wire [31:0] o_beq_jump_dir,
    output wire        o_reg_dest,
    output wire        o_alu_src,
    output wire [3:0]  o_alu_op,
    output wire        o_mem_read,
    output wire        o_mem_write,
    output wire        o_mem_to_reg,
    output wire        o_reg_write,
    output wire        o_jump,
    output wire        o_isJal,
    output wire        o_jalSel,
    output wire        o_jumpSel, // Output jump select signal for JR
    output wire [31:0] o_pc_plus_8, // PC + 8 for JAL
    output wire [2:0]  o_bhw_type,
    output wire        o_flush_idex,
    output wire        o_stall,
    output wire        o_halt,
    output wire [31:0] o_du_reg_data
);

    wire [31:0] data_1;
    wire [31:0] data_2;
    wire        branch;
    wire        jumpSel;
    wire [1:0]  forward_a;
    wire [1:0]  forward_b;
    wire [31:0] shifted_extended_beq_offset;
    wire        comparator_result;
    wire        is_beq_signal;
    wire        mux_comparator_result;

    assign o_function_code = i_function_code;
    assign o_rs = i_rs;
    assign o_rt = i_rt;
    assign o_rd = i_rd;
    assign o_jumpSel = jumpSel;

    REGMEM regmem (
        .clk(i_clk),
        .reset(i_reset),
        .rs(i_rs),
        .rt(i_rt),
        .write_data(i_data_write),
        .reg_addr(i_m_wb_rd),
        .write_enable(i_m_wb_reg_write),
        .du_reg_addr(i_du_reg_addr),
        .du_reg_data(o_du_reg_data), 
        .data_1(data_1),
        .data_2(data_2)
    );

    CONTROL_UNIT control_unit (
        .enable(1'b1), 
        .op_code(i_opcode),
        .branch(branch),
        .is_beq(is_beq_signal),
        .reg_dest(o_reg_dest),
        .alu_src(o_alu_src),
        .alu_op(o_alu_op),
        .mem_read(o_mem_read),
        .mem_write(o_mem_write),
        .mem_to_reg(o_mem_to_reg),
        .reg_write(o_reg_write),
        .jump(o_jump),
        .isJal(o_isJal),
        .jalSel(o_jalSel),
        .jumpSel(jumpSel),
        .bhw_type(o_bhw_type),
        .halt(o_halt)
    );
    
    HAZARD_UNIT hazard_unit (
        .branch(branch),
        .if_id_rs(i_rs),
        .if_id_rt(i_rt),
        .id_ex_rt(i_id_ex_rt),
        .ex_rd(i_ex_m_rd),
        .m_rd(i_m_rd),
        .id_ex_mem_read(i_id_ex_mem_read),
        .id_ex_regwrite(i_id_ex_reg_write),
        .ex_m_memtoreg(i_ex_m_memtoreg),
        .flush_idex(o_flush_idex),
        .stall(o_stall)
    );

    FORWARDING_UNIT_ID forwarding_unit_id (
        .if_id_rs(i_rs),
        .if_id_rt(i_rt),
        .ex_m_rd(i_ex_m_rd),
        .m_rd(i_m_rd),
        .ex_m_reg_write(i_ex_m_reg_write),
        .m_reg_write(i_m_reg_write),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    MUX3TO1 mux_forward_a (
        .input_1(data_1),
        .input_2(i_ex_m_alu_result),
        .input_3(i_m_alu_result),
        .selection_bit(forward_a),
        .mux(o_data_1)
    );

    MUX3TO1 mux_forward_b (
        .input_1(data_2),
        .input_2(i_ex_m_alu_result),
        .input_3(i_m_alu_result),
        .selection_bit(forward_b),
        .mux(o_data_2)
    );

    SIGN_EXTEND sign_extend (
        .in(i_beq_offset),
        .out(o_extended_beq_offset)
    );

    SHFT2L_ID shft2l_id (
        .shift(o_extended_beq_offset),
        .shifted_data(shifted_extended_beq_offset)
    );

    ALU adder (
        .data_a(i_pc_plus_4),     
        .data_b(shifted_extended_beq_offset),             
        .operation(6'b100001),        
        .result(o_beq_jump_dir)        
    );

    ALU adder4 (
        .data_a(i_pc_plus_4),     
        .data_b(32'b00000000000000000000000000000100),             
        .operation(6'b100001),        
        .result(o_pc_plus_8)        
    );  

    COMPARATOR comparator (
        .data_a(o_data_1),
        .data_b(o_data_2),
        .equal(comparator_result)
    );

    MUX2To1_1BIT mux_is_beq (
        .input_1(comparator_result),
        .input_2(~comparator_result), //Resultado de comparacion negado
        .selection_bit(~is_beq_signal),
        .mux(mux_comparator_result)
    );

    AND_ID and_id (
        .a(branch),
        .b(mux_comparator_result),
        .result(o_pc_src)
    );
endmodule