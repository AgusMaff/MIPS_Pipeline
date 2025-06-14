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
  input  wire [31:0] a,           // Primer operando
  input  wire [31:0] b,           // Segundo operando
  input  wire [3:0]  alu_control, // Señal de control
  output reg  [31:0] result       // Resultado
);

  // Lógica de la ALU
  always @(*) begin
    case(alu_control)
      ALU_AND:      result = a & b;
      ALU_OR:       result = a | b;
      ALU_ADD:      result = $signed(a) + $signed(b);  
      ALU_ADDU:     result = a + b;                  
      ALU_SUB:      result = $signed(a) - $signed(b);  
      ALU_SUBU:     result = a - b;                   
      ALU_SLT:      result = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
      ALU_SLTU:     result = (a < b) ? 32'b1 : 32'b0; 
      ALU_NOR:      result = ~(a | b);
      ALU_XOR:      result = a ^ b;
      ALU_SLL:      result = b << a[4:0]; 
      ALU_SRL:      result = b >> a[4:0]; 
      ALU_SRA:      result = $signed(b) >>> a[4:0];         
      default: result = 0; // Por defecto suma (unsigned)
    endcase
    
  end

endmodule