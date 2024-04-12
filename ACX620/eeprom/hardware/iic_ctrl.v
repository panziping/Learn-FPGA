module iic_ctrl(
	clk,
	rst_n,
	
	iic_device_addr,
	iic_reg_addr,
	
	iic_rd_en_go,
	iic_rd_data,
	
	iic_wr_en_go,
	iic_wr_data,
	iic_rw_data_valid_go,
	iic_busy,
	iic_sclk,
	iic_sdat
);

	input 			clk;
	input 			rst_n;
	
	input  [6:0] 	iic_device_addr;
	input  [7:0] 	iic_reg_addr;
	
	input 			iic_rd_en_go;
	output [7:0] 	iic_rd_data;
	
	input 			iic_wr_en_go;
	input  [7:0] 	iic_wr_data;
	output 			iic_rw_data_valid_go;
	
	output 			iic_busy;
	output 			iic_sclk;
	inout 			iic_sdat;

	// ******************************************************************************************************************************************************************* //
	// write : *write = 0*																																																  //
	// iic one byte write : 																																												           //
	//	start + (device address & 8'b0000_0000) + (slave ack) + reg address + (slave ack) + data + (slave ack) + stop;																		  //
	// iic multiple bytes write : 																																												  	  //
	//	start + (device address & 8'b0000_0000) + (slave ack) + reg address + (slave ack) + data + (slave ack) + ... + data + (slave ack) + stop;									  //																																								              //
	// ******************************************************************************************************************************************************************* //
	// read  : *read = 1*																																											  	  				  //
	// iic one byte read : 																																												  	  			  //
	//	start + (device address & 8'b0000_0000) + (slave ack) + reg address + (slave ack) + 																										  //
	// start + (device address & 8'b0000_0001) + (slave ack) + data + (master nack) + stop; 																										  //
	// iic multiple bytes read : 																																												  	     //
	// start + (device address & 8'b0000_0000) + (slave ack) + reg address + (slave ack) + 																										  //
	// start + (device address & 8'b0000_0001) + (slave ack) + data + (master ack) + ... + data + (master nack) + stop; 																	  //
	// ******************************************************************************************************************************************************************* //

	localparam STA  = 6'b000_001;
	localparam WR   = 6'b000_010; 
	localparam RD   = 6'b000_100;
	localparam ACK  = 6'b001_000;	// master gen ack
	localparam NACK = 6'b010_000;	// master gen nack
	localparam STOP = 6'b100_000;
	
	
	localparam S_IDLE  	    = 7'b000_0001;
	localparam S_WR_REG		 = 7'b000_0010;
	localparam S_WAIT_WR_REG = 7'b000_0100;
	localparam S_WR_REG_DONE = 7'b000_1000;
 	localparam S_RD_REG 		 = 7'b001_0000;
	localparam S_WAIT_RD_REG = 7'b010_0000;
	localparam S_RD_REG_DONE = 7'b100_0000;
	
	reg r_iic_en_go;
	reg [5:0] r_iic_cmd;
	reg [7:0] r_wr_data;
	wire [7:0] w_rd_data;
	wire w_trans_done;
	wire w_slave_ack;
iic_driver iic_driver(
	.clk(clk),
	.rst_n(rst_n),
	.iic_cmd(r_iic_cmd),
	.iic_en_go(r_iic_en_go),
	.rd_data(w_rd_data),
	.wr_data(r_wr_data),
	.trans_done(w_trans_done),
	.slave_ack(w_slave_ack),
	.iic_sclk(iic_sclk),
	.iic_sdat(iic_sdat)
);

	task read_byte;
	input [5:0] ctrl_cmd;
	begin
		r_iic_en_go <= 1'b1;
		r_iic_cmd <= ctrl_cmd;
	end
	endtask
	
	task write_byte;
	input [5:0] ctrl_cmd;
	input [7:0] wr_byte_data;
	begin
		r_iic_en_go <= 1'b1;
		r_iic_cmd <= ctrl_cmd;
		r_wr_data <= wr_byte_data;
	end
	endtask
	
	reg [6:0] r_current_state;
	reg [6:0] r_next_state;
	reg [7:0] r_cnt; 
	
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n)
			r_current_state <= S_IDLE;
		else
			r_current_state <= r_next_state;
	end
	
	always@(*) begin
		case(r_current_state)
			S_IDLE: begin
				if(iic_wr_en_go == 1'b1)
					r_next_state = S_WR_REG;
				else if(iic_rd_en_go == 1'b1)
					r_next_state = S_RD_REG;
				else
					r_next_state = S_IDLE;
			end
			S_WR_REG: begin
				r_next_state = S_WAIT_WR_REG;
			end
			S_WAIT_WR_REG: begin
				if(w_trans_done == 1'b1) begin
					case(r_cnt)
						8'd0: r_next_state = (w_slave_ack == 1'd0) ? S_WR_REG : S_IDLE; // device addr
						8'd1: r_next_state = (w_slave_ack == 1'd0) ? S_WR_REG : S_IDLE; // reg addr
						8'd2: r_next_state = (w_slave_ack == 1'd0) ? S_WR_REG_DONE : S_IDLE; //wr data
						default: r_next_state = S_IDLE;
					endcase
				end
				else
					r_next_state = S_WAIT_WR_REG;
			end
			S_WR_REG_DONE: begin
				r_next_state = S_IDLE;
			end
			
			S_RD_REG: begin
				r_next_state = S_WAIT_RD_REG;
			end
			S_WAIT_RD_REG: begin
				if(w_trans_done == 1'b1) begin
					case(r_cnt)
						8'd0: r_next_state = (w_slave_ack == 1'd0) ? S_RD_REG : S_IDLE; // device addr
						8'd1: r_next_state = (w_slave_ack == 1'd0) ? S_RD_REG : S_IDLE; // reg addr
						8'd2: r_next_state = (w_slave_ack == 1'd0) ? S_RD_REG : S_IDLE; // device addr
						8'd3: r_next_state = S_RD_REG_DONE ; // rd data
						default: r_next_state = S_IDLE;
					endcase
				end
				else
					r_next_state = S_WAIT_RD_REG;
			end
			S_RD_REG_DONE: begin
				r_next_state = S_IDLE;
			end
			default: r_next_state = S_IDLE;
		endcase
	end
	
	

	reg r_rw_data_valid_go;
	reg [7:0] r_iic_rd_data;
	always@(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			r_cnt <= 8'd0;
			r_iic_cmd <= 6'd0;
			r_iic_en_go <= 1'b0;
			r_rw_data_valid_go <= 1'b0;
			r_wr_data <= 8'd0;
			r_iic_rd_data <= 8'd0;
		end
		else begin
			case(r_current_state)
				S_IDLE: begin
					r_cnt <= 8'd0;
					r_iic_cmd <= 6'd0;
					r_iic_en_go <= 1'b0;
					r_rw_data_valid_go <= 1'b0;
					r_wr_data <= 8'd0;
				end // S_IDLE
				
				S_WR_REG: begin
					case(r_cnt)
						8'd0: write_byte(STA|WR,{iic_device_addr,1'b0} | 8'b0000_0000);
						8'd1: write_byte(WR,iic_reg_addr);
						8'd2: write_byte(WR|STOP,iic_wr_data);
						default:;
					endcase
				end //S_WR_REG
				
				S_WAIT_WR_REG: begin
					r_iic_en_go <= 1'b0;
					if(w_trans_done == 1'b1)
						r_cnt <= r_cnt + 1'b1;
					else	
						r_cnt <= r_cnt;
				end // S_WAIT_WR_REG
				
				S_WR_REG_DONE: begin
					r_rw_data_valid_go <= 1'b1;
				end // S_WR_REG_DONE
				
				S_RD_REG: begin
					case(r_cnt)
						8'd0: write_byte(STA|WR,{iic_device_addr,1'b0} | 8'b0000_0000);
						8'd1: write_byte(WR,iic_reg_addr);
						8'd2: write_byte(STA|WR,{iic_device_addr,1'b0}| 8'b0000_0001);
						8'd3: read_byte(RD|NACK|STOP);
						default:;
					endcase
				end // S_RD_REG
				
				S_WAIT_RD_REG: begin
					r_iic_en_go <= 1'b0;
					if(w_trans_done == 1'b1)
						r_cnt <= r_cnt + 1'b1;
					else	
						r_cnt <= r_cnt;
				end //S_WAIT_RD_REG
				
				S_RD_REG_DONE: begin
					r_iic_rd_data <= w_rd_data;
					r_rw_data_valid_go <= 1'b1;
				end
				default: begin
					r_cnt <= 8'd0;
					r_iic_cmd <= 6'd0;
					r_iic_en_go <= 1'b0;
					r_rw_data_valid_go <= 1'b0;
					r_wr_data <= 8'd0;
					r_iic_rd_data <= 8'd0;
				end
			endcase
		end 
	end
	
	assign iic_rd_data = r_iic_rd_data;
	assign iic_rw_data_valid_go = r_rw_data_valid_go;
	
	assign iic_busy = (r_current_state != S_IDLE);



endmodule
