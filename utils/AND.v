`timescale 1ns / 1ps

module AND (
    input wire i_zero_alu,
    input wire i_control_unit,
    output wire o_mux
);

  assign o_mux = i_zero_alu & i_control_unit;
endmodule