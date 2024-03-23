module adc_ctrl(
	clk,
	rst_n,
	
	adc_addr,
	key_press_valid_go,
	
	adc_cs_n,
	adc_sclk,
	adc_dout,
	adc_din,
	
	adc_data,
	adc_data_valid_go
);


	input 			clk;
	input 			rst_n;
	input 			key_press_valid_go;
	input [2:0]		adc_addr;
	output 			adc_cs_n;
	output 			adc_sclk;
	input  			adc_dout;
	output 			adc_din;
	
	output [11:0] adc_data;
	output 		  adc_data_valid_go;
	
	

	

	
	wire w_adc_convert_en_go;
	wire w_adc_convert_busy;
	wire [11:0] w_adc_data;
	wire w_adc_data_convert_valid_go;
adc128s102_driver adc_driver(
	.clk(clk),
	.rst_n(rst_n),
	.adc_addr(adc_addr),
	.adc_convert_en_go(w_adc_convert_en_go),
	.adc_cs_n(adc_cs_n),
	.adc_sclk(adc_sclk),
	.adc_dout(adc_dout),
	.adc_din(adc_din),
	.adc_convert_busy(w_adc_convert_busy),
	.adc_data(w_adc_data),
	.adc_data_convert_valid_go(w_adc_data_convert_valid_go)
);
	
	

	
	
	reg [1:0]r_adc_convert_busy_sync;
	//wire w_adc_convert_busy_pedge;
	wire w_adc_convert_busy_nedge;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_adc_convert_busy_sync <= 2'd0;
		else
			r_adc_convert_busy_sync <= {r_adc_convert_busy_sync[0],w_adc_convert_busy};
	end

	//assign w_adc_convert_busy_pedge = (r_adc_convert_busy_sync == 2'b01) ? 1'b1 : 1'b0;
	assign w_adc_convert_busy_nedge = (r_adc_convert_busy_sync == 2'b10) ? 1'b1 : 1'b0; 
	
	localparam ADC_COLLECT_TIMES = 100;
	
	
	localparam S_IDLE  	= 4'b0001;
	localparam S_START 	= 4'b0010;
	localparam S_SAMPLE = 4'b0100;
	localparam S_DONE 	= 4'b1000;
	
	
	reg [3:0] r_current_state;
	reg [3:0] r_next_state;
	
	reg [$clog2(ADC_COLLECT_TIMES)-1:0] r_sample_cnt;
	
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_current_state <= S_IDLE;
		else
			r_current_state <= r_next_state;
	end

	
	always@(*) begin
		case(r_current_state)
			S_IDLE: begin
				if(key_press_valid_go == 1'b1)
					r_next_state <= S_START;
				else
					r_next_state <= S_IDLE;
			end
			S_START: begin
				if(w_adc_data_convert_valid_go == 1'b1)
					r_next_state <= S_SAMPLE;
				else
					r_next_state <= S_START;
			end
			S_SAMPLE: begin
				if(r_sample_cnt == ADC_COLLECT_TIMES)
					r_next_state = S_DONE;
				else
					r_next_state = S_SAMPLE;
			end
			S_DONE: begin
				if(w_adc_convert_busy_nedge == 1'b1)
					r_next_state <= S_IDLE;
				else
					r_next_state <= S_DONE;
			end
		default: r_next_state <= S_IDLE;
		endcase
	end
	
	

	
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_sample_cnt <= 'd0;
		else if(r_current_state == S_SAMPLE) begin
			if(w_adc_data_convert_valid_go == 1)
				r_sample_cnt <= r_sample_cnt + 1'b1;
			else
				r_sample_cnt <= r_sample_cnt;
		end
		else
			r_sample_cnt <= 'd0;
	end
	
	reg r_adc_convert_en_go;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_adc_convert_en_go <= 1'b0;
		else if(r_current_state == S_IDLE && r_next_state == S_START)
			r_adc_convert_en_go <= 1'b1;
		else if(r_current_state == S_SAMPLE && w_adc_convert_busy_nedge == 1'b1)
			r_adc_convert_en_go <= 1'b1;
		else
			r_adc_convert_en_go <= 1'b0;
	end
	assign w_adc_convert_en_go = r_adc_convert_en_go;
	
	reg r_adc_data_valid_go;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			r_adc_data_valid_go <= 'd0;
		end
		else if(r_current_state == S_SAMPLE && w_adc_data_convert_valid_go == 1 'b1)
			r_adc_data_valid_go <= 1'b1;
		else
			r_adc_data_valid_go <= 1'b0;
	end
	assign adc_data_valid_go = r_adc_data_valid_go;
	assign adc_data = w_adc_data;

	
endmodule



