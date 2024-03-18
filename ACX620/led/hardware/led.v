`timescale 1ns/1ns
//function:key0 push on,led left shift.key1 push on ,led right shift.
module led(			
	clk,
	rst_n,
	key,
	led
);


	input clk;
	input rst_n;
	input [1:0] key;
	output reg [3:0] led;

	reg [31:0] r_led_cnt;
	
	localparam LED_CNT_MAX = 500_000_000/20;	//500ms
	

	always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			r_led_cnt <= 'd0;
		else if(r_led_cnt == LED_CNT_MAX - 1)
			r_led_cnt <= 'd0;
		else
			r_led_cnt <= r_led_cnt + 1'd1;
	end

	
	wire [1:0] w_key_state_valid_go;
	
key_filter key_filter1(	//left shift
	.clk(clk),
	.rst_n(rst_n),
	.key(key[0]),
	.key_state_valid_go(w_key_state_valid_go[0])	//1:push on;0:no push.
);	


key_filter key_filter2(	// right shift
	.clk(clk),
	.rst_n(rst_n),
	.key(key[1]),
	.key_state_valid_go(w_key_state_valid_go[1])	//1:push on;0:no push.
);
	
	reg r_shift_en;
	always@(posedge clk)
	begin
		if(!rst_n)
			r_shift_en <= 1'd0;
		else if(w_key_state_valid_go[0] == 1'b1)	
			r_shift_en <= 1'd1;
		else if(w_key_state_valid_go[1] == 1'b1)
			r_shift_en <= 1'd0;
		else
			r_shift_en <= r_shift_en; 
	end
	
	always@(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
			led <= 4'b1110;
		else if(r_shift_en) begin
			if(r_led_cnt == LED_CNT_MAX - 1)
				led <= {led[0],led[3:1]};
			else
				led <= led;
		end
		else begin
			if(r_led_cnt == LED_CNT_MAX - 1)
				led <= {led[2:0],led[3]};
			else
				led <= led;
		end
	end
	
endmodule
	