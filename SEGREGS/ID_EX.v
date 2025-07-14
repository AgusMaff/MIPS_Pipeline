`timescale 1ns / 1ps

module ID_EX (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] id_dato_1,
    input  wire [31:0] id_dato_2,   
    input  wire [4:0]  id_rs,
    input  wire [4:0]  id_rt,
    input  wire [4:0]  id_rd,
    input  wire [31:0] id_extended_beq_offset,
    input  wire [5:0]  id_function_code,
    input  wire        id_ex_reg_dst,
    input  wire        id_ex_alu_src,
    input  wire [3:0]  id_ex_alu_op,
    input  wire        id_m_mem_read,
    input  wire        id_m_mem_write,
    input  wire        id_wb_mem_to_reg,
    input  wire        id_wb_reg_write,
    input  wire [2:0]  id_bhw_type,

    output reg [31:0] ex_dato_1,
    output reg [31:0] ex_dato_2,
    output reg [4:0]  ex_rs,
    output reg [4:0]  ex_rt,
    output reg [4:0]  ex_rd,
    output reg [5:0]  ex_function_code,
    output reg [31:0] ex_extended_beq_offset,
    output reg        ex_reg_dst,
    output reg        ex_alu_src,
    output reg [3:0]  ex_alu_op,
    output reg        ex_m_mem_read,
    output reg        ex_m_mem_write,
    output reg        ex_wb_mem_to_reg,
    output reg        ex_wb_reg_write,
    output reg [2:0]  ex_bhw_type
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ex_dato_1 <= 32'b0;
            ex_dato_2 <= 32'b0;
            ex_rs <= 5'b0;
            ex_rt <= 5'b0;
            ex_rd <= 5'b0;
            ex_function_code <= 6'b0;
            ex_extended_beq_offset <= 32'b0;
            ex_reg_dst <= 1'b0;
            ex_alu_src <= 1'b0;
            ex_alu_op <= 4'b0;
            ex_m_mem_read <= 1'b0;
            ex_m_mem_write <= 1'b0;
            ex_wb_mem_to_reg <= 1'b0;
            ex_wb_reg_write <= 1'b0;
            ex_bhw_type <= 3'b0;
        end else begin
            ex_dato_1 <= id_dato_1;
            ex_dato_2 <= id_dato_2;   
            ex_rs <= id_rs;
            ex_rt <= id_rt;
            ex_rd <= id_rd;
            ex_function_code <= id_function_code;
            ex_extended_beq_offset <= id_extended_beq_offset;
            ex_reg_dst <= id_ex_reg_dst;
            ex_alu_src <= id_ex_alu_src;
            ex_alu_op <= id_ex_alu_op;
            ex_m_mem_read <= id_m_mem_read;
            ex_m_mem_write <= id_m_mem_write;
            ex_wb_mem_to_reg <= id_wb_mem_to_reg;
            ex_wb_reg_write <= id_wb_reg_write; 
            ex_bhw_type <= id_bhw_type;
        end
    end
endmodule