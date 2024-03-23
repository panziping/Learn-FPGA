module adc128s102_driver(
	clk,
	rst_n,
	adc_addr,
	adc_convert_en_go,
	adc_cs_n,
	adc_sclk,
	adc_dout,
	adc_din,
	adc_convert_busy,
	adc_data,
	adc_data_convert_valid_go
);

	input clk;
	input rst_n;
	
	input [2:0] adc_addr;
	input adc_convert_en_go;
	
	output adc_cs_n;
	output adc_sclk;
	input  adc_dout;
	output adc_din;
	output adc_convert_busy;
	
	output [11:0] adc_data;
	output adc_data_convert_valid_go;
	

	reg [2:0] r_adc_addr;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_adc_addr <= 3'd0;
		else if(adc_convert_en_go == 1'b1)
			r_adc_addr <= adc_addr;
		else
			r_adc_addr <= r_adc_addr;
	end
	
	reg r_adc_convert_en;
	wire w_adc_convert_end;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_adc_convert_en <= 1'b0;
		else if(adc_convert_en_go == 1'b1)
			r_adc_convert_en <= 1'b1;
		else if(w_adc_convert_end == 1'b1)
			r_adc_convert_en <= 1'b0;
		else
			r_adc_convert_en <= r_adc_convert_en;
	end
	
	assign adc_convert_busy = r_adc_convert_en;

	

	
	localparam SYSCLK = 50_000_000;
	localparam SPI_CLK = 6_250_000;
	localparam SPI_CLK_DR = SYSCLK / SPI_CLK;
	
	reg [$clog2(SPI_CLK_DR)-1:0] r_div_cnt;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_div_cnt <= 'd0;
		else if(r_adc_convert_en == 1'b1) begin
			if(r_div_cnt == SPI_CLK_DR - 1'b1)
				r_div_cnt <= 'd0;
			else
				r_div_cnt <= r_div_cnt + 1'b1;
		end
		else
			r_div_cnt <= 'd0;
	end
	wire w_sclk_pluse;
	assign w_sclk_pluse = (r_div_cnt == 'd1) ? 1'b1 : 1'b0; 
	
	
	
	
	reg [5:0] r_bit_cnt;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_bit_cnt <= 6'd0;
		else if(r_adc_convert_en == 1'b1) begin
			if(w_sclk_pluse == 1'b1)
				r_bit_cnt <= r_bit_cnt + 1'b1;
			else
				r_bit_cnt <= r_bit_cnt;
		end
		else
			r_bit_cnt <= 6'd0;
	end
	assign w_adc_convert_end = (r_bit_cnt == 6'd35) ? 1'b1 : 1'b0;
	
	
	
	//fpga negedge output addr data,adc posedge collect addr data
	//fpga posedge collect adc data,adc negedge output adc data
	reg r_adc_cs_n;
	reg [11:0] r_adc_data;
	reg r_adc_sclk;
	reg r_adc_din;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			r_adc_data <= 12'd0;
			r_adc_cs_n <= 1'd1;
			r_adc_sclk <= 1'b1;
			r_adc_din <= 1'b1;
		end
		else begin
			case(r_bit_cnt)
			6'd0: begin r_adc_cs_n <= 1'b1; r_adc_sclk <= 1'b1; r_adc_din <= 1'b1; end
			6'd1: begin r_adc_cs_n <= 1'b0; r_adc_sclk <= 1'b1; r_adc_din <= 1'b1; end
			6'd2: begin r_adc_sclk <= 1'b0; r_adc_din <= 1'b1; end
			6'd3: begin r_adc_sclk <= 1'b1; r_adc_din <= 1'b1; end
			6'd4: begin r_adc_sclk <= 1'b0; r_adc_din <= 1'b1; end
			6'd5: begin r_adc_sclk <= 1'b1; r_adc_din <= 1'b1; end
			6'd6: begin r_adc_sclk <= 1'b0; r_adc_din <= r_adc_addr[2]; end
			6'd7: begin r_adc_sclk <= 1'b1; end
			6'd8: begin r_adc_sclk <= 1'b0; r_adc_din <= r_adc_addr[1]; end
			6'd9: begin r_adc_sclk <= 1'b1; end	
			6'd10: begin r_adc_sclk <= 1'b0; r_adc_din <= r_adc_addr[0]; end
			6'd11: begin r_adc_sclk <= 1'b1; r_adc_data[11] <= adc_dout; end
			6'd12: begin r_adc_sclk <= 1'b0; end
			6'd13: begin r_adc_sclk <= 1'b1; r_adc_data[10] <= adc_dout; end		
			6'd14: begin r_adc_sclk <= 1'b0; end
			6'd15: begin r_adc_sclk <= 1'b1; r_adc_data[9] <= adc_dout; end	
			6'd16: begin r_adc_sclk <= 1'b0; end
			6'd17: begin r_adc_sclk <= 1'b1; r_adc_data[8] <= adc_dout; end	
			6'd18: begin r_adc_sclk <= 1'b0; end
			6'd19: begin r_adc_sclk <= 1'b1; r_adc_data[7] <= adc_dout; end				
			6'd20: begin r_adc_sclk <= 1'b0; end
			6'd21: begin r_adc_sclk <= 1'b1; r_adc_data[6] <= adc_dout; end			
			6'd22: begin r_adc_sclk <= 1'b0; end
			6'd23: begin r_adc_sclk <= 1'b1; r_adc_data[5] <= adc_dout; end			
			6'd24: begin r_adc_sclk <= 1'b0; end
			6'd25: begin r_adc_sclk <= 1'b1; r_adc_data[4] <= adc_dout; end				
			6'd26: begin r_adc_sclk <= 1'b0; end
			6'd27: begin r_adc_sclk <= 1'b1; r_adc_data[3] <= adc_dout; end			
			6'd28: begin r_adc_sclk <= 1'b0; end
			6'd29: begin r_adc_sclk <= 1'b1; r_adc_data[2] <= adc_dout; end	
			6'd30: begin r_adc_sclk <= 1'b0; end
			6'd31: begin r_adc_sclk <= 1'b1; r_adc_data[1] <= adc_dout; end		
			6'd32: begin r_adc_sclk <= 1'b0; end
			6'd33: begin r_adc_sclk <= 1'b1; r_adc_data[0] <= adc_dout; end	
			6'd34: begin r_adc_cs_n <= 1'b1; r_adc_sclk <= 1'b1; r_adc_din <= 1'b1;end	
			6'd35: begin r_adc_cs_n <= 1'b1; r_adc_sclk <= 1'b1; r_adc_din <= 1'b1;end		
			default:begin r_adc_cs_n <= 1'd1;r_adc_sclk <= 1'b1; r_adc_din <= 1'b1;end
			endcase
		end
	end
	
	assign adc_cs_n = r_adc_cs_n;
	assign adc_sclk = r_adc_sclk;
	assign adc_din = r_adc_din;
	assign adc_data = r_adc_data;
	
	reg r_adc_data_valid_go;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_adc_data_valid_go <= 1'b0;
		else if(r_bit_cnt == 6'd34 && r_div_cnt == SPI_CLK_DR - 1'b1) 
			r_adc_data_valid_go <= 1'b1;
		else
			r_adc_data_valid_go <= 1'b0;
	end
	assign adc_data_convert_valid_go = r_adc_data_valid_go;
	



endmodule

