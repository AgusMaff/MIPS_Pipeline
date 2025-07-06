`timescale 1ns / 1ps

module CONTROL_UNIT(
    input  wire       enable,         // Habilitación de unidad de control
    input  wire [5:0] op_code,        // Código de operación de la instrucción
    output wire       branch,         // Señal de ramificación
    output wire       reg_dest,       // Señal de destino de registro
    output wire       alu_src,        // Selección de fuente ALU
    output wire [2:0] alu_op,         // Operación ALU
    output wire       mem_read,       // Señal de lectura de memoria
    output wire       mem_write,      // Señal de escritura en memoria
    output wire       mem_to_reg,     // Señal de escritura de memoria a registro
    output wire       reg_write       // Señal de escritura en registro
);

    always @(*) begin
        if (enable) begin
            case (op_code)
                6'b000000: begin // Instrucción R-type
                    branch     = 1'b0;
                    reg_dest   = 1'b1;
                    alu_src    = 1'b0;
                    alu_op     = 3'b010; 
                    mem_read   = 1'b0;
                    mem_write  = 1'b0;
                    mem_to_reg = 1'b0;
                    reg_write  = 1'b1;
                end
                //6'b100011: begin // Intrucciones de almacenamiento (lw)
                //    branch     = 1'b0;
                //    reg_dest   = 1'b0; 
                //    alu_src    = 1'b1; 
                //    alu_op     = 3'b000; 
                //    mem_read   = 1'b1;
                //    mem_write  = 1'b0;
                //    mem_to_reg = 1'b1; 
                //    reg_write  = 1'b1;
                //end
                //6'b101011: begin // Instrucciones de carga (sw)
                //    branch     = 1'b0;
                //    reg_dest   = 1'bx; 
                //    alu_src    = 1'b1; 
                //    alu_op     = 3'b000; 
                //    mem_read   = 1'b0;
                //    mem_write  = 1'b1; 
                //    mem_to_reg = 1'bx; 
                //    reg_write  = 1'b0; 
                //end
                default: begin // Default case (ADD)
                    branch     = 1'b0;
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