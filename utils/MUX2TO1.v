`timescale 1ns / 1ps

module MUX2TO1 (
    input wire [31:0] i_input_1,
    input wire [31:0] i_input_2,
    input wire i_control_unit,
    output wire [31:0] o_mux
);

  assign o_mux = (i_control_unit) ? i_input_2 : i_input_1;
endmodule