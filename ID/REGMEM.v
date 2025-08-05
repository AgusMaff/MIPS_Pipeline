`timescale 1ns / 1ps

module REGMEM (
    input  wire        clk,
    input  wire        reset,
    input  wire [4:0]  rs,     
    input  wire [4:0]  rt,      
    input  wire [31:0] write_data,
    input  wire [4:0]  reg_addr,
    input  wire        write_enable,
    input  wire [4:0]  du_reg_addr,
    output wire [31:0] du_reg_data,
    output wire [31:0] data_1,
    output wire [31:0] data_2
);

    reg [31:0] registers [0:31];

    // Lectura combinacional
    assign data_1 = (rs == 5'b00000) ? 32'b0 : registers[rs];
    assign data_2 = (rt == 5'b00000) ? 32'b0 : registers[rt];

    assign du_reg_data = (du_reg_addr == 5'b00000) ? 32'b0 : registers[du_reg_addr];

    integer i;

    // Escritura secuencial
    always @(negedge clk or posedge reset) begin
        if (reset) begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] <= 32'b0;
            end        
        end else if (write_enable && (reg_addr != 5'b00000)) begin
            registers[reg_addr] <= write_data;
        end
    end

endmodule

