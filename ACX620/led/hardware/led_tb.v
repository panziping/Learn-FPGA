`timescale 1ns/1ns

module led_tb;





`define sys_freq 50_000_000
`define clk_period (1_000_000_000 /`sys_freq)

reg clk;
reg rst_n;

initial clk = 1;
always#(`clk_period/2) clk = ~clk;

wire [3:0]led;

led led0(
	.clk(clk),
	.rst_n(rst_n),
	.key(),
	.led(led)
);




initial begin
rst_n = 0;
#190;
rst_n = 1;



#2000;
$stop;
end









endmodule

