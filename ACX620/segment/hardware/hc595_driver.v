module hc595_driver(
	clk,
	rst_n,
	seg_data,
	seg_data_valid_go,
	seg_sclk,
	seg_rclk,
	seg_dio
);

	input clk;
	input rst_n;
	input [15:0] seg_data;
	input seg_data_valid_go;
	output reg seg_sclk;
	output reg seg_rclk;
	output reg seg_dio;
	

	reg [15:0] r_seg_data;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_seg_data <= 'd0;
		else if(seg_data_valid_go == 1'b1)
			r_seg_data <= seg_data;
		else
			r_seg_data <= r_seg_data;
	end
	
	localparam DIV_CNT_MAX = 4;			//fseg_sclk = 6.25MHz
	reg [2:0] r_div_cnt;
	
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_div_cnt <= 'd0;
		else if(r_div_cnt == DIV_CNT_MAX -1)
			r_div_cnt <= 'd0;
		else	
			r_div_cnt <= r_div_cnt + 1'b1;
	end
	wire w_sclk_pluse;	//SH_CP
	assign w_sclk_pluse = (r_div_cnt == DIV_CNT_MAX -1) ? 1'b1 :1'b0;
	
	
	reg [4:0] r_sclk_edge_cnt;	//SH_CP
	
	
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_sclk_edge_cnt <= 'd0;
		else if(w_sclk_pluse == 1'b1)
			if(r_sclk_edge_cnt == 5'd31)
				r_sclk_edge_cnt <= 'd0;
			else
				r_sclk_edge_cnt <= r_sclk_edge_cnt + 1'd1;
		else
			r_sclk_edge_cnt <= r_sclk_edge_cnt;
	end
	

	
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			seg_sclk <= 1'd0;
			seg_rclk <= 1'd0;
			seg_dio <= 1'd0;
		end
		else begin
			case(r_sclk_edge_cnt)
				5'd0 : begin seg_sclk = 1'b0; seg_rclk = 1'b1; seg_dio = r_seg_data[15]; end //Q2H(HEX_DP)
				5'd1 : begin seg_sclk = 1'b1; seg_rclk = 1'b0;  								 end 
				5'd2 : begin seg_sclk = 1'b0;				        seg_dio = r_seg_data[14]; end //Q2G(HEX_G)
				5'd3 : begin seg_sclk = 1'b1;								   						 end
				5'd4 : begin seg_sclk = 1'b0;				        seg_dio = r_seg_data[13]; end //Q2F(HEX_F)
				5'd5 : begin seg_sclk = 1'b1;														    end
				5'd6 : begin seg_sclk = 1'b0;				        seg_dio = r_seg_data[12]; end //Q2E(HEX_E)
				5'd7 : begin seg_sclk = 1'b1;														    end
				5'd8 : begin seg_sclk = 1'b0;				        seg_dio = r_seg_data[11]; end //Q2D(HEX_D)	
				5'd9 : begin seg_sclk = 1'b1;														    end
				5'd10: begin seg_sclk = 1'b0;				        seg_dio = r_seg_data[10]; end //Q2C(HEX_C)	
				5'd11: begin seg_sclk = 1'b1;														    end
				5'd12: begin seg_sclk = 1'b0;				        seg_dio = r_seg_data[9];  end //Q2B(HEX_B)	
				5'd13: begin seg_sclk = 1'b1;					    									 end
				5'd14: begin seg_sclk = 1'b0;				        seg_dio = r_seg_data[8];  end //Q2A(HEX_A)
				5'd15: begin seg_sclk = 1'b1;					    									 end
				5'd16: begin seg_sclk = 1'b0;				        seg_dio = r_seg_data[7];  end //Q1H(HEX_SEL7)		
				5'd17: begin seg_sclk = 1'b1;					    									 end
				5'd18: begin seg_sclk = 1'b0;				        seg_dio = r_seg_data[6];  end //Q1G(HEX_SEL6)
				5'd19: begin seg_sclk = 1'b1;					    									 end
				5'd20: begin seg_sclk = 1'b0;				        seg_dio = r_seg_data[5];  end //Q1F(HEX_SEL5)
				5'd21: begin seg_sclk = 1'b1;					    									 end
				5'd22: begin seg_sclk = 1'b0;				        seg_dio = r_seg_data[4];  end //Q1E(HEX_SEL4)		
				5'd23: begin seg_sclk = 1'b1;					    									 end
				5'd24: begin seg_sclk = 1'b0;				        seg_dio = r_seg_data[3];  end //Q1D(HEX_SEL3)			
				5'd25: begin seg_sclk = 1'b1;					    									 end
				5'd26: begin seg_sclk = 1'b0;				        seg_dio = r_seg_data[2];  end //Q1C(HEX_SEL2)	
				5'd27: begin seg_sclk = 1'b1;					    									 end
				5'd28: begin seg_sclk = 1'b0;				        seg_dio = r_seg_data[1];  end //Q1B(HEX_SEL1)	
				5'd29: begin seg_sclk = 1'b1;					    									 end
				5'd30: begin seg_sclk = 1'b0;				        seg_dio = r_seg_data[0];  end //Q1A(HEX_SEL0)
				5'd31: begin seg_sclk = 1'b1;					    									 end
				default:;
			endcase
		end
	end

endmodule 
