`timescale 1ns / 1ps

module ALU # (
  // ALU Control Signals
  parameter ALU_ADD  = 4'b0010,
  parameter ALU_ADDU = 4'b0011,
  parameter ALU_SUB  = 4'b0110,
  parameter ALU_SUBU = 4'b0100,  // Added for SUB Unsigned
  parameter ALU_AND  = 4'b0000,
  parameter ALU_OR   = 4'b0001,
  parameter ALU_XOR  = 4'b1101,
  parameter ALU_NOR  = 4'b1100,
  parameter ALU_SLT  = 4'b0111,
  parameter ALU_SLTU = 4'b1001,
  parameter ALU_SLL  = 4'b1000,
  parameter ALU_SRL  = 4'b1010,  
  parameter ALU_SRA  = 4'b1011
) (
  input  wire  [31:0]  data_a,      // Primer operando
  input  wire  [31:0]  data_b,      // Segundo operando
  input  wire  [3:0]   operation,   // Señal de control
  output wire  [31:0]  result       // Resultado
);

  reg [31:0] alu_result; // Registro para almacenar el resultado

  // Lógica de la ALU
  always @(*) begin
    case(operation)
      ALU_AND:       alu_result = data_a & data_b;
      ALU_OR:        alu_result = data_a | data_b;
      ALU_ADD:       alu_result = $signed(data_a) + $signed(data_b);  
      ALU_ADDU:      alu_result = data_a + data_b;                  
      ALU_SUB:       alu_result = $signed(data_a) - $signed(data_b);  
      ALU_SUBU:      alu_result = data_a - data_b;                   
      ALU_SLT:       alu_result = ($signed(data_a) < $signed(data_b)) ? 32'b1 : 32'b0;
      ALU_SLTU:      alu_result = (data_a < data_b) ? 32'b1 : 32'b0; 
      ALU_NOR:       alu_result = ~(data_a | data_b);
      ALU_XOR:       alu_result = data_a ^ data_b;
      ALU_SLL:       alu_result = data_b << data_a[4:0]; 
      ALU_SRL:       alu_result = data_b >> data_a[4:0]; 
      ALU_SRA:       alu_result = $signed(data_b) >>> data_a[4:0];         
      default: alu_result = 0; // Por defecto suma (unsigned)
    endcase
    
  end

  assign result = alu_result; // Asignar el resultado al puerto de salida

endmodule