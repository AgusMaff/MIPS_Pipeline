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
    input        id_ex_regwrite,  //writereg_e
    input        ex_m_memtoreg,
    output       flush_idex,
    output       stall
);


reg reg_flush;
reg reg_stall;
always @(*) begin
    reg_flush = 1'b0;
    reg_stall = 1'b0;
    //read load data hazard
    if((id_ex_mem_read) && ((if_id_rs == id_ex_rt) || (if_id_rt == id_ex_rt)))
    begin
        reg_stall = 1'b1;
    end

    else if(branch && ((id_ex_regwrite && (ex_rd != 5'b00000) && ((ex_rd == if_id_rs) || (ex_rd == if_id_rt))) || (ex_m_memtoreg && (m_rd != 5'b00000) && ((m_rd == if_id_rs) || (m_rd == if_id_rt)))))
        begin
            reg_flush = 1'b1;
        end
    end

assign flush_idex = reg_flush;
assign stall      = reg_stall;
  
endmodule