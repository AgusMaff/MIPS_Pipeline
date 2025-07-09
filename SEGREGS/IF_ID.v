`timescale 1ns / 1ps

module IF_ID (
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] if_pc_plus_4,
    input  wire [31:0] if_instruction,
    input  wire        flush_idex,
    input  wire        stall,

    output reg  [31:0] id_pc_plus_4,
    output reg  [4:0]  id_rs,
    output reg  [4:0]  id_rt,
    output reg  [4:0]  id_rd,
    output reg  [15:0] id_beq_offset,
    output reg  [5:0]  id_opcode,
    output reg  [5:0]  id_function_code
);

    always @(posedge clk or posedge reset) begin
        if (reset || flush_idex) begin
            id_pc_plus_4 <= 32'b0;
            id_rs <= 5'b0;
            id_rt <= 5'b0;
            id_rd <= 5'b0;
            id_beq_offset <= 16'b0;
            id_opcode <= 5'b0;
            id_function_code <= 5'b0;
        end else if (!stall) begin
            id_pc_plus_4 <= if_pc_plus_4;
            id_rs <= if_instruction[25:21];
            id_rt <= if_instruction[20:16];
            id_rd <= if_instruction[15:11];
            id_beq_offset <= if_instruction[15:0];
            id_opcode <= if_instruction[31:26];
            id_function_code <= if_instruction[5:0];
        end
    end
endmodule