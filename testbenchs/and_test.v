`timescale 1ns / 1ps
/////////////////////////////

module AND_TEST();
  // Entradas
  reg a;
  reg b;

  // Salida
  wire result;

  //Instancia de AND
  AND dut (
    .i_zero_alu(a),
    .i_control_unit(b),
    .o_mux(result)
  );

  // Procedimiento de prueba
  initial begin
    $display("Tiempo | A | B | Resultado");
    $monitor("%4dns | %b | %b | %b", $time, a, b, result);

    // Espera inicial
    #10;

    // Prueba AND con ambos bits en 0
    a = 0; b = 0; #10;

    // Prueba AND con A en 1 y B en 0
    a = 1; b = 0; #10;

    // Prueba AND con A en 0 y B en 1
    a = 0; b = 1; #10;

    // Prueba AND con ambos bits en 1
    a = 1; b = 1; #10;

    // Finaliza la simulación
    $finish;
  end
endmodule