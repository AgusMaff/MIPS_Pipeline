`timescale 1ns / 1ps

module IF(
    input  wire        i_clk,          // Reloj
    input  wire        i_reset,        // Reset
    input  wire        i_stall,        // Señal de stall para agregar latencia
    input  wire        i_pcsrc,        // Señal de selección de PC
    input  wire        i_jump,         // Señal de salto
    input  wire [31:0] i_beq_dir,      // Dirección de salto para BEQ
    input  wire [31:0] i_jmp_dir,      // Dirección de salto para JMP
    output wire [31:0] o_pc_plus_4,    // PC + 4
    output wire [31:0] o_instruction   // Instrucción leída
);
    wire [31:0] next_pc;            // Siguiente PC
    wire [31:0] next_pc_final;      // PC final
    wire [31:0] pc_to_instmem;      // PC actual
    wire [31:0] jmp_dir;            // Dirección de salto para JMP

    MUX2TO1 mux_beq_or_pcplus4 (
        .i_input_1(o_pc_plus_4),
        .i_input_2(i_beq_dir),
        .i_selection_bit(i_pcsrc),
        .o_mux(next_pc)
    );

    MUX2TO1 mux_jmp_or_next (
        .i_input_1(next_pc),
        .i_input_2(jmp_dir),
        .i_selection_bit(i_jump),
        .o_mux(next_pc_final)
    );

    PC pc (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_next_pc(next_pc_final),
        .stall(i_stall),
        .o_pc(pc_to_instmem)
    );

    INSMEM instmem (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_write_en(1'b0),            // No se escribe en la memoria de instrucciones
        .i_read_en(1'b1),             // Siempre se lee (luego tengo que diseñar la debug unit que controla la lectura y escritura de la memoria de instrucciones)
        .i_data(32'b0),               // No se usa en lectura
        .i_addr(pc_to_instmem),       // Dirección de la memoria de instrucciones
        .o_instruction(o_instruction) // Instrucción leída
    );

    ALU addr4 (
        .i_data_a(pc_to_instmem),     // PC actual
        .i_data_b(4'b0010),             // Valor a sumar (4)
        .i_operation(3'b010),         // Operación de suma
        .o_result(o_pc_plus_4)        // Resultado de la suma (PC + 4)
    );

    SHFT2L shft2l (
        .i_data(o_pc_plus_4),       // PC actual
        .o_shifted(jmp_dir)     // PC desplazado a la izquierda 2 bits
    );


endmodule