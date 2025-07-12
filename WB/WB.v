`timescale 1ns / 1ps

module WB (
    input wire [31:0] i_wb_data,
    input wire i_wb_mem_to_reg,
    input wire [31:0] i_wb_alu_result,
    input wire i_wb_reg_write,
    input wire [4:0] i_wb_rd, 

    output wire [31:0] o_wb_write_data
);

    assign o_wb_write_data = i_wb_mem_to_reg ? i_wb_data : i_wb_alu_result;

endmodule
