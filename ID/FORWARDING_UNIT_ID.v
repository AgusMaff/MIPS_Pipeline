`timescale 1ns / 1ps

module FORWARDING_UNIT_ID(
    input  wire [4:0] if_id_rs,          // Source register 1 from ID stage
    input  wire [4:0] if_id_rt,          // Source register 2 from ID stage
    input  wire [4:0] ex_m_rd,           // Destination register from EX stage
    input  wire [4:0] m_rd,              // Destination register from MEM stage
    input  wire       ex_m_reg_write,    // Register write signal from EX stage
    input  wire       m_reg_write,       // Register write signal from MEM stage
    input  wire       m_mem_read,
    output wire [1:0] forward_a,         // Forwarding signal for source A
    output wire [1:0] forward_b          // Forwarding signal for source B
);
    reg [1:0] a;
    reg [1:0] b;

    always @(*) begin
        // Forward A (RS) con prioridad correcta
        if ((if_id_rs == ex_m_rd) && ex_m_reg_write && (ex_m_rd != 5'b00000)) begin 
            a = 2'b01;  // Forward desde EX/MEM (más reciente)
        end
        else if ((if_id_rs == m_rd) && m_mem_read && (m_rd != 5'b00000)) begin 
            a = 2'b11;  // Forward desde MEM/WB (menos reciente)
        end
        else if ((if_id_rs == m_rd) && m_reg_write && (m_rd != 5'b00000))begin
            a = 2'b10;  // No forward (usar dato de registro)
        end 
        else begin
            a = 2'b00;  // No forward (usar dato de registro)
        end

        // Forward B (RT) con prioridad correcta
        if ((if_id_rt == ex_m_rd) && ex_m_reg_write && (ex_m_rd != 5'b00000)) begin
            b = 2'b01;  // Forward desde EX/MEM (más reciente)
        end
        else if ((if_id_rt == m_rd) && m_mem_read && (m_rd != 5'b00000)) begin
            b = 2'b11;  // Forward desde MEM/WB (menos reciente)
        end
        else if ((if_id_rt == m_rd) && m_reg_write && (m_rd != 5'b00000))begin
            b = 2'b10;  // No forward (usar dato de registro)
        end
        else begin
            b = 2'b00;  // No forward (usar dato de registro)
        end
    end

    assign forward_a = a;
    assign forward_b = b;
endmodule