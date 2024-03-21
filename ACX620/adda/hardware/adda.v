module adda(
	i_clk,
	i_rst_n,
	
	o_cs_n,
	o_sclk,
	o_din

);

	input i_clk;
	input i_rst_n;
	
	
	output o_cs_n;
	output o_sclk;
	output o_din;


	wire [15:0] test_dac_data;
	assign test_dac_data = {4'b0000,12'd4095};

tlv5618_driver tlv5618_driver(
	.clk(i_clk),
	.rst_n(i_rst_n),
	.dac_data(test_dac_data),
	.dac_load_en_go(1'b1),
	.cs_n(o_cs_n),
	.sclk(o_sclk),
	.din(o_din),
	.dac_convert_busy()
);


endmodule
