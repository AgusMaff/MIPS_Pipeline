`timescale 1ns / 1ps

module MUX_TEST ();
    // Entradas
    reg [31:0] a;
    reg [31:0] b;
    reg control_unit;
    
    // Salida
    wire [31:0] result;
    
    // Instancia del MUX
    MUX2TO1 dut (
        .i_input_1(a),
        .i_input_2(b),
        .i_control_unit(control_unit),
        .o_mux(result)
    );
    
    // Procedimiento de prueba
    initial begin
        $display("Tiempo | Control Unit | A        | B        | Resultado");
        $monitor("%4dns | %b           | %d | %d | %d", $time, control_unit, a, b, result);
    
        // Espera inicial
        #10;
    
        // Prueba con control unit en 0 (selecciona A)
        a = 10; b = 20; control_unit = 0; #10;
    
        // Prueba con control unit en 1 (selecciona B)
        a = 30; b = 40; control_unit = 1; #10;
    
        // Prueba con ambos inputs iguales
        a = 50; b = 50; control_unit = 0; #10;
    
        // Finaliza la simulación
        $finish;
    end
endmodule