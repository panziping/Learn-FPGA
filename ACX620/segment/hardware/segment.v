`timescale 1ns/1ns
module segment(
	i_clk,
	i_rst_n,
	o_seg_sclk,
	o_seg_rclk,
	o_seg_dio
);


	input i_clk;
	input i_rst_n;
	output o_seg_sclk;
	output o_seg_rclk;
	output o_seg_dio;
	


	
	wire  [31:0] disp_data;
	assign disp_data = 32'habcdef12;
	
	wire [15:0] seg_data;
	wire seg_data_valid_go;
	
seg_disp seg_disp(
	.clk(i_clk),
	.rst_n(i_rst_n),
	.disp_en(1'b1),
	.disp_data(disp_data),
	.disp_data_valid_go(1'b1),
	.seg_data(seg_data[14:0]),
	.seg_data_valid_go(seg_data_valid_go)
);
	
	



hc595_driver hc595_driver(
	.clk(i_clk),
	.rst_n(i_rst_n), 
	.seg_data({1'b1,seg_data[14:0]}),		//{1bit dp,7bit seg_code, 8bit seg_sel}
	.seg_data_valid_go(seg_data_valid_go),
	.seg_sclk(o_seg_sclk),
	.seg_rclk(o_seg_rclk),
	.seg_dio(o_seg_dio)
);




endmodule
