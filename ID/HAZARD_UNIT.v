`timescale 1ns / 1ps

module HAZARD_UNIT 
(
    input        branch,
    input [4:0]  if_id_rs,
    input [4:0]  if_id_rt,
    input [4:0]  id_ex_rt,
    input [4:0]  ex_rd,
    input [4:0]  m_rd,
    input        id_ex_mem_read,  //load operations   |memread_e writereg_m  regwrite_E  memread_m
    input        ex_regwrite,  //writereg_e
    input        m_memtoreg,
    input        branch_taken,
    output       flush,
    output       stall
);

reg reg_stall;
always @(*) begin
    reg_stall = 1'b0;
    //read load data hazard
    if((id_ex_mem_read) && ((if_id_rs == id_ex_rt) || (if_id_rt == id_ex_rt)))
    begin
        reg_stall = 1'b1;
    end
end

assign flush      = branch_taken;
assign stall      = reg_stall;
  
endmodule