`timescale 1ns / 1ps

module IF(
    input wire i_clk,                // Reloj
    input wire i_reset,              // Reset
    output wire [31:0] o_instruction  // Instrucción leída
);
    wire [31:0] next_pc;             // Siguiente PC
    wire [31:0] pc;                  // PC actual

    // Instancia del PC
    PC pc_inst (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_next_pc(next_pc),
        .o_pc(pc)
    );

    // Instancia de la memoria de instrucciones
    INSMEM insmem_inst (
        .addr(pc), 
        .instruction(o_instruction)
    );
    
    // Instancia de ALU para sumar 4 al PC
    ALU addr4 (
        .a(pc), 
        .b(32'd4),
        .alu_control(4'b0011),
        .result(next_pc)
    );

    // MUX para seleccionar el proximo valor de PC
    //MUX2TO1 mux_instr (
    //    .i_input_1(o_instruction), 
    //    .i_input_2(32'b0), // Valor por defecto en caso de reset
    //    .i_control_unit(i_reset), 
    //    .o_mux(o_instruction)
    //);
endmodule