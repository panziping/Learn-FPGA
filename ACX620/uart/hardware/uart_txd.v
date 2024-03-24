module uart_txd(
	clk,
	rst_n,
	txd_data,
	txd_en_go,
	parity,
	txd,
	txd_busy
);
	input 		clk;
	input 		rst_n;
	input [7:0] txd_data;
	input 		txd_en_go;
	input [1:0] parity;
	output 		txd;
	output 		txd_busy;
	
	localparam BAUD = 115200;
	localparam SYS_FREQ = 50_000_000;
	localparam BAUD_DR = SYS_FREQ / BAUD;	
	
	localparam P_EVEN = 2'b00;
	localparam P_ODD  = 2'b01;
	localparam P_NONE = 2'b10;
	
	
	reg [3:0] r_bit_width;
	always@(*) begin
		case(parity)
		P_EVEN : r_bit_width = 4'd12;
		P_ODD  : r_bit_width = 4'd12;
		P_NONE : r_bit_width = 4'd11;
		default :r_bit_width = 4'd11;
		endcase
	end
	
	
	reg [7:0] r_txd_data;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_txd_data <= 8'd0;
		else if(txd_en_go == 1'b1)
			r_txd_data <= txd_data;
		else 
			r_txd_data <= r_txd_data;
	end
	
	
	reg r_txd_en;
	reg [3:0] r_bit_cnt;
	wire w_txd_end;
	
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_txd_en <= 1'b0;
		else if(txd_en_go == 1'b1)
			r_txd_en <= 1'b1;
		else if(w_txd_end == 1'b1)
			r_txd_en <= 1'b0;
		else
			r_txd_en <= r_txd_en;
	end
	
	assign txd_busy = r_txd_en;
	assign w_txd_end = (r_bit_cnt == r_bit_width) ? 1'b1 : 1'b0;
	

	reg [$clog2(BAUD_DR)-1:0] r_baud_cnt;
	
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_baud_cnt <= 'd0;
		else if(r_txd_en == 1'b1) begin
			if(r_baud_cnt == BAUD_DR - 1)
				r_baud_cnt <= 'd0;
			else
				r_baud_cnt <= r_baud_cnt + 1'b1;
		end
		else
			r_baud_cnt <= 'd0;
	end
	wire w_bps_clk;
	assign w_bps_clk = (r_baud_cnt == 1'b1) ? 1'b1:1'b0;
	

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_bit_cnt <= 4'd0;
		else if(r_txd_en == 1'b1) begin
			if(w_bps_clk == 1'b1)
				r_bit_cnt <= r_bit_cnt + 1'b1;
			else
				r_bit_cnt <= r_bit_cnt;
		end
		else
			r_bit_cnt <= 4'd0;
	end
	
	
	reg r_txd;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			r_txd <= 1'b1;
		end
		else begin
			case(r_bit_cnt)
				0: begin r_txd <= 1'b1; end
				1: begin r_txd <= 1'b0; end
				2: begin r_txd <= r_txd_data[0]; end
				3: begin r_txd <= r_txd_data[1]; end
				4: begin r_txd <= r_txd_data[2]; end
				5: begin r_txd <= r_txd_data[3]; end
				6: begin r_txd <= r_txd_data[4]; end
				7: begin r_txd <= r_txd_data[5]; end
				8: begin r_txd <= r_txd_data[6]; end
				9: begin r_txd <= r_txd_data[7]; end
				10: begin
					case(parity)
						P_EVEN : r_txd <= ^r_txd_data;
						P_ODD  : r_txd <= ~^r_txd_data;
						P_NONE : r_txd <= 1'b1;
						default: r_txd <= 1'd1;
					endcase
				end
				11: begin r_txd <= 1'd1; end
				12: begin r_txd <= 1'd1; end
				default:begin r_txd <= 1'd1; end
			endcase
		end
	end
	
	assign txd = r_txd;
	
	
endmodule
