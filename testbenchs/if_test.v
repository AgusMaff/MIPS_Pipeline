`timescale 1ns / 1ps

module IF_TEST();
    reg i_clk;
    reg i_reset;
    wire [31:0] o_instruction;

    IF dut (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .o_instruction(o_instruction)
    );

    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk;
    end

    initial begin
        $display("Tiempo | Reset | Instruction");
        $monitor("%4dns | %b | %h", $time, i_reset, o_instruction);

        i_reset = 1; #5;
        i_reset = 0; #100;

        $finish;
    end
endmodule
