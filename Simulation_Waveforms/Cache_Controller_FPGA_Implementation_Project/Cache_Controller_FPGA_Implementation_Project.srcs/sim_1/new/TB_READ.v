`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.10.2019 05:13:39
// Design Name: 
// Module Name: TB_READ
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module TB_READ();

reg [10:0] address;
reg [3:0] data;
reg mode, clk;
wire [3:0] output_data;
wire hit1, hit2;
wire Wait;
wire clk2;

CACHE_CONTROLLER inst(
	.address(address),
	.data(data),
	.mode(mode),
	.clk(clk),
	.output_data(output_data),
	.hit1(hit1),
	.hit2(hit2),
	.Wait(Wait),
	.clk2(clk2)
);

initial
begin
	clk = 1'b1;
	
	address = 11'b00000001101; //Block 3, byte 1
	data =    4'b1110; 	 
	mode = 1'b1; //write	

    #50
	address = 11'b00000101110;	 //Block 11, byte 2
	data =    4'b0001;	 
	mode = 1'b0; //read	

    #50
	address = 11'b00000101110;	 //Block 11, byte 2
	data =    4'b0110;	 
	mode = 1'b1; //write	
	
    #50
	address = 11'b00000001101;	 //Block 3, byte 1
	data =    4'b0001;	 
	mode = 1'b0; //read	

    #50
	address = 11'b00000101111;	 //Block 11, byte 3
	data =    4'b1111;	 
	mode = 1'b1; //read	 
	
end

always #25 clk = ~clk;
endmodule