module iic_driver(
	clk,
	rst_n,
	iic_cmd,
	iic_en_go,
	rd_data,
	wr_data,
	trans_done,
	slave_ack,
	iic_sclk,
	iic_sdat
);

	input 			clk;
	input 			rst_n;
	
	input  [5:0] 	iic_cmd;
	input 			iic_en_go;
	
	output [7:0] 	rd_data;
	input  [7:0] 	wr_data;
	
	output 			trans_done;
	output 			slave_ack;
	
	output 			iic_sclk;
	inout 			iic_sdat;
	

	
	parameter SYS_CLOCK         = 50_000_000;
	parameter IIC_SCLK          = 400_000;
	localparam IIC_SCLK_CNT_MAX = SYS_CLOCK / IIC_SCLK / 4;
	
	reg r_sclk_div_en;
	reg [$clog2(IIC_SCLK_CNT_MAX)-1:0] r_sclk_div_cnt;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_sclk_div_cnt <= 'd0;
		else if(r_sclk_div_en == 1'b1)
			if(r_sclk_div_cnt == IIC_SCLK_CNT_MAX - 1'b1)
				r_sclk_div_cnt <= 'd0;
			else
				r_sclk_div_cnt <= r_sclk_div_cnt + 1'b1;
		else
			r_sclk_div_cnt <= 'd0;
	end
	
	wire w_sclk_plus;
	assign w_sclk_plus = (r_sclk_div_cnt == IIC_SCLK_CNT_MAX - 1'b1) ? 1'b1 : 1'b0; 
	
	reg [7:0] r_wr_data;
	reg [5:0] r_iic_cmd;
	reg r_iic_en_go;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)begin
			r_wr_data <= 8'd0;
			r_iic_cmd <= 6'd0;
		end
		else if(iic_en_go == 1'b1) begin
			r_wr_data <= wr_data;
			r_iic_cmd <= iic_cmd;
		end
		else begin
			r_wr_data <= r_wr_data;
			r_iic_cmd <= r_iic_cmd;
		end
	end
	
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_iic_en_go <= 1'b0;
		else
			r_iic_en_go <= iic_en_go;
	end
	
	
	
	
	localparam STA  = 6'b000_001;
	localparam WR   = 6'b000_010; 
	localparam RD   = 6'b000_100;
	localparam ACK  = 6'b001_000;
	localparam NACK = 6'b010_000;
	localparam STOP = 6'b100_000;
	
	localparam S_IDLE		  = 7'b0_000_001;
	localparam S_GEN_STA	  = 7'b0_000_010;
	localparam S_WR_DATA   = 7'b0_000_100;
	localparam S_RD_DATA	  = 7'b0_001_000;
	localparam S_CHECK_ACK = 7'b0_010_000;
	localparam S_GEN_ACK   = 7'b0_100_000;
	localparam S_GEN_STOP  = 7'b1_000_000;
	
	
	
	reg [6:0] r_current_state;
	reg [6:0] r_next_state;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_current_state <= S_IDLE;
		else
			r_current_state <= r_next_state;
	end
	
	reg [7:0] 	r_bit_cnt;

	always@(*) begin
		case(r_current_state)
			S_IDLE : begin
				if(r_iic_en_go == 1'b1) begin
					if(r_iic_cmd & STA)
						r_next_state = S_GEN_STA;
					else if(r_iic_cmd & WR)
						r_next_state = S_WR_DATA;
					else if(r_iic_cmd & RD)
						r_next_state = S_RD_DATA;
					else
						r_next_state = S_IDLE;
				end
				else
					r_next_state = S_IDLE; 
			end //S_IDLE
		
			S_GEN_STA: begin
				if(w_sclk_plus == 1'b1) begin
					if(r_bit_cnt == 'd3) begin
						if(r_iic_cmd & WR)
							r_next_state = S_WR_DATA;
						else if(r_iic_cmd & RD)
							r_next_state = S_RD_DATA;
						else
							r_next_state = S_IDLE;
					end
					else	
						r_next_state = S_GEN_STA;
				end 
				else
					r_next_state = S_GEN_STA;
			end //S_GEN_STA
		
			S_WR_DATA: begin
				if(w_sclk_plus == 1'b1) begin
					if(r_bit_cnt == 'd31)
						r_next_state = S_CHECK_ACK;
					else
						r_next_state = S_WR_DATA;
				end 
				else
					r_next_state = S_WR_DATA;
			end // S_WR_DATA

			S_RD_DATA: begin
				if(w_sclk_plus == 1'b1) begin
					if(r_bit_cnt == 'd31)
						r_next_state = S_GEN_ACK;
					else
						r_next_state = S_RD_DATA;
				end
				else
					r_next_state = S_RD_DATA;
			end // S_RD_DATA
			
			S_CHECK_ACK: begin
				if(w_sclk_plus == 1'b1) begin
					if(r_bit_cnt == 'd3) begin
						if(r_iic_cmd & STOP)
							r_next_state = S_GEN_STOP;
						else 
							r_next_state = S_IDLE;
					end
					else
						r_next_state = S_CHECK_ACK;
				end
				else
					r_next_state = S_CHECK_ACK;
			end // S_CHECK_ACK
		
			S_GEN_ACK: begin
				if(w_sclk_plus == 1'b1) begin
					if(r_bit_cnt == 'd3) begin
						if(r_iic_cmd & STOP)
							r_next_state = S_GEN_STOP;
						else
							r_next_state = S_IDLE;
					end
					else
						r_next_state = S_GEN_ACK;
				end
				else
					r_next_state = S_GEN_ACK;
			end //S_GEN_ACK
			S_GEN_STOP: begin
				if(w_sclk_plus == 1'b1) begin
					if(r_bit_cnt == 'd3)
						r_next_state = S_IDLE;
					else
						r_next_state = S_GEN_STOP;
				end
				else
					r_next_state = S_GEN_STOP;
			end // S_GEN_STOP	
			default:r_next_state = S_IDLE;
		endcase
	end
	
	

	reg 		  	r_iic_sclk;
	reg 			r_iic_sdat_o;
	reg  			r_iic_sdat_en;
	reg 			r_slave_ack;
	reg [7:0] 	r_rd_data;
	
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			r_bit_cnt <= 'd0;
			r_iic_sclk <= 1'b1;
			r_iic_sdat_o <= 1'b1;
			r_iic_sdat_en <= 1'b0;
			r_slave_ack <= 1'b1;
			r_rd_data <= 8'd0;
			r_sclk_div_en <= 1'b0;
		end
		else begin
			case(r_current_state)
			S_IDLE : begin
				r_sclk_div_en <= 1'b0;
				r_iic_sdat_en <= 1'b0;
				//r_iic_sclk <= 1'b1; // dont pull up. Unless the sclk bus is a hiz state
				r_bit_cnt <= 'd0;
				if(r_iic_en_go == 1'b1)
					r_sclk_div_en <= 1'b1;
				else
					r_sclk_div_en <= 1'b0;
			end //S_IDLE
			
			S_GEN_STA: begin
				if(w_sclk_plus == 1'b1) begin
					if(r_bit_cnt == 'd3)
						r_bit_cnt <= 'd0;
					else
						r_bit_cnt <= r_bit_cnt + 1'd1;
						
					case(r_bit_cnt)
						'd0: begin r_iic_sclk <= 1'b1; r_iic_sdat_o <= 1'b1; r_iic_sdat_en <= 1'b1; end
						'd1: begin r_iic_sclk <= 1'b1; r_iic_sdat_o <= 1'b1; r_iic_sdat_en <= 1'b1; end
						'd2: begin r_iic_sclk <= 1'b1; r_iic_sdat_o <= 1'b0; r_iic_sdat_en <= 1'b1; end
						'd3: begin r_iic_sclk <= 1'b0; r_iic_sdat_o <= 1'b0; r_iic_sdat_en <= 1'b1; end
						default: begin r_iic_sclk <= 1'b1; r_iic_sdat_o <= 1'b1; r_iic_sdat_en <= 1'b0; end
					endcase
				end 
				else begin
					r_bit_cnt <= r_bit_cnt;
					r_iic_sclk <= r_iic_sclk;
					r_iic_sdat_o <= r_iic_sdat_o;
					r_iic_sdat_en <= r_iic_sdat_en;
				end
			end //S_GEN_STA
			
			S_WR_DATA: begin
				if(w_sclk_plus == 1'b1) begin
					if(r_bit_cnt == 'd31)
						r_bit_cnt <= 'd0;
					else
						r_bit_cnt <= r_bit_cnt + 1'b1;
						
					case(r_bit_cnt)
						'd0,'d4,'d8, 'd12,'d16,'d20,'d24,'d28: begin r_iic_sclk <= 1'b0; r_iic_sdat_o <= r_wr_data[7 - r_bit_cnt[4:2]]; r_iic_sdat_en <= 1'b1; end 
						'd1,'d5,'d9, 'd13,'d17,'d21,'d25,'d29: begin r_iic_sclk <= 1'b1; r_iic_sdat_o <= r_iic_sdat_o; r_iic_sdat_en <= 1'b1; end
						'd2,'d6,'d10,'d14,'d18,'d22,'d26,'d30: begin r_iic_sclk <= 1'b1; r_iic_sdat_o <= r_iic_sdat_o; r_iic_sdat_en <= 1'b1; end
						'd3,'d7,'d11,'d15,'d19,'d23,'d27,'d31: begin r_iic_sclk <= 1'b0; r_iic_sdat_o <= r_iic_sdat_o; r_iic_sdat_en <= 1'b1; end
						default: begin r_iic_sclk <= 1'b1; r_iic_sdat_o <= 1'b1; r_iic_sdat_en <= 1'b0; end
					endcase
				end 
				else begin
					r_bit_cnt <= r_bit_cnt;
					r_iic_sclk <= r_iic_sclk;
					r_iic_sdat_o <= r_iic_sdat_o;
					r_iic_sdat_en <= r_iic_sdat_en;
				end
			end // S_WR_DATA
			
			S_RD_DATA: begin
				if(w_sclk_plus == 1'b1) begin
					if(r_bit_cnt == 'd31)
						r_bit_cnt <= 'd0;
					else
						r_bit_cnt <= r_bit_cnt + 1'b1;
						
					case(r_bit_cnt)
						'd0,'d4,'d8, 'd12,'d16,'d20,'d24,'d28: begin r_iic_sclk <= 1'b0; r_iic_sdat_en <= 1'b0; end 
						'd1,'d5,'d9, 'd13,'d17,'d21,'d25,'d29: begin r_iic_sclk <= 1'b1; r_iic_sdat_en <= 1'b0; end
						'd2,'d6,'d10,'d14,'d18,'d22,'d26,'d30: begin r_iic_sclk <= 1'b1; r_rd_data <= {r_rd_data[6:0],iic_sdat}; r_iic_sdat_en <= 1'b0; end
						'd3,'d7,'d11,'d15,'d19,'d23,'d27,'d31: begin r_iic_sclk <= 1'b0; r_rd_data <= r_rd_data; r_iic_sdat_en <= 1'b0; end
						default: begin r_iic_sclk <= 1'b1; r_iic_sdat_o <= 1'b1; r_iic_sdat_en <= 1'b0; end
					endcase
				end
				else begin
					r_bit_cnt <= r_bit_cnt;
					r_iic_sclk <= r_iic_sclk;
					r_iic_sdat_o <= r_iic_sdat_o;
					r_iic_sdat_en <= r_iic_sdat_en;
					r_rd_data <= r_rd_data;
				end
			end // S_RD_DATA
			
			S_CHECK_ACK: begin
				if(w_sclk_plus == 1'b1) begin
					if(r_bit_cnt == 'd3)
						r_bit_cnt <= 'd0;
					else
						r_bit_cnt <= r_bit_cnt + 1'b1;
						
					case(r_bit_cnt)
						'd0: begin r_iic_sclk <= 1'b0; r_iic_sdat_en <= 1'b0; end
						'd1: begin r_iic_sclk <= 1'b1; r_iic_sdat_en <= 1'b0; end
						'd2: begin r_iic_sclk <= 1'b1; r_slave_ack <= iic_sdat; r_iic_sdat_en <= 1'b0; end
						'd3: begin r_iic_sclk <= 1'b0; r_slave_ack <=r_slave_ack; r_iic_sdat_en <= 1'b0; end
						default: begin r_iic_sclk <= 1'b1; r_iic_sdat_o <= 1'b1; r_iic_sdat_en <= 1'b0; end
					endcase
				end
				else begin
					r_bit_cnt <= r_bit_cnt;
					r_iic_sclk <= r_iic_sclk;
					r_iic_sdat_o <= r_iic_sdat_o;
					r_iic_sdat_en <= r_iic_sdat_en;
					r_slave_ack <= r_slave_ack;
				end
			end // S_CHECK_ACK
			
			S_GEN_ACK: begin
				if(w_sclk_plus == 1'b1) begin
					if(r_bit_cnt == 'd3)
						r_bit_cnt <= 'd0;
					else
						r_bit_cnt <= r_bit_cnt + 1'b1;
						
					case(r_bit_cnt) 
						'd0: begin 
							r_iic_sclk <= 1'b0; 
							if(r_iic_cmd & ACK)
								r_iic_sdat_o <= 1'b0;
							else if(r_iic_cmd & NACK)
								r_iic_sdat_o <= 1'b1;
							else
								r_iic_sdat_o <= r_iic_sdat_o;
							r_iic_sdat_en <= 1'b1;
						end
						'd1: begin r_iic_sclk <= 1'b1; r_iic_sdat_o <= r_iic_sdat_o; r_iic_sdat_en <= 1'b1; end
						'd2: begin r_iic_sclk <= 1'b1; r_iic_sdat_o <= r_iic_sdat_o; r_iic_sdat_en <= 1'b1; end
						'd3: begin r_iic_sclk <= 1'b0; r_iic_sdat_o <= r_iic_sdat_o; r_iic_sdat_en <= 1'b1; end
						default: begin r_iic_sclk <= 1'b1; r_iic_sdat_o <= 1'b1; r_iic_sdat_en <= 1'b0; end
					endcase	
				end
				else begin
					r_bit_cnt <= r_bit_cnt;
					r_iic_sclk <= r_iic_sclk;
					r_iic_sdat_o <= r_iic_sdat_o;
					r_iic_sdat_en <= r_iic_sdat_en;
				end
				
			end //S_GEN_ACK
			
			S_GEN_STOP: begin
				if(w_sclk_plus == 1'b1) begin
					if(r_bit_cnt == 'd3)
						r_bit_cnt <= 'd0;
					else
						r_bit_cnt <= r_bit_cnt + 1'b1;
						
					case(r_bit_cnt)
						'd0: begin r_iic_sclk <= 1'b0;r_iic_sdat_o <= 1'b0; r_iic_sdat_en <= 1'b1; end
						'd1: begin r_iic_sclk <= 1'b1;r_iic_sdat_o <= 1'b0; r_iic_sdat_en <= 1'b1; end
						'd2: begin r_iic_sclk <= 1'b1;r_iic_sdat_o <= 1'b1; r_iic_sdat_en <= 1'b1; end
						'd3: begin r_iic_sclk <= 1'b1;r_iic_sdat_o <= 1'b1; r_iic_sdat_en <= 1'b1; end
						default:begin r_iic_sclk <= 1'b1; r_iic_sdat_o <= 1'b1; r_iic_sdat_en <= 1'b0; end
					endcase
				end
				else begin
					r_bit_cnt <= r_bit_cnt;
					r_iic_sclk <= r_iic_sclk;
					r_iic_sdat_o <= r_iic_sdat_o;
					r_iic_sdat_en <= r_iic_sdat_en;
				end
			end // S_GEN_STOP	
			default : begin
				r_bit_cnt <= 'd0;
				r_iic_sclk <= 1'b1;
				r_iic_sdat_o <= 1'b1;
				r_iic_sdat_en <= 1'b0;
				r_slave_ack <= 1'b1;
				r_rd_data <= 8'd0;
				r_sclk_div_en <= 1'b0;
			end
			endcase
		end
	end
	
	assign iic_sclk = r_iic_sclk;
	assign slave_ack = r_slave_ack;
	assign rd_data = r_rd_data;

	assign iic_sdat = (r_iic_sdat_en && !r_iic_sdat_o) ? 1'b0 : 1'bz;
	
	
	reg r_trans_done;
	always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			r_trans_done <= 1'b0;
		else if(r_current_state == S_CHECK_ACK && r_next_state == S_IDLE)
			r_trans_done <= 1'b1;
		else if(r_current_state == S_GEN_ACK && r_next_state == S_IDLE)
			r_trans_done <= 1'b1;	
		else if(r_current_state == S_GEN_STOP && r_next_state == S_IDLE)
			r_trans_done <= 1'b1;
		else
			r_trans_done <= 1'b0;
	end
	
	
	assign trans_done = r_trans_done;

endmodule 

