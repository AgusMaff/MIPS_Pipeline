`timescale 1ns / 1ps

module hazard_unit 
(
    input        branch,
    input [4:0]  rs_id ,
    input [4:0]  rt_id ,
    input [4:0]  rt_ex ,
    input [4:0]  rd_ex ,
    input [4:0]  rd_mem,
    input        mem_read_ex,  //load operations   |memread_e writereg_m  regwrite_E  memread_m
    input        regwrite_ex,  //writereg_e
    input        memtor
    output       flush_idex,
    output       stall
);


reg reg_flush;
reg reg_stall;
always @(*) begin
    //read load data hazard
    if((mem_read_ex) && ((rs_id == rt_ex) || (rt_id == rt_ex)))
    begin
        reg_flush = 1'b1;
        reg_stall = 1'b1;
    end

    else if(branch && ((regwrite_ex && (rd_ex != 5'b00000) && ((rd_ex == rs_id) || (rd_ex == rt_id))) || (memtoreg_m && (rd_mem != 5'b00000) && ((rd_mem == rs_id) || (rd_mem == rt_id)))))
        begin
            reg_flush = 1'b1;
            reg_stall = 1'b1;
        end
    else begin
        reg_flush = 1'b0;
        reg_stall = 1'b0;
    end
    
end

assign o_flush_idex = reg_flush;
assign o_stall      = reg_stall;

    
endmodule