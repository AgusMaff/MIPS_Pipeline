`timescale 1ns / 1ps

module FORWARDING_UNIT_ID(
    input  wire [4:0] rs_id,          // Source register 1 from ID stage
    input  wire [4:0] rt_id,          // Source register 2 from ID stage
    input  wire [4:0] rd_ex_m,        // Destination register from EX stage
    input  wire       reg_write_ex_m, // Register write signal from EX stage
    output wire       forward_a,      // Forwarding signal for source A
    output wire       forward_b       // Forwarding signal for source B
);
    reg a;
    reg b;

    always @(*) 
    begin
        //fordward for rs en ID from mem
        if ((rs_id == rd_ex_m)&& reg_write_ex_m && (rd_ex_m != 5'b00000)) begin 
            a = 1'b1;
        end
        else begin
            a = 1'b0;
        end
        //fordward for rt en ID from mem
        if ((rt_id == rd_ex_m) && reg_write_ex_m && (rd_ex_m != 5'b00000)) begin
            b = 1'b1;
        end
        else begin
            b = 1'b0;
        end
    end

    assign forward_a = a;
    assign forward_b = b;
endmodule