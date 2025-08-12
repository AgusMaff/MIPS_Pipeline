`timescale 1ns / 1ps

module IF(
    input  wire        i_clk,          // Reloj
    input  wire        i_clk_en,       // Habilitar señal de reloj
    input  wire        i_reset,        // Reset
    input  wire        i_stall,        // Señal de stall para agregar latencia
    input  wire        i_pcsrc,        // Señal de selección de PC
    input  wire        i_jump,         // Señal de salto
    input  wire        i_write_en,     // Señal de escritura en memoria de instrucciones (no se usa en IF)
    input  wire        i_read_en,      // Señal de lectura en memoria de instrucciones (se usa en IF)
    input  wire [31:0] i_data,         // Datos a escribir en memoria de instrucciones (no se usa en IF)
    input  wire [31:0] i_addr_wr,      // Dirección de escritura en memoria de instrucciones (no se usa en IF)
    input  wire [31:0] i_beq_dir,      // Dirección de salto para BEQ
    input  wire [31:0] i_prev_instruction, // Instrucción previa para la unidad de depuración
    input  wire [31:0] i_jr_jump_addr, // Dirección de salto para JR
    input  wire        i_jumpSel,      // Bit de control para JR

    output wire [31:0] o_pc_plus_4,    // PC + 4
    output wire [31:0] o_instruction   // Instrucción leída
);
    wire [31:0] next_pc;            // Siguiente PC
    wire [31:0] jump_or_next_pc;    // PC de salto o siguiente PC
    wire [31:0] next_pc_final;      // PC final
    wire [31:0] pc_to_instmem;      // PC actual
    wire [31:0] jmp_dir;            // Dirección de salto para JMP

    MUX2TO1 mux_beq_or_pcplus4 (
        .input_1(o_pc_plus_4),
        .input_2(i_beq_dir),
        .selection_bit(i_pcsrc),
        .mux(next_pc)
    );

    MUX2TO1 mux_jmp_or_next (
        .input_1(next_pc),
        .input_2(jmp_dir),
        .selection_bit(i_jump),
        .mux(jump_or_next_pc)
    );

    MUX2TO1 mux_next_pc_or_jr(
        .input_1(jump_or_next_pc),
        .input_2(i_jr_jump_addr), // Instrucción previa para JR
        .selection_bit(i_jumpSel), // Bit de control para JR
        .mux(next_pc_final)
    );

    PC pc (
        .clk(i_clk),
        .clk_en(i_clk_en), // Habilitar señal de reloj
        .reset(i_reset),
        .next_pc(next_pc_final), // Solo se usan los 8 bits menos significativos
        .write_en(i_write_en),      // No se escribe en la memoria de instrucciones
        .stall(i_stall),
        .pc(pc_to_instmem)
    );

    INSMEM instmem (
        .clk(i_clk),
        .reset(i_reset),
        .write_en(i_write_en),      // No se escribe en la memoria de instrucciones
        .data(i_data),              // No se usa en lectura
        .addr(pc_to_instmem[7:0]),       // Dirección de la memoria de instrucciones
        .addr_wr(i_addr_wr[7:0]),        // Dirección de escritura (no se usa en lectura)
        .instruction(o_instruction) // Instrucción leída
    );

    ALU addr4 (
        .data_a(pc_to_instmem),     // PC actual
        .data_b(32'd4),             // Valor a sumar (4 en 32 bits)
        .operation(6'b100001),        // Operación de suma
        .result(o_pc_plus_4)       // Resultado de la suma (PC + 4)
    );

    SHFT2L shft2l (
        .pc_plus_4(o_pc_plus_4[31:28]),
        .shift(i_prev_instruction[25:0]),   // PC actual
        .jump_dir(jmp_dir)        // PC desplazado a la izquierda 2 bits
    );


endmodule