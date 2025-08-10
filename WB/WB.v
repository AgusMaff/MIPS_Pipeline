`timescale 1ns / 1ps

module WB (
    input wire [31:0] i_wb_data,
    input wire i_wb_mem_to_reg,
    input wire [31:0] i_wb_alu_result,
    input wire [31:0] i_wb_pc_plus_8,
    input wire i_wb_isJal,
    input wire i_wb_halt,

    output wire [31:0] o_wb_write_data,
    output wire        o_wb_halt
);

    wire [31:0] alu_result_or_mem_data;

    assign alu_result_or_mem_data = i_wb_mem_to_reg ? i_wb_data : i_wb_alu_result;
    assign o_wb_write_data = i_wb_isJal ? i_wb_pc_plus_8 : alu_result_or_mem_data;
    assign o_wb_halt = i_wb_halt;

endmodule
