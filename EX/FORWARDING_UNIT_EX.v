`timescale 1ns / 1ps

module FORWARDING_UNIT_EX(
    input wire [4:0] id_ex_rs,               // Source register ID from ID stage
    input wire [4:0] id_ex_rt,               // Target register ID from ID stage
    input wire [4:0] ex_mem_rd,              // Destination register ID from EX stage
    input wire [4:0] mem_wb_rd,              // Destination register ID from MEM stage
    input wire ex_mem_reg_write,             // Write enable signal from EX stage
    input wire mem_wb_reg_write,             // Write enable signal from MEM stage
    output wire [1:0] forward_a,              // Forwarding control for source A
    output wire [1:0] forward_b               // Forwarding control for source B
);

    reg [1:0] a;
    reg [1:0] b;

    assign forward_a = a;
    assign forward_b = b;

    always @(*) begin
        // Forwarding for source A
        if (ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs)) begin
            a = 2'b01; // Forward from EX stage
        end else if (mem_wb_reg_write && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rs)) begin
            a = 2'b10; // Forward from MEM stage
        end else begin
            a = 2'b00; // No forwarding
        end

        // Forwarding for source B
        if (ex_mem_reg_write && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rt)) begin
            b = 2'b01; // Forward from EX stage
        end else if (mem_wb_reg_write && (mem_wb_rd != 0) && (mem_wb_rd == id_ex_rt)) begin
            b = 2'b10; // Forward from MEM stage
        end else begin
            b = 2'b00; // No forwarding
        end
    end

endmodule