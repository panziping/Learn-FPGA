module data_handle(
	clk,
	rst_n,
	adc_data,
	adc_data_valid_go,
	txd_data,
	txd_en_go,
	txd_busy
);

	input clk;
	input rst_n;
	
	input [11:0] adc_data;
	input adc_data_valid_go;

	
	
	
	
	output [7:0] txd_data;
	output 		txd_en_go;
	input 		txd_busy;
	
	
	reg [1:0] r_txd_busy_sync;
	wire w_txd_busy_nedge;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_txd_busy_sync <= 2'd0;
		else	
			r_txd_busy_sync <= {r_txd_busy_sync[0],txd_busy};
	end
	
	assign w_txd_busy_nedge = (r_txd_busy_sync == 2'b10)?1'b1 : 1'b0;
	
	
	
	wire w_fifo_empty;
	wire w_fifo_wrreq;
	wire w_fifo_rdreq;
	wire [11:0] w_fifo_data;
	FIFO FIFO1(
	.aclr(~rst_n),
	.clock(clk),
	.data(adc_data),
	.rdreq(w_fifo_rdreq),
	.wrreq(w_fifo_wrreq),
	.empty(w_fifo_empty),
	.full(),
	.q(w_fifo_data),
	.usedw());	
	
	
	assign w_fifo_wrreq = adc_data_valid_go;
	
	
	
	localparam S_IDLE = 3'b001;
	localparam S_LB   = 3'b010;
	localparam S_HB   = 3'b100;
	reg [2:0] r_current_state;
	reg [2:0] r_next_state;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_current_state <= S_IDLE;
		else
			r_current_state <= r_next_state;
	end
	
	always@(*) begin
		case(r_current_state)
			S_IDLE: begin
				if(w_fifo_empty == 1'b0 && txd_busy == 1'b0)
					r_next_state = S_LB;
				else
					r_next_state = S_IDLE;
			end
			S_LB: begin
				if(w_txd_busy_nedge==1'b1)
					r_next_state = S_HB;
				else
					r_next_state = S_LB;
			end
			S_HB: begin
				if(w_txd_busy_nedge==1'b1)
					r_next_state = S_IDLE;
				else
					r_next_state = S_HB;
			end
			default: r_next_state = S_IDLE;
		endcase
	end
	


	

	

	reg r_fifo_rdreq_go;

	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) 
			r_fifo_rdreq_go <= 1'b0;
		else if(r_current_state == S_IDLE && r_next_state == S_LB) 
			r_fifo_rdreq_go <= 1'b1;
//		else if(r_current_state == S_LB && r_next_state == S_HB) 
//			r_fifo_rdreq_go <= 1'b1;
		else 
			r_fifo_rdreq_go <= 1'b0;
	end
	assign w_fifo_rdreq = r_fifo_rdreq_go;
	
	
	reg [7:0] r_txd_data;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_txd_data <= 8'd0;
		else if(r_current_state == S_LB)
			r_txd_data <= w_fifo_data[7:0];
		else if(r_current_state == S_HB)
			r_txd_data <= {4'd0,w_fifo_data[11:8]};
		else	
			r_txd_data <= r_txd_data;
	
	end
	
	
	assign txd_data = r_txd_data;
	reg r_txd_en_go_sync1;
	reg r_txd_en_go_sync0;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_txd_en_go_sync0 <= 1'b0;
		else if(r_current_state == S_IDLE && r_next_state == S_LB) 
			r_txd_en_go_sync0 <= 1'b1;
		else if(r_current_state == S_LB && r_next_state == S_HB) 
			r_txd_en_go_sync0 <= 1'b1;
		else
			r_txd_en_go_sync0 <= 1'b0;
	end
	
	
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_txd_en_go_sync1 <= 1'b0;
		else
			r_txd_en_go_sync1 <= r_txd_en_go_sync0;
	end
	assign txd_en_go = r_txd_en_go_sync1;




	
endmodule
