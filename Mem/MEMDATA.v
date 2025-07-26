`timescale 1ns / 1ps

module MEMDATA (
    input wire i_clk,
    input wire i_reset,
    input wire [31:0] mem_addr,
    input wire [31:0] mem_data_in,
    input wire mem_write_enable,
    input wire [31:0] du_mem_addr,

    output wire [31:0] mem_data_out,
    output wire [31:0] du_mem_data
);
    reg [7:0] memory [0:255]; // Memoria de 256 bytes (64 palabras de 32 bits)
    integer j;

    always @(posedge i_clk or posedge i_reset) begin
        if (i_reset) begin
            // Resetea la memoria a ceros
            for (j = 0; j < 256; j = j + 1) begin
                memory[j] <= 8'b0;
            end
        end else if (mem_write_enable) begin
            memory[mem_addr]     <= mem_data_in[7:0];
            memory[mem_addr + 1] <= mem_data_in[15:8];
            memory[mem_addr + 2] <= mem_data_in[23:16];
            memory[mem_addr + 3] <= mem_data_in[31:24];
        end 
    end

    assign mem_data_out = {memory[mem_addr+3], memory[mem_addr+2], memory[mem_addr+1], memory[mem_addr]};
    assign du_mem_data = {memory[du_mem_addr+3], memory[du_mem_addr+2], memory[du_mem_addr+1], memory[du_mem_addr]};
endmodule