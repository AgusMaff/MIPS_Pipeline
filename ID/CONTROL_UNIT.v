`timescale 1ns / 1ps

module CONTROL_UNIT (
    input  wire       enable,         // Habilitación de unidad de control
    input  wire [5:0] op_code,        // Código de operación de la instrucción
    output reg        branch,         // Señal de ramificación
    output reg        is_beq,         // Señal de BEQ
    output reg        reg_dest,       // Señal de destino de registro
    output reg        alu_src,        // Selección de fuente ALU
    output reg  [3:0] alu_op,         // Operación ALU
    output reg        mem_read,       // Señal de lectura de memoria
    output reg        mem_write,      // Señal de escritura en memoria
    output reg        mem_to_reg,     // Señal de escritura de memoria a registro
    output reg        reg_write,      // Señal de escritura en registro
    output reg        jump,           // Señal de salto
    output reg  [2:0] bhw_type,       // Tipo de instrucción de carga/almacenamiento (BHW)
    output reg        halt            // Señal de parada (HALT)
);

    always @(*) begin
        if (enable) begin
            case (op_code[5:3])
                3'b000: begin 
                    case (op_code[2:0])
                        3'b000: begin //ADD, SUB, AND, OR, XOR, NOR, SLL, SRL, SRA, SLT, SLTU, ...
                            branch     = 1'b0;
                            is_beq     = 1'b0; 
                            reg_dest   = 1'b1;
                            alu_src    = 1'b0;
                            alu_op     = 4'b0000; 
                            mem_read   = 1'b0;
                            mem_write  = 1'b0;
                            mem_to_reg = 1'b0;
                            reg_write  = 1'b1;
                            jump       = 1'b0; 
                            bhw_type   = 3'b000; // Tipo de instrucción R
                            halt       = 1'b0; // No es HALT
                        end
                        3'b100: begin //BEQ
                            branch     = 1'b1;
                            is_beq     = 1'b1; 
                            reg_dest   = 1'b0;
                            alu_src    = 1'b0;
                            alu_op     = 4'b0001; 
                            mem_read   = 1'b0;
                            mem_write  = 1'b0;
                            mem_to_reg = 1'b0;
                            reg_write  = 1'b0;
                            jump       = 1'b0; 
                            bhw_type   = 3'b000; // Tipo de instrucción R
                            halt       = 1'b0; // No es HALT
                        end
                        3'b101: begin //BNE
                            branch     = 1'b1;
                            is_beq     = 1'b0; 
                            reg_dest   = 1'b0;
                            alu_src    = 1'b0;
                            alu_op     = 4'b0011; // La operación es la misma que BEQ, pero con una señal diferente
                            mem_read   = 1'b0;
                            mem_write  = 1'b0;
                            mem_to_reg = 1'b0;
                            reg_write  = 1'b0;
                            jump       = 1'b0; 
                            bhw_type   = 3'b000; // Tipo de instrucción R
                            halt       = 1'b0; // No es HALT
                        end
                        3'b010: begin //JMP
                            branch     = 1'b0;
                            is_beq     = 1'b0;
                            reg_dest   = 1'b0;
                            alu_src    = 1'b0;
                            alu_op     = 4'b0100; 
                            mem_read   = 1'b0;
                            mem_write  = 1'b0;
                            mem_to_reg = 1'b0;
                            reg_write  = 1'b0;
                            jump       = 1'b1; // Señal de salto
                            bhw_type   = 3'b000; // Tipo de instrucción R
                            halt       = 1'b0; // No es HALT
                        end
                        3'b011: begin //JAL
                            branch     = 1'b0;
                            is_beq     = 1'b0;
                            reg_dest   = 1'b1; // JAL escribe en $rd
                            alu_src    = 1'b0;
                            alu_op     = 4'b0101; 
                            mem_read   = 1'b0;
                            mem_write  = 1'b0;
                            mem_to_reg = 1'b0;
                            reg_write  = 1'b1; // JAL escribe en $rd
                            jump       = 1'b1; // Señal de salto
                            bhw_type   = 3'b000; // Tipo de instrucción R
                            halt       = 1'b0; // No es HALT
                        end        
                    endcase
                end

                3'b100: begin //LOAD TYPE INSTRUCTIONS (LW, LH, LB, LBU, LHU, LWU)
                    case(op_code[2:0])
                        3'b011: begin //LW
                            branch     = 1'b0;
                            is_beq     = 1'b0;
                            reg_dest   = 1'b0; // LW escribe en rt
                            alu_src    = 1'b1; // Fuente ALU es inmediato
                            alu_op     = 4'b0110; 
                            mem_read   = 1'b1; // Leer de memoria
                            mem_write  = 1'b0;
                            mem_to_reg = 1'b1; // Escribir en registro desde memoria
                            reg_write  = 1'b1; // Habilitar escritura en registro
                            jump       = 1'b0;
                            bhw_type   = 3'b001; // Tipo de instrucción de carga (Palabra completa)
                            halt       = 1'b0; // No es HALT
                        end
                        3'b001: begin //LH
                            branch     = 1'b0;
                            is_beq     = 1'b0;
                            reg_dest   = 1'b0; // LH escribe en rt
                            alu_src    = 1'b1; // Fuente ALU es inmediato
                            alu_op     = 4'b0110; 
                            mem_read   = 1'b1; // Leer de memoria
                            mem_write  = 1'b0;
                            mem_to_reg = 1'b1; // Escribir en registro desde memoria
                            reg_write  = 1'b1; // Habilitar escritura en registro
                            jump       = 1'b0;
                            bhw_type   = 3'b010; // Tipo de instrucción de carga (Media palabra)
                            halt       = 1'b0; // No es HALT
                        end
                        3'b000: begin //LB
                            branch     = 1'b0;
                            is_beq     = 1'b0;
                            reg_dest   = 1'b0; // LB escribe en rt
                            alu_src    = 1'b1; // Fuente ALU es inmediato
                            alu_op     = 4'b0110; 
                            mem_read   = 1'b1; // Leer de memoria
                            mem_write  = 1'b0;
                            mem_to_reg = 1'b1; // Escribir en registro desde memoria
                            reg_write  = 1'b1; // Habilitar escritura en registro
                            jump       = 1'b0;
                            bhw_type   = 3'b100; // Tipo de instrucción de carga (Byte)
                            halt       = 1'b0; // No es HALT
                        end
                        3'b111: begin //LWU
                            branch     = 1'b0;
                            is_beq     = 1'b0;
                            reg_dest   = 1'b0; // LWU escribe en rt
                            alu_src    = 1'b1; // Fuente ALU es inmediato
                            alu_op     = 4'b0110; 
                            mem_read   = 1'b1; // Leer de memoria
                            mem_write  = 1'b0;
                            mem_to_reg = 1'b1; // Escribir en registro desde memoria
                            reg_write  = 1'b1; // Habilitar escritura en registro
                            jump       = 1'b0;
                            bhw_type   = 3'b101; // Tipo de instrucción de carga (Palabra completa)
                            halt       = 1'b0; // No es HALT
                        end
                        3'b100: begin //LBU
                            branch     = 1'b0;
                            is_beq     = 1'b0;
                            reg_dest   = 1'b0; // LBU escribe en rt
                            alu_src    = 1'b1; // Fuente ALU es inmediato
                            alu_op     = 4'b0110; 
                            mem_read   = 1'b1; // Leer de memoria
                            mem_write  = 1'b0;
                            mem_to_reg = 1'b1; // Escribir en registro desde memoria
                            reg_write  = 1'b1; // Habilitar escritura en registro
                            jump       = 1'b0;
                            bhw_type   = 3'b110; // Tipo de instrucción de carga (Byte)
                            halt       = 1'b0; // No es HALT
                        end
                        3'b101: begin //LHU
                            branch     = 1'b0;
                            is_beq     = 1'b0;
                            reg_dest   = 1'b0; // LHU escribe en rt
                            alu_src    = 1'b1; // Fuente ALU es inmediato
                            alu_op     = 4'b0110; 
                            mem_read   = 1'b1; // Leer de memoria
                            mem_write  = 1'b0;
                            mem_to_reg = 1'b1; // Escribir en registro desde memoria
                            reg_write  = 1'b1; // Habilitar escritura en registro
                            jump       = 1'b0;
                            bhw_type   = 3'b111; // Tipo de instrucción de carga (Media palabra)
                            halt       = 1'b0; // No es HALT
                        end
                    endcase
                end

                3'b101: begin //STORE TYPE INSTRUCTIONS (SW, SH, SB)
                    case(op_code[2:0])
                        3'b011: begin //SW
                            branch     = 1'b0;
                            is_beq     = 1'b0;
                            reg_dest   = 1'b0; // SW no escribe en registro
                            alu_src    = 1'b1; // Fuente ALU es inmediato
                            alu_op     = 4'b0110; 
                            mem_read   = 1'b0;
                            mem_write  = 1'b1; // Escribir en memoria
                            mem_to_reg = 1'b0; // No se escribe en registro
                            reg_write  = 1'b0; // No se habilita escritura en registro
                            jump       = 1'b0;
                            bhw_type   = 3'b001; // Tipo de instrucción de almacenamiento (Palabra completa)
                            halt       = 1'b0; // No es HALT
                        end
                        3'b001: begin //SH
                            branch     = 1'b0;
                            is_beq     = 1'b0;
                            reg_dest   = 1'b0; // SH no escribe en registro
                            alu_src    = 1'b1; // Fuente ALU es inmediato
                            alu_op     = 4'b0110; 
                            mem_read   = 1'b0;
                            mem_write  = 1'b1; // Escribir en memoria
                            mem_to_reg = 1'b0; // No se escribe en registro
                            reg_write  = 1'b0; // No se habilita escritura en registro
                            jump       = 1'b0;
                            bhw_type   = 3'b010; // Tipo de instrucción de almacenamiento (Media palabra)
                            halt       = 1'b0; // No es HALT
                        end
                        3'b000: begin //SB
                            branch     = 1'b0;
                            is_beq     = 1'b0;
                            reg_dest   = 1'b0; // SB no escribe en registro
                            alu_src    = 1'b1; // Fuente ALU es inmediato
                            alu_op     = 4'b0110; 
                            mem_read   = 1'b0;
                            mem_write  = 1'b1; // Escribir en memoria
                            mem_to_reg = 1'b0; // No se escribe en registro
                            reg_write  = 1'b0; // No se habilita escritura en registro
                            jump       = 1'b0;
                            bhw_type   = 3'b100; // Tipo de instrucción de almacenamiento (Byte)
                            halt       = 1'b0; // No es HALT
                        end
                    endcase
                end

                3'b001: begin // I TYPE INSTRUCTIONS (ADDI, ADDIU, ANDI, ORI, XORI, SLTI, SLTIU)
                    case (op_code[2:0]) 
                        3'b000: begin //ADDI
                            branch     = 1'b0;
                            is_beq     = 1'b0;
                            reg_dest   = 1'b0; // Escribir en rt
                            alu_src    = 1'b1; // Fuente ALU es inmediato
                            alu_op     = 4'b1000; 
                            mem_read   = 1'b0;
                            mem_write  = 1'b0;
                            mem_to_reg = 1'b0;
                            reg_write  = 1'b1; // Habilitar escritura en registro
                            jump       = 1'b0;
                            bhw_type   = 3'b000; // Tipo de instrucción I
                            halt       = 1'b0; // No es HALT
                        end
                        3'b001: begin //ADDIU
                            branch     = 1'b0;
                            is_beq     = 1'b0;
                            reg_dest   = 1'b0; // Escribir en rt
                            alu_src    = 1'b1; // Fuente ALU es inmediato
                            alu_op     = 4'b1001; 
                            mem_read   = 1'b0;
                            mem_write  = 1'b0;
                            mem_to_reg = 1'b0;
                            reg_write  = 1'b1; // Habilitar escritura en registro
                            jump       = 1'b0;
                            bhw_type   = 3'b000; // Tipo de instrucción I
                            halt       = 1'b0; // No es HALT
                        end
                        3'b100: begin //ANDI
                            branch     = 1'b0;
                            is_beq     = 1'b0;
                            reg_dest   = 1'b0; // Escribir en rt
                            alu_src    = 1'b1; // Fuente ALU es inmediato
                            alu_op     = 4'b1010; 
                            mem_read   = 1'b0;
                            mem_write  = 1'b0;
                            mem_to_reg = 1'b0;
                            reg_write  = 1'b1; // Habilitar escritura en registro
                            jump       = 1'b0;
                            bhw_type   = 3'b000; // Tipo de instrucción I
                            halt       = 1'b0; // No es HALT
                        end
                        3'b101: begin //ORI
                            branch     = 1'b0;
                            is_beq     = 1'b0;
                            reg_dest   = 1'b0; // Escribir en rt
                            alu_src    = 1'b1; // Fuente ALU es inmediato
                            alu_op     = 4'b1011; 
                            mem_read   = 1'b0;
                            mem_write  = 1'b0;
                            mem_to_reg = 1'b0;
                            reg_write  = 1'b1; // Habilitar escritura en registro
                            jump       = 1'b0;
                            bhw_type   = 3'b000; // Tipo de instrucción I
                            halt       = 1'b0; // No es HALT
                        end
                        3'b110: begin //XORI
                            branch     = 1'b0;
                            is_beq     = 1'b0;
                            reg_dest   = 1'b0; // Escribir en rt
                            alu_src    = 1'b1; // Fuente ALU es inmediato
                            alu_op     = 4'b1100; 
                            mem_read   = 1'b0;
                            mem_write  = 1'b0;
                            mem_to_reg = 1'b0;
                            reg_write  = 1'b1; // Habilitar escritura en registro
                            jump       = 1'b0;
                            bhw_type   = 3'b000; // Tipo de instrucción I
                            halt       = 1'b0; // No es HALT
                        end
                        3'b111: begin //LUI
                            branch     = 1'b0;
                            is_beq     = 1'b0;
                            reg_dest   = 1'b0; // Escribir en rt
                            alu_src    = 1'b1; // Fuente ALU es inmediato
                            alu_op     = 4'b1101; 
                            mem_read   = 1'b0;
                            mem_write  = 1'b0;
                            mem_to_reg = 1'b0;
                            reg_write  = 1'b1; // Habilitar escritura en registro
                            jump       = 1'b0;
                            bhw_type   = 3'b000; // Tipo de instrucción I
                            halt       = 1'b0; // No es HALT
                        end
                        3'b010: begin //SLTI
                            branch     = 1'b0;
                            is_beq     = 1'b0;
                            reg_dest   = 1'b0; // Escribir en rt
                            alu_src    = 1'b1; // Fuente ALU es inmediato
                            alu_op     = 4'b1110; 
                            mem_read   = 1'b0;
                            mem_write  = 1'b0;
                            mem_to_reg = 1'b0;
                            reg_write  = 1'b1; // Habilitar escritura en registro
                            jump       = 1'b0;
                            bhw_type   = 3'b000; // Tipo de instrucción I
                            halt       = 1'b0; // No es HALT
                        end
                        3'b011: begin //SLTIU
                            branch     = 1'b0;
                            is_beq     = 1'b0;
                            reg_dest   = 1'b0; // Escribir en rt
                            alu_src    = 1'b1; // Fuente ALU es inmediato
                            alu_op     = 4'b1111; 
                            mem_read   = 1'b0;
                            mem_write  = 1'b0;
                            mem_to_reg = 1'b0;
                            reg_write  = 1'b1; // Habilitar escritura en registro
                            jump       = 1'b0;
                            bhw_type   = 3'b000; // Tipo de instrucción I
                            halt       = 1'b0; // No es HALT
                        end
                    endcase
                end

                3'b111: begin 
                    case (op_code[2:0])
                        3'b111: begin //HALT
                            branch     = 1'b0;
                            is_beq     = 1'b0;
                            reg_dest   = 1'b0;
                            alu_src    = 1'b0;
                            alu_op     = 4'b0000; 
                            mem_read   = 1'b0;
                            mem_write  = 1'b0;
                            mem_to_reg = 1'b0;
                            reg_write  = 1'b0;
                            jump       = 1'b0;
                            bhw_type   = 3'b000; // Tipo de instrucción R
                            halt       = 1'b1; // Señal de parada (HALT)
                        end
                    endcase
                end

                
                default: begin // Default case (ADD)
                    branch     = 1'b0;
                    is_beq     = 1'b0;
                    reg_dest   = 1'b0;
                    alu_src    = 1'b0;
                    alu_op     = 3'b000; 
                    mem_read   = 1'b0;
                    mem_write  = 1'b0;
                    mem_to_reg = 1'b0;
                    reg_write  = 1'b0;
                    jump       = 1'b0;
                    bhw_type   = 3'b000; // Tipo de instrucción R
                    halt       = 1'b0; // No es HALT
                end
            endcase
        end else begin // Si la unidad de control no está habilitada
            branch     = 1'b0;
            is_beq     = 1'b0;
            reg_dest   = 1'b0;
            alu_src    = 1'b0;
            alu_op     = 3'b000;
            mem_read   = 1'b0;
            mem_write  = 1'b0;
            mem_to_reg = 1'b0;
            reg_write  = 1'b0;
            jump       = 1'b0;
            bhw_type   = 3'b000; // Tipo de instrucción R
            halt       = 1'b0; // No es HALT
        end
    end
endmodule