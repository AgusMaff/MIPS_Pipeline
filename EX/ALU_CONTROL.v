`timescale 1ns / 1ps

module ALU_CONTROL(
    input  wire [3:0]  alu_op,         // Operación ALU de la unidad de control
    input  wire [5:0]  function_code,  // Código de función de la instrucción
    output reg  [5:0]  alu_control     // Señal de control para la ALU
);

    always @(*) begin
        case (alu_op)
            4'b0000: alu_control = function_code; // R-type instructions
            4'b0110: alu_control = 6'b100000; // Load operation (ADD)
            4'b0111: alu_control = 6'b100000; // Store operation (ADD)
            4'b1000: alu_control = 6'b100000; // ADDI (Add Immediate)
            4'b1001: alu_control = 6'b100001; // ADDIU (Add Immediate Unsigned)
            4'b0101: alu_control = 6'b100100; // ANDI
            4'b1011: alu_control = 6'b100101; // ORI
            4'b1100: alu_control = 6'b100110; // XORI
            4'b1110: alu_control = 6'b101010; // SLTI
            4'b1111: alu_control = 6'b101011; // SLTIU
            4'b1101: alu_control = 6'b001111; // LUI (Load Upper Immediate)
            4'b1100: alu_control =
            default: begin
                     alu_control = 6'b100000; // Default to ADD
            end
        endcase
    end
endmodule