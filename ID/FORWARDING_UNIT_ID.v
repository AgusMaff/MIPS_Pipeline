`timescale 1ns / 1ps

module FORWARDING_UNIT_ID(
    input  wire [4:0] if_id_rs,          // Source register 1 from ID stage
    input  wire [4:0] if_id_rt,          // Source register 2 from ID stage
    input  wire [4:0] ex_m_rd,        // Destination register from EX stage
    input  wire       ex_m_reg_write, // Register write signal from EX stage
    output wire       forward_a,      // Forwarding signal for source A
    output wire       forward_b       // Forwarding signal for source B
);
    reg a;
    reg b;

    always @(*) 
    begin
        //fordward for rs en ID from mem
        if ((if_id_rs == ex_m_rd) && ex_m_reg_write && (ex_m_rd != 5'b00000)) begin 
            a = 1'b1;
        end
        else begin
            a = 1'b0;
        end
        //fordward for rt en ID from mem
        if ((if_id_rt == ex_m_rd) && ex_m_reg_write && (ex_m_rd != 5'b00000)) begin
            b = 1'b1;
        end
        else begin
            b = 1'b0;
        end
    end

    assign forward_a = a;
    assign forward_b = b;
endmodule