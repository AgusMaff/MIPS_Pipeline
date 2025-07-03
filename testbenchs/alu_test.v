`timescale 1ns / 1ps
/////////////////////////////

module ALU_TEST ();
  // Entradas
  reg [31:0] a;
  reg [31:0] b;
  reg [3:0] alu_control;

  // Salida
  wire [31:0] result;

  // Instancia de la ALU
  ALU dut (
    .data_a(a),
    .data_b(b),
    .operation(alu_control),
    .result(result)
  );

  // Procedimiento de prueba
  initial begin
    $display("Tiempo | ALU_CONTROL | A        | B        | Resultado");
    $monitor("%4dns |    %b    | %d | %d | %d", $time, alu_control, a, b, result);

    // Espera inicial
    #10;

    // Prueba ADD
    a = 10; b = 5; alu_control = 4'b0010; #10;
    
    // Prueba ADDU
    a = 32'hFFFFFFFF; b = 1; alu_control = 4'b0011; #10;

    // Prueba SUB
    a = 10; b = 15; alu_control = 4'b0110; #10;

    // Prueba SUBU
    a = 10; b = 15; alu_control = 4'b0100; #10;

    // Prueba AND
    a = 32'hF0F0F0F0; b = 32'h0F0F0F0F; alu_control = 4'b0000; #10;

    // Prueba OR
    a = 32'hF0F0F0F0; b = 32'h0F0F0F0F; alu_control = 4'b0001; #10;

    // Prueba XOR
    a = 32'hFF00FF00; b = 32'h00FF00FF; alu_control = 4'b1101; #10;

    // Prueba NOR
    a = 32'h00000000; b = 32'hFFFFFFFF; alu_control = 4'b1100; #10;

    // Prueba SLT (signed)
    a = -5; b = 3; alu_control = 4'b0111; #10;

    // Prueba SLTU (unsigned)
    a = 32'hFFFFFFFE; b = 2; alu_control = 4'b1001; #10;

    // Prueba SLL
    a = 3; b = 32'h00000001; alu_control = 4'b1000; #10;

    // Prueba SRL
    a = 3; b = 32'h80000000; alu_control = 4'b1010; #10;

    // Prueba SRA
    a = 3; b = -32'h00000010; alu_control = 4'b1011; #10;

    $finish;
  end


endmodule