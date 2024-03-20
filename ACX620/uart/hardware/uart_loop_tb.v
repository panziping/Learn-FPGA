`timescale 1ns/1ns
module uart_loop_tb;



`define sys_freq 50_000_000
`define clk_period (1_000_000_000 /`sys_freq)

reg clk;
reg rst_n;

initial clk = 1;
always#(`clk_period/2) clk = ~clk;

reg rx;
wire tx;
uart_loop uart_loop(
	.i_clk(clk),
	.i_rst_n(rst_n),
	.i_rx(rx),
	.o_tx(tx)
);


	localparam BAUD = 115200;
	localparam UART_DLY_BIT = 1_000_000_000 / BAUD;
	
//`define even 
//`define odd
`define none
`ifdef even
    integer i;
    task Txd_Byte_EVEN;                     //baud = 9600,Pority = EVEN
    input [7:0] txd_data;
    begin
        rx <= 1'b0;
        #(UART_DLY_BIT);
        for (i = 0;i < 8;i = i + 1) 
        begin
            rx <= txd_data[i];
            #(UART_DLY_BIT);   
        end
        rx <= ^txd_data;
        #(UART_DLY_BIT);
        rx <= 1'b1;
        #(UART_DLY_BIT);
    end
    endtask
`endif

`ifdef odd
    integer i;
    task Txd_Byte_ODD;                     //baud = 9600,Pority = EVEN
    input [7:0] txd_data;
    begin
        rx <= 1'b0;
        #(UART_DLY_BIT);
        for (i = 0;i < 8;i = i + 1) 
        begin
            rx <= txd_data[i];
            #(UART_DLY_BIT);   
        end
        rx <= ~^txd_data;
        #(UART_DLY_BIT);
        rx <= 1'b1;
        #(UART_DLY_BIT);
    end
    endtask
`endif

`ifdef none 
    integer i;
    task Txd_Byte_NONE;                     //baud = 9600,Pority = EVEN
    input [7:0] txd_data;
    begin
        rx <= 1'b0;
        #(UART_DLY_BIT);
        for (i = 0;i < 8;i = i + 1) 
        begin
            rx <= txd_data[i];
            #(UART_DLY_BIT);   
        end
        rx <= 1'b1;
        #(UART_DLY_BIT);
    end
    endtask
`endif





	initial begin
	rst_n = 0;
	rx = 1'b0;
	#200;
	rst_n = 1;
	rx = 1'b1;
	#200;
	Txd_Byte_NONE(8'h28);
	Txd_Byte_NONE(8'h73);
	Txd_Byte_NONE(8'h55);
	Txd_Byte_NONE(8'h43);
	
	#10000;
	$stop;
	end













endmodule 

