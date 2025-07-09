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
    output reg        jump            // Señal de salto
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
                        end        
                    endcase
                end

                3'b100: begin //LOAD TYPE INSTRUCTIONS (LW, LH, LB, LBU, LHU, LWU)
                        branch     = 1'b0;
                        is_beq     = 1'b0;
                        reg_dest   = 1'b0; // LW escribe en rt
                        alu_src    = 1'b1; // Fuente ALU es inmediato
                        alu_op     = 4'b0110; 
                        mem_read   = 1'b1; // Leer de memoria
                        mem_write  = 1'b0;
                        mem_to_reg = 1'b1; // Escribir en registro desde memoria
                        reg_write  = 1'b1; // Habilitar escritura en registro
                end

                3'b101: begin //STORE TYPE INSTRUCTIONS (SW, SH, SB)
                        branch     = 1'b0;
                        is_beq     = 1'b0;
                        reg_dest   = 1'b0; // No se escribe en registro
                        alu_src    = 1'b1; // Fuente ALU es inmediato
                        alu_op     = 4'b0111;
                        mem_read   = 1'b0;
                        mem_write  = 1'b1; // Escribir en memoria
                        mem_to_reg = 1'b0; // No se escribe en registro desde memoria
                        reg_write  = 1'b0; // No se escribe en registro
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
                        end
                    endcase
                end
                
                default: begin // Default case (ADD)
                    branch     = 1'b0;
                    is_beq     = 1'b0;
                    reg_dest   = 1'b1;
                    alu_src    = 1'b0;
                    alu_op     = 3'b010; 
                    mem_read   = 1'b0;
                    mem_write  = 1'b0;
                    mem_to_reg = 1'b0;
                    reg_write  = 1'b1;
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
        end
    end
endmodule