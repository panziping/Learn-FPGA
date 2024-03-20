module uart_rxd(
	clk,
	rst_n,
	rxd,
	parity,
	rxd_data,
	rxd_data_valid_go
); 
	input clk;
	input rst_n;
	input rxd;
	input [1:0] parity;
	output [7:0] rxd_data;
	output rxd_data_valid_go;
	
	
	localparam BAUD = 115200;
	localparam SYS_FREQ = 50_000_000;
	localparam BAUD_DR = SYS_FREQ / BAUD;
	
	
	localparam P_EVEN = 2'b00;
	localparam P_ODD  = 2'b01;
	localparam P_NONE = 2'b10;
	
	reg [3:0] r_bit_width;
	always@(*) begin
		case(parity)
		P_EVEN : r_bit_width = 4'd10;
		P_ODD  : r_bit_width = 4'd10;
		P_NONE : r_bit_width = 4'd9;
		default :r_bit_width = 4'd9;
		endcase
	end
	
	reg [2:0] r_rxd_sync;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_rxd_sync <= 'd0;
		else
			r_rxd_sync <= {r_rxd_sync[1:0],rxd};
	end
	
	wire w_rxd_nedge;
	assign w_rxd_nedge = (r_rxd_sync[2:1] == 2'b10) ? 1'b1:1'b0;
	

	reg r_rxd_en;
	reg [3:0] r_bit_cnt;
	wire w_rxd_end;
	reg r_rxd_data_error;
	reg [$clog2(BAUD_DR)-1:0] r_baud_cnt;
	
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_rxd_en <= 1'b0;
		else if(w_rxd_nedge == 1'b1)
			r_rxd_en <= 1'b1;
		else if(r_rxd_data_error == 1'b1 || w_rxd_end == 1'b1)
			r_rxd_en <= 1'b0;
		else
			r_rxd_en <= r_rxd_en;
	end
		
	assign w_rxd_end = (r_baud_cnt == BAUD_DR >> 1) && (r_bit_cnt == r_bit_width);
	
	

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_baud_cnt <= 'd0;
		else if(r_rxd_en == 1'b1)
			if(r_baud_cnt == BAUD_DR - 1'd1)
				r_baud_cnt <= 'd0;
			else 
				r_baud_cnt <= r_baud_cnt + 1'd1;
		else
			r_baud_cnt <= 'd0;
	end
	wire w_bps_clk;
	assign w_bps_clk = (r_baud_cnt == BAUD_DR >> 1 ) ? 1'b1:1'b0;
	

 	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_bit_cnt <= 'd0;
		else if(r_rxd_en == 1'b1)
			if(r_baud_cnt == BAUD_DR - 1'd1)
				r_bit_cnt <= r_bit_cnt + 1'b1;
			else
				r_bit_cnt <= r_bit_cnt;
		else
			r_bit_cnt <= 'd0;
	end
	
	

	reg [7:0] r_rxd_data;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			r_rxd_data_error <= 1'd0;
			r_rxd_data <= 8'd0;
		end
		else if(w_bps_clk == 1'b1) begin
			case(r_bit_cnt)
			4'd0: begin r_rxd_data_error <= (r_rxd_sync[2] == 1'b1) ? 1'b1 : 1'b0; end
			4'd1: begin r_rxd_data[0] <= r_rxd_sync[2];end
			4'd2: begin r_rxd_data[1] <= r_rxd_sync[2];end
			4'd3: begin r_rxd_data[2] <= r_rxd_sync[2];end
			4'd4: begin r_rxd_data[3] <= r_rxd_sync[2];end
			4'd5: begin r_rxd_data[4] <= r_rxd_sync[2];end
			4'd6: begin r_rxd_data[5] <= r_rxd_sync[2];end
			4'd7: begin r_rxd_data[6] <= r_rxd_sync[2];end	
			4'd8: begin r_rxd_data[7] <= r_rxd_sync[2];end
			4'd9: begin
				case(parity)
				P_EVEN : r_rxd_data_error <= (^r_rxd_data^r_rxd_sync[2] == 1'b0) ? 1'b0 : 1'b1;
				P_ODD  : r_rxd_data_error <= (^r_rxd_data^r_rxd_sync[2] == 1'b1) ? 1'b0 : 1'b1;
				P_NONE : r_rxd_data_error <=  (r_rxd_sync[2] == 1'b0) ? 1'b1 : 1'b0;
				default:r_rxd_data_error <= 1'd1;
				endcase
			end	
			4'd10: r_rxd_data_error <= (r_rxd_sync[2] == 1'b0) ? 1'b1 : 1'b0;
			default:;
			endcase
		end //else if
		else begin 
			r_rxd_data_error <= 1'd0;
			r_rxd_data <= r_rxd_data;
		end	
	end
	
	

	
	reg r_rxd_data_valid_go;
	always@(posedge clk or negedge rst_n) begin
			if(!rst_n)
				r_rxd_data_valid_go <= 1'b0;
			else if((r_baud_cnt == BAUD_DR >> 1) && (r_bit_cnt == r_bit_width))
				r_rxd_data_valid_go <= 1'b1;
			else
				r_rxd_data_valid_go <= 1'b0;
	end
	assign rxd_data = r_rxd_data;
	assign rxd_data_valid_go = r_rxd_data_valid_go;
	
	
endmodule

