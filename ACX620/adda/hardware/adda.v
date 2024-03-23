`timescale 1ns/1ns



module adda(
	i_clk,
	i_rst_n,
	
	i_key,
	o_adc_cs_n,
	o_adc_sclk,
	o_adc_din,
	i_adc_dout

);
	
	//----------------------------  function  ----------------------------- //
	// press the key,adc collect 100 times,adc busy , key invalid. 			//
	// uart send adc data with a baud rate of 115200								//
	// dac output sin and square wave(rom)  											//
 	//----------------------------------------------------------------------//
	
	input i_clk;
	input i_rst_n;
	
	input i_key;

	output o_adc_cs_n;
	output o_adc_sclk;
	output o_adc_din;
	input i_adc_dout;
	
	

	wire w_key_press_valid_go;
key_filter key_filter(
	.clk(i_clk),
	.rst_n(i_rst_n),
	.key(i_key),
	.key_press_valid_go(w_key_press_valid_go)	//1:key press;0: key release.
);	
	
	
	localparam ADC_ADDR = 3'b101;

	wire [11:0] w_adc_data;
	wire w_adc_data_valid_go;
	
adc_ctrl adc_ctrl(
	.clk(i_clk),
	.rst_n(i_rst_n),
	.adc_addr(ADC_ADDR),
	.key_press_valid_go(w_key_press_valid_go),
	.adc_cs_n(o_adc_cs_n),
	.adc_sclk(o_adc_sclk),
	.adc_dout(i_adc_dout ),
	.adc_din(o_adc_din),
	
	.adc_data(w_adc_data),
	.adc_data_valid_go(w_adc_data_valid_go)
);





	

	
	
	
	
	
	
	
	
	
	
	
	
//
//	wire [15:0] test_dac_data;
//	assign test_dac_data = {4'b0000,12'd2047};
//
//tlv5618_driver tlv5618_driver(
//	.clk(i_clk),
//	.rst_n(i_rst_n),
//	.dac_data(test_dac_data),
//	.dac_convert_en_go(1'b1),
//	.dac_cs_n(o_cs_n),
//	.dac_sclk(o_sclk),
//	.dac_din(o_din),
//	.dac_convert_busy()
//);

endmodule
