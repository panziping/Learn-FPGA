module uart_loop(
	i_clk,
	i_rst_n,
	i_rx,
	o_tx
);

	input i_clk;
	input i_rst_n;
	input i_rx;
	output o_tx;
	

	
	localparam P_EVEN = 2'b00;
	localparam P_ODD  = 2'b01;
	localparam P_NONE = 2'b10;
	
	
	wire [7:0] w_uart_data;
	wire w_uart_data_valid_go;

uart_rxd uart_rxd(
	.clk(i_clk),
	.rst_n(i_rst_n),
	.rxd(i_rx),
	.parity(P_NONE),
	.rxd_data(w_uart_data),
	.rxd_data_valid_go(w_uart_data_valid_go)
); 
	
uart_txd uart_txd(
	.clk(i_clk),
	.rst_n(i_rst_n),
	.txd_data(w_uart_data),
	.txd_en_go(w_uart_data_valid_go),
	.parity(P_NONE),
	.txd(o_tx),
	.txd_busy()
);
	
endmodule 


