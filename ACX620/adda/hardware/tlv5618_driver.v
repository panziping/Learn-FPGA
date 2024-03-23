module tlv5618_driver(
	clk,
	rst_n,
	dac_data,
	dac_convert_en_go,
	dac_cs_n,
	dac_sclk,
	dac_din,
	dac_convert_busy
);

	input 		 clk;
	input 		 rst_n;
	input [15:0] dac_data;
	input 		 dac_convert_en_go;
	output 		 dac_cs_n;
	output 		 dac_sclk;
	output 		 dac_din;
	output 		 dac_convert_busy;
	
	
	
	//-----------------------------data_format----------------------------- //
	// D15 | D14 | D13 | D12 |						D11 ~ D0								//
	//  R1 | SPD | PWR |  R0 |					 DATA11~DATA0							//
	//----------------------------------------------------------------------//
	// R1 | R0 |              REGISTER          										//
	// 0  | 0  | Write data to DAC B and BUFFER 										//
	// 0  | 1  | Write data to BUFFER			  										//
	// 1  | 0  | Write data to DAC A and update DAC B with BUFFER content   //
	// 1  | 1  | Reserved																	//
	//----------------------------------------------------------------------//
	// SPD (Speed control bit) |       description  								//
	// 			  1			   | 			fast mode									//
	//  			  0 			   | 			slow mode									//
	// PWR (Power control bit) |       description  								//
	// 			  1			   | 			power down									//
	//  			  0 			   | 			normal operation							//
	//On power up,SPD and PWD are reset to 0(slow mode and normal operation)//
	//----------------------------------------------------------------------//
	
	
	reg [15:0] r_dac_data;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_dac_data <= 16'd0;
		else if(dac_convert_en_go == 1'b1)
			r_dac_data <= dac_data;
		else
			r_dac_data <= r_dac_data;
	end
	
	
	localparam SPI_CLK = 12_500_000;
	localparam SYS_FREQ = 50_000_000;
	localparam SPI_CLK_DR =  SYS_FREQ / SPI_CLK;	//freq = 12.5Mhz,Fmax = 20Mhz
	
	reg r_dac_convert_en;
	wire w_dac_convert_end;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_dac_convert_en <= 1'b0;
		else if(dac_convert_en_go == 1'b1)
			r_dac_convert_en <= 1'b1;
		else if(w_dac_convert_end == 1'b1)
			r_dac_convert_en <= 1'b0;
		else
			r_dac_convert_en <= r_dac_convert_en;
	end
	assign dac_convert_busy = r_dac_convert_en;

	reg [$clog2(SPI_CLK_DR)-1:0]r_div_cnt;
	wire w_sclk_pluse;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_div_cnt <= 'd0;
		else if(r_dac_convert_en == 1'b1) begin
			if(r_div_cnt == SPI_CLK_DR - 1'd1)
				r_div_cnt <= 'd0;
			else	
				r_div_cnt <= r_div_cnt + 1'd1;
		end
		else
			r_div_cnt <= 'd0;
	end
	assign w_sclk_pluse = (r_div_cnt == 'd1) ? 1'b1 : 1'b0;
	
	reg [5:0] r_bit_cnt;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_bit_cnt <= 6'd0;
		else if(r_dac_convert_en == 1'b1) begin
			if(w_sclk_pluse == 1'b1)
				r_bit_cnt <= r_bit_cnt + 1'b1;
			else 
				r_bit_cnt <= r_bit_cnt;
		end
		else
			r_bit_cnt <= 6'd0;
	end
	assign w_dac_convert_end = (r_bit_cnt == 6'd35) ? 1'b1 : 1'b0;
	
	
	reg r_dac_cs_n;
	reg r_dac_sclk;
	reg r_dac_din;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			r_dac_cs_n <= 1'b1;
			r_dac_din <= 1'b0;
			r_dac_sclk <= 1'b1;
		end
		else begin
			case(r_bit_cnt)
			6'd0 : begin r_dac_cs_n <= 1'b1; r_dac_din <= 1'b0; r_dac_sclk <= 1'b1; end
			6'd1 : begin r_dac_cs_n <= 1'b0; r_dac_din <= 1'b0; r_dac_sclk <= 1'b1; end
			6'd2 : begin r_dac_din <= r_dac_data[15]; r_dac_sclk <= 1'b1; end
			6'd3 : begin r_dac_sclk <= 1'b0; end
			6'd4 : begin r_dac_din <= r_dac_data[14]; r_dac_sclk <= 1'b1; end
			6'd5 : begin r_dac_sclk <= 1'b0; end
			6'd6 : begin r_dac_din <= r_dac_data[13]; r_dac_sclk <= 1'b1; end
			6'd7 : begin r_dac_sclk <= 1'b0; end	
			6'd8 : begin r_dac_din <= r_dac_data[12]; r_dac_sclk <= 1'b1; end
			6'd9 : begin r_dac_sclk <= 1'b0; end		
			6'd10 : begin r_dac_din <= r_dac_data[11]; r_dac_sclk <= 1'b1; end
			6'd11 : begin r_dac_sclk <= 1'b0; end			
			6'd12 : begin r_dac_din <= r_dac_data[10]; r_dac_sclk <= 1'b1; end
			6'd13 : begin r_dac_sclk <= 1'b0; end				
			6'd14 : begin r_dac_din <= r_dac_data[9]; r_dac_sclk <= 1'b1; end
			6'd15 : begin r_dac_sclk <= 1'b0; end		
			6'd16 : begin r_dac_din <= r_dac_data[8]; r_dac_sclk <= 1'b1; end
			6'd17 : begin r_dac_sclk <= 1'b0; end		
			6'd18 : begin r_dac_din <= r_dac_data[7]; r_dac_sclk <= 1'b1; end
			6'd19 : begin r_dac_sclk <= 1'b0; end		
			6'd20 : begin r_dac_din <= r_dac_data[6]; r_dac_sclk <= 1'b1; end
			6'd21 : begin r_dac_sclk <= 1'b0; end		
			6'd22 : begin r_dac_din <= r_dac_data[5]; r_dac_sclk <= 1'b1; end
			6'd23 : begin r_dac_sclk <= 1'b0; end		
			6'd24 : begin r_dac_din <= r_dac_data[4]; r_dac_sclk <= 1'b1; end
			6'd25 : begin r_dac_sclk <= 1'b0; end		
			6'd26 : begin r_dac_din <= r_dac_data[3]; r_dac_sclk <= 1'b1; end
			6'd27 : begin r_dac_sclk <= 1'b0; end
			6'd28 : begin r_dac_din <= r_dac_data[2]; r_dac_sclk <= 1'b1; end
			6'd29 : begin r_dac_sclk <= 1'b0; end	
			6'd30 : begin r_dac_din <= r_dac_data[1]; r_dac_sclk <= 1'b1; end
			6'd31 : begin r_dac_sclk <= 1'b0; end		
			6'd32 : begin r_dac_din <= r_dac_data[0]; r_dac_sclk <= 1'b1; end
			6'd33 : begin r_dac_sclk <= 1'b0; end			
			6'd34 : begin r_dac_cs_n <= 1'b0; r_dac_din <= 1'b0; r_dac_sclk <= 1'b1; end  //notes:the next positive clock edge following the 16th falling clock edge.
			6'd35 : begin r_dac_cs_n <= 1'b1; r_dac_din <= 1'b0; r_dac_sclk <= 1'b1; end
			default:begin r_dac_cs_n <= 1'b1; r_dac_din <= 1'b0; r_dac_sclk <= 1'b1; end
			endcase
		end
	
	end
	assign dac_sclk = r_dac_sclk;
	assign dac_cs_n = r_dac_cs_n;
	assign dac_din = r_dac_din;
	

	
endmodule
