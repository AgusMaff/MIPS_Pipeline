`timescale 1ns / 1ps

module ALU # (
  // ALU Control Signals
  parameter ALU_ADD  = 6'b100000,
  parameter ALU_ADDU = 6'b100001,
  parameter ALU_SUB  = 6'b100010,
  parameter ALU_SUBU = 6'b100011,
  parameter ALU_AND  = 6'b100100,
  parameter ALU_OR   = 6'b100101,
  parameter ALU_XOR  = 6'b100110,
  parameter ALU_NOR  = 6'b100111,
  parameter ALU_SLL  = 6'b000000,
  parameter ALU_SLLV = 6'b000100,
  parameter ALU_SRL  = 6'b000010,
  parameter ALU_SRLV = 6'b000110,
  parameter ALU_SRA  = 6'b000011,
  parameter ALU_SRAV = 6'b000111,
  parameter ALU_SLT  = 6'b101010,
  parameter ALU_SLTU = 6'b101011,
  parameter ALU_LUI  = 6'b001111
  ) (
  input  wire  [31:0]  data_a,      // Primer operando
  input  wire  [31:0]  data_b,      // Segundo operando
  input  wire  [5:0]   operation,   // Señal de control
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
      ALU_LUI:       alu_result = {data_b[15:0], 16'b0};
      ALU_SLLV:      alu_result = (data_b) << data_a;
      ALU_SRLV:      alu_result = (data_b) >> data_a;
      ALU_SRAV:      alu_result = $signed(data_b) >>> data_a;     
      default: alu_result = 0; // Por defecto suma (unsigned)
    endcase
    
  end

  assign result = alu_result; // Asignar el resultado al puerto de salida

endmodule



