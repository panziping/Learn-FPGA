module key_filter(
	clk,
	rst_n,
	key,
	key_state_valid_go	//1:push on;0:no push.
);

	input clk;
	input rst_n;
	input key;
	output reg key_state_valid_go;

	
	
	
	//--------key wave----------//
	//---|___________|----------//
	//**************************//

	reg [2:0] r_key_sync;
	always@(posedge clk) begin
		if(!rst_n) 
			r_key_sync <= 'd0;
		else 
			r_key_sync <= {r_key_sync[1:0],key};
	end
	
	assign w_key_pedge  = (r_key_sync[2:1]  == 2'b01);
	assign w_key_nedge  = (r_key_sync[2:1]  == 2'b10);
	
	
	localparam S_IDLE 		= 4'b0001;
	localparam S_FILTER0 	= 4'b0010;
	localparam S_DONE		 	= 4'b0100; 	
	localparam S_FILTER1 	= 4'b1000;

	reg [3:0] r_state;
	
	
	
	
	/*---------------------------------state----------------------------------------------*/
	// S_IDLE    -> S_FILTER0 : w_key_nedge == 1'b1													  //
	// S_FILTER0 -> S_IDLE    : w_key_pedge == 1'b1													  //
	// S_FILTER0 -> S_DONE	  : r_timer_cnt == TIMER_CNT_MAX - 1 && r_key_sync[2] == 1'b0 //
	// S_DONE	 -> S_FILTER1 : w_key_pedge == 1'b1													  //
	// S_FILTER1 -> S_DONE    : w_key_nedge == 1'b1													  //
	// s_FILTER1 -> S_IDLE	  : r_timer_cnt == TIMER_CNT_MAX - 1 && r_key_sync[2] == 1'b1 Z//
	
	/*---------------------------------state----------------------------------------------*/
	
	
	
	localparam TIMER_CNT_MAX = 20_000_000 / 20;//20ms
	reg [19:0] r_timer_cnt;
	reg r_cnt_en;
	
	always@(posedge clk)
	begin
		if(!rst_n)
			r_timer_cnt <= 'd0;
		else if(r_cnt_en == 1'b1)
			r_timer_cnt <= r_timer_cnt + 1'b1;
		else
			r_timer_cnt <= 'd0;
	end
	
	
	always@(posedge clk) begin
		if(!rst_n) begin
			r_state <= S_IDLE;
			r_cnt_en <= 1'b0;
			key_state_valid_go <= 1'd0;
		end
		else begin
			case(r_state)
			S_IDLE: begin
				if(w_key_nedge == 1'b1) begin
					r_state <= S_FILTER0;
					r_cnt_en <= 1'b1;
				end
				else begin
					r_state <= S_IDLE;
					r_cnt_en <= 1'b0;
					key_state_valid_go <= 1'd0;
				end
			end
			S_FILTER0: begin
				if(w_key_pedge == 1'b1) begin
					r_state <= S_IDLE;
					r_cnt_en <= 1'b0;
				end
				else if(r_timer_cnt == TIMER_CNT_MAX - 1 && r_key_sync[2] == 1'b0) begin
					r_state <= S_DONE;
					r_cnt_en <= 1'b0;
				end
				else begin
					r_state <= S_FILTER0;
					r_cnt_en <= r_cnt_en;
				end
			end
			S_DONE: begin
				if(w_key_pedge == 1'b1) begin
					r_state <= S_FILTER1;
					r_cnt_en <= 1'd1;
				end
				else begin
					r_state <= S_DONE;
					r_cnt_en <= 1'b0;
				end
			end
			S_FILTER1: begin
				if(w_key_nedge == 1'b1) begin
					r_state <= S_DONE;
					r_cnt_en <= 1'b0;
				end
				else if(r_timer_cnt == TIMER_CNT_MAX - 1 && r_key_sync[2] == 1'b1) begin
					r_state <= S_IDLE;
					r_cnt_en <= 1'b0;
					key_state_valid_go <= 1'd1;
				end
				else begin
					r_state <= S_FILTER1;
					r_cnt_en <= r_cnt_en;
				end 
			end 
			default: begin
				r_state <= S_IDLE;
				r_cnt_en <= 1'b0;
			end 
			endcase
		end 
	end
	

endmodule
