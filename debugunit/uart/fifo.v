module fifo
#(
    parameter B = 8, //number bits in a word
    parameter W = 5  //number of address bits
)(
    input             clk,
    input           reset,
    input              rd,
    input              wr,
    input  [B-1:0] w_data,
    output          empty,
    output           full,
    output [B-1:0] r_data

);
//! signal declaration
reg [B-1:0] array_reg [2**W-1:0] ; // register array
reg [W-1:0]             w_ptr_reg;
reg [W-1:0]            w_ptr_next; 
reg [W-1:0]            w_ptr_succ;
reg [W-1:0]             r_ptr_reg;
reg [W-1:0]            r_ptr_next;
reg [W-1:0]            r_ptr_succ;
reg                      full_reg;
reg                     empty_reg;
reg                     full_next;
reg                    empty_next;
wire                        wr_en;

//body register file write operation
always @(posedge clk) begin
    if(wr_en)
        array_reg[w_ptr_reg] <= w_data;
end
// register file read operation 
assign r_data = array_reg [r_ptr_reg] ; 
// write enabled only when FIFO is not full 
assign wr_en = wr & ~full_reg; 

// fifo control logic 
// register for read and w'rite pointers 
always @ (posedge clk , posedge reset ) begin
    if (reset) begin
        w_ptr_reg <=    0;
        r_ptr_reg <=    0;
        full_reg  <= 1'b0; 
        empty_reg <= 1'b1; 
    end
    else begin
        w_ptr_reg <= w_ptr_next;
        r_ptr_reg <= r_ptr_next;
        full_reg  <=  full_next;
        empty_reg <= empty_next;
    end
end

// next-state logic for read and write pointers
always @ (*) begin
    // successive pointer values 
    w_ptr_succ = w_ptr_reg + 1;
    r_ptr_succ = r_ptr_reg + 1;
    //default: keep old values
    w_ptr_next = w_ptr_reg; 
    r_ptr_next = r_ptr_reg; 
    full_next  =  full_reg; 
    empty_next = empty_reg;
    case ({wr, rd})
        //2'b00 no operation
        2'b01: //read
            if (~empty_reg) begin
                r_ptr_next = r_ptr_succ;
                full_next  = 1'b0;
                if (r_ptr_succ==w_ptr_reg)
                    empty_next = 1'b1;
            end
        2'b10: //write
            if (~full_reg) begin
                w_ptr_next = w_ptr_succ;
                empty_next = 1'b0;
                if (w_ptr_succ==r_ptr_reg)
                    full_next = 1'b1;
            end
        2'b11: //read and write
            begin
            w_ptr_next = w_ptr_succ;
            r_ptr_next = r_ptr_succ;
            end
    endcase
end

//output
assign empty = empty_reg;
assign full  =  full_reg;

endmodule