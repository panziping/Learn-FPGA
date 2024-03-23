`timescale 1ns/1ns
module adda_tb;
	`define sys_freq 50_000_000
	`define clk_period (1_000_000_000 /`sys_freq)

	reg i_clk;
	reg i_rst_n;

	initial i_clk = 1;
	always#(`clk_period/2) i_clk = ~i_clk;
	reg i_key;

	wire o_adc_cs_n;
	wire o_adc_sclk;
	wire o_adc_din;
	reg i_adc_dout;

	
adda adda(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	
	.i_key(i_key),
	.o_adc_cs_n(o_adc_cs_n),
	.o_adc_sclk(o_adc_sclk),
	.o_adc_din(o_adc_din),
	.i_adc_dout(i_adc_dout)

);


	reg [2:0]adc_addr;
	

	wire  [11:0] w_adc_data = 12'b0101_0101_0101; //110001000101
	wire  [11:0] w_adc_invalid_data = 12'b1010_1010_1010; //1100_0100_0101
	
	
	integer i;
	integer j;
	integer k;
	integer m;
	initial begin
	i_rst_n = 0;	
	i_key = 1'b1;
	i_adc_dout = 1'b1;
	adc_addr = 3'b0;
	i=0;
	j=0;
	k=0;
	m=0;
	
	#201;
	i_rst_n = 1;
	#200;
	i_key = 1'b0;
	#30_000_000;
	i_key = 1'b1;

	@(negedge o_adc_cs_n) begin
		repeat(2) begin
			@(posedge o_adc_sclk);
		end
		
		for(i = 0;i<2;i=i+1) begin
			@(posedge o_adc_sclk)
				adc_addr[2-i] = o_adc_din;
		end
		
		@(negedge o_adc_sclk)
			i_adc_dout = w_adc_invalid_data[11];
		@(posedge o_adc_sclk)
			adc_addr[0] = o_adc_din;
		for(j = 0;j<11;j=j+1) begin
			@(negedge o_adc_sclk)
				i_adc_dout = w_adc_invalid_data[10-j];
		end
	
	end
	
	adc_addr = 3'b0;
	
	@(negedge o_adc_cs_n) begin
		repeat(2) begin
			@(posedge o_adc_sclk);
		end
		

		for(k = 0;k<2;k=k+1) begin
			@(posedge o_adc_sclk)
				adc_addr[2-k] = o_adc_din;
		end

		@(negedge o_adc_sclk)
			i_adc_dout = w_adc_data[11];
		@(posedge o_adc_sclk)
			adc_addr[0] = o_adc_din;
		for(m = 0;m<11;m=m+1) begin
			@(negedge o_adc_sclk)
				i_adc_dout = w_adc_data[10-m];
		end
	
	end

	#10000;
	$stop;
	end



endmodule


//
//`timescale 1ns/1ns
//module adda_tb;
//
//
//
//	`define sys_freq 50_000_000
//	`define clk_period (1_000_000_000 /`sys_freq)
//
//	reg i_clk;
//	reg i_rst_n;
//
//	initial i_clk = 1;
//	always#(`clk_period/2) i_clk = ~i_clk;
//	reg i_key;
//
//	wire o_adc_cs_n;
//	wire o_adc_sclk;
//	wire o_adc_din;
//	reg i_adc_dout;
//
//	
//adda adda(
//	.i_clk(i_clk),
//	.i_rst_n(i_rst_n),
//	
//	.i_key(i_key),
//	.o_adc_cs_n(o_adc_cs_n),
//	.o_adc_sclk(o_adc_sclk),
//	.o_adc_din(o_adc_din),
//	.i_adc_dout(i_adc_dout)
//
//);
//
//
//	reg [2:0]adc_addr;
//	
//	integer i;
//	integer j;
//	
//	task adc_128s102;
//	input [11:0] adc_data;
//	input adc_cs_n;
//	input adc_sclk;
//	input adc_din;
//	output adc_dout;
//	begin 
//		adc_addr = 3'd0;
//		@(negedge adc_cs_n) begin
//			repeat(2) begin
//				@(posedge adc_sclk);
//			end
//			
//
//			for(i = 0;i<2;i=i+1) begin
//				@(posedge adc_sclk)
//					adc_addr[2-i] = adc_din;
//			end
//			
//			@(negedge adc_sclk)
//				adc_dout = adc_data[11];
//			@(posedge adc_sclk)
//				adc_addr[0] = adc_din;
//			for(j = 0;j<11;j=j+1) begin
//				@(negedge adc_sclk)
//					adc_dout = adc_data[10-j];
//			end
//		
//		end
//	end
//
//	endtask
//
//		
//
//	wire  [11:0] w_adc_data = 12'b0101_0101_0101; //110001000101
//	wire  [11:0] w_adc_invalid_data = 12'b1010_1010_1010; //1100_0100_0101
//	
//	
//	initial begin
//		i_rst_n = 0;	
//		i_key = 1'b1;
//		i_adc_dout = 1'b1;
//		adc_addr = 3'b0;
//		i=0;
//		j=0;
//		#201;
//		i_rst_n = 1;
//		#200;
//		i_key = 1'b0;
//		#30_000_000;
//		i_key = 1'b1;
//
//		adc_128s102(w_adc_invalid_data,o_adc_cs_n,o_adc_sclk,o_adc_din,i_adc_dout);
//		adc_128s102(w_adc_data,o_adc_cs_n,o_adc_sclk,o_adc_din,i_adc_dout);
//		#10000;
//		$stop;
//	end
//	
//endmodule
//	
//	
//	
//
