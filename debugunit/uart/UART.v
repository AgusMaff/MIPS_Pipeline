module UART
#(//19200 bauds, databit,1stopbit 2^2 FIFO
    DBIT       = 8,     // data bits
    SB_TICK    = 16,    // ticks for stop bits
    DVSR       = 163,   // baud rate divisor (9600 baud @ 50MHz)
    DVSR_BITS  = 8,     // number of bits in divisor
    FIFO_W     = 5     // FIFO width (4 words)
) 
(
    input                    clk,  //! clock
    input                  reset,  //! reset
    input                rd_uart,  //! read uart
    input                wr_uart,  //! write uart
    input                     rx,  //! rx
    input  [DBIT-1:0]     w_data,  //! data to write
    
    output               tx_full,  //! tx full
    output              rx_empty,  //! rx empty
    output                    tx,  //! tx
    output [DBIT-1:0]     r_data  //! data to read
);
    
    //signal declaration
    wire            tick              ;
    wire            rx_done_tick      ;
    wire            tx_done_tick      ;
    wire            tx_empty          ;
    wire            tx_fifo_not_empty ;
    wire [DBIT-1:0] tx_fifo_out       ;
    wire [DBIT-1:0] rx_data_out       ;
    
    //body
    baud_rate_gen 
    #( 
        .NB(DVSR_BITS),  // number of bits in counter //aplicar log2(M)=NB
        .M (DVSR)   // mod-M 
    )
    u_baud_rate_gen
        ( 
        .clk     (clk  ),
        .reset   (reset), 
        .max_tick(tick ), 
        .q       (     )  
        );
    
    uart_rx
    #(
        .DBIT    (DBIT   ),  // # data bit 
        .SB_TICK (SB_TICK)   // # ticks for stop bits
    )
    u_uart_rx
        (
        .clk         (clk           ), 
        .reset       (reset         ),
        .rx          (rx            ), 
        .s_tick      (tick          ),
        .rx_done_tick(rx_done_tick  ),
        .dout        (rx_data_out   )
        );
    
    fifo
    #(
        .B(DBIT     ), //number bits in a word
        .W(FIFO_W   )  //number of address bits
    )
    u_fifo_rx
    (
        .clk   (clk         ),
        .reset (reset       ),
        .rd    (rd_uart     ),
        .wr    (rx_done_tick),
        .w_data(rx_data_out ),
        .empty (rx_empty    ),
        .full  (            ),
        .r_data(r_data      )
    );
    
    fifo
    #(
        .B(DBIT     ), //number bits in a word
        .W(FIFO_W   )  //number of address bits
    )
    u_fifo_tx
    (
        .clk   (clk         ),
        .reset (reset       ),
        .rd    (tx_done_tick),
        .wr    (wr_uart     ),
        .w_data(w_data      ),
        .empty (tx_empty    ),
        .full  (tx_full     ),
        .r_data(tx_fifo_out )
    );
    
    uart_tx 
    #(
        .DBIT    (DBIT     ),   //!Data bit
        .SB_TICK (SB_TICK  )    //! Sticks for stop bits
    )
    u_uart_tx
    (
        .clk         (clk               ),
        .reset       (reset             ),
        .tx_start    (tx_fifo_not_empty ),
        .s_tick      (tick              ),
        .din         (tx_fifo_out       ),
        .tx_done_tick(tx_done_tick      ),
        .tx          (tx                )
    );
    
    assign tx_fifo_not_empty = ~tx_empty;
    
endmodule