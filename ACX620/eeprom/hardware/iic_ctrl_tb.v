`timescale 1ns/1ns
module iic_driver_tb;

`define sys_freq 50_000_000
`define clk_period (1_000_000_000 /`sys_freq)

	reg i_clk;
	reg i_rst_n;

	initial i_clk = 1;
	always#(`clk_period/2) i_clk = ~i_clk;


	reg  [6:0] 	device_addr;
	reg  [7:0] 	reg_addr;

	reg 			rdreg_req;
	wire [7:0] 	rd_data;
	
	reg 			wrreg_req;
	reg  [7:0] 	wr_data;
	wire 			rw_data_valid_go;
	
	wire iic_sclk;
	wire iic_sdat;
	pullup PUP (iic_sdat);

iic_ctrl iic_ctrl(
	.clk(i_clk),
	.rst_n(i_rst_n),
	
	.iic_device_addr(device_addr),
	.iic_reg_addr(reg_addr),
	
	.iic_rd_en_go(rdreg_req),
	.iic_rd_data(rd_data),
	
	.iic_wr_en_go(wrreg_req),
	.iic_wr_data(wr_data),
	.iic_rw_data_valid_go(rw_data_valid_go),
	.iic_busy(),
	.iic_sclk(iic_sclk),
	.iic_sdat(iic_sdat)
);

M24LC04B M24LC04B(
		.A0(0), 
		.A1(0), 
		.A2(0), 
		.WP(0), 
		.SDA(iic_sdat), 
		.SCL(iic_sclk), 
		.RESET(~i_rst_n)
);
localparam DEVICE_ID = 7'b1010_000;
	initial begin
		i_rst_n = 0;
		wrreg_req = 0;
		rdreg_req = 0;
		wr_data = 8'd0;
		device_addr ='d0;
		reg_addr ='d0;		
		#201;
		i_rst_n = 1;

		write_one_byte(DEVICE_ID,8'h0A,8'hd1);
		//#20000;
		write_one_byte(DEVICE_ID,8'h0B,8'hd2);
		//#20000;
		write_one_byte(DEVICE_ID,8'h0C,8'hd3);
		//#20000;
		write_one_byte(DEVICE_ID,8'h0D,8'hd4);
		//#20000;
		write_one_byte(DEVICE_ID,8'h0F,8'hd5);
		//#20000;
		
		read_one_byte(DEVICE_ID,8'h0A);
		//#20000;
		read_one_byte(DEVICE_ID,8'h0B);
		//#20000;
		read_one_byte(DEVICE_ID,8'h0C);
		//#20000;
		read_one_byte(DEVICE_ID,8'h0D);
		//#20000;
		read_one_byte(DEVICE_ID,8'h0F);
		//#20000;

		#10000;
		$stop;
	end



	task write_one_byte;
		input [6:0]id;
		input [7:0]mem_address; 
		input [7:0]data;
		begin
			device_addr = id;
			reg_addr = mem_address;

			wr_data = data;
			wrreg_req = 1;
			#20;
			wrreg_req = 0;
			@(posedge rw_data_valid_go);
			#20000;	
		end
	endtask
	
	task read_one_byte;
		input [6:0]id;
		input [7:0]mem_address;
		begin
			device_addr = id;
			reg_addr = mem_address;

			rdreg_req = 1;
			#20;
			rdreg_req = 0;
			@(posedge rw_data_valid_go);
			#20000;			
		end
	endtask
	

endmodule

