module seg_disp(
	clk,
	rst_n,
	disp_en,
	disp_data,
	disp_data_valid_go,
	seg_data,
	seg_data_valid_go
);
	input clk;
	input rst_n;
	input disp_en;
	input [31:0] disp_data;
	input disp_data_valid_go;
	output reg [14:0] seg_data;
	output reg seg_data_valid_go;
	
	
	reg [31:0] r_disp_data;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_disp_data <= 'd0;
		else if(disp_data_valid_go == 1'b1) 
			r_disp_data <= disp_data;
		else
			r_disp_data <= r_disp_data;
	end
	
	
	
	//segment refresh frequency: 1KHz
	localparam REFRESH_CNT_MAX = 50_000_000 / 1000;
	
	reg [$clog2(REFRESH_CNT_MAX)-1:0] r_refresh_cnt;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_refresh_cnt <= 'd0;
		else if(disp_en == 1'b1) 
			if(r_refresh_cnt == REFRESH_CNT_MAX - 1)
				r_refresh_cnt <= 'd0;
			else
				r_refresh_cnt <= r_refresh_cnt + 1'd1;
		else
			r_refresh_cnt <= 'd0;
	end
	wire w_refresh_pluse;
	assign w_refresh_pluse = (r_refresh_cnt == REFRESH_CNT_MAX - 1) ? 1'b1:1'b0;
	
	reg [7:0] r_seg_sel;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_seg_sel <= 8'b0000_0001;
		else if(w_refresh_pluse == 1'b1)
			r_seg_sel <= {r_seg_sel[6:0],r_seg_sel[7]};
		else
			r_seg_sel <= r_seg_sel;
	end
	
	
	reg [3:0] r_seg_disp;
	always@(*) begin
		case(r_seg_sel)
		8'b0000_0001 : r_seg_disp = r_disp_data[3:0];
		8'b0000_0010 : r_seg_disp = r_disp_data[7:4];
		8'b0000_0100 : r_seg_disp = r_disp_data[11:8];
		8'b0000_1000 : r_seg_disp = r_disp_data[15:12];
		8'b0001_0000 : r_seg_disp = r_disp_data[19:16];
		8'b0010_0000 : r_seg_disp = r_disp_data[23:20];
		8'b0100_0000 : r_seg_disp = r_disp_data[27:24];
		8'b1000_0000 : r_seg_disp = r_disp_data[31:28];		
		default:r_seg_disp = 4'b0000;
		endcase
	end
	
	reg [6:0] r_seg_code;
	always@(*) begin
		case(r_seg_disp)
			4'h0: r_seg_code = 7'b1000000;
			4'h1: r_seg_code = 7'b1111001;
			4'h2: r_seg_code = 7'b0100100;
			4'h3: r_seg_code = 7'b0110000;
			4'h4: r_seg_code = 7'b0011001;
			4'h5: r_seg_code = 7'b0010010;
			4'h6: r_seg_code = 7'b0000010;
			4'h7: r_seg_code = 7'b1111000;
			4'h8: r_seg_code = 7'b0000000;
			4'h9: r_seg_code = 7'b0010000;
			4'ha: r_seg_code = 7'b0001000;
			4'hb: r_seg_code = 7'b0000011;
			4'hc: r_seg_code = 7'b1000110;
			4'hd: r_seg_code = 7'b0100001;
			4'he: r_seg_code = 7'b0000110;
			4'hf: r_seg_code = 7'b0001110;
			default:;
		endcase
	end
	
	
	
	reg [1:0] r_refresh_pluse_sync;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_refresh_pluse_sync <= 'd0;
		else 
			r_refresh_pluse_sync <= {r_refresh_pluse_sync[0],w_refresh_pluse};
	end
	
	
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			seg_data <= 'd0;
			seg_data_valid_go <= 1'd0;
		end
		else if(r_refresh_pluse_sync[1] == 1'b1) begin
			seg_data <= disp_en ? {r_seg_code,r_seg_sel} : 15'd0;
			seg_data_valid_go <= disp_en ? 1'b1 : 1'b0;
		end	
		else begin
			seg_data <= seg_data;
			seg_data_valid_go <= seg_data_valid_go;
		end
	end

	
endmodule
