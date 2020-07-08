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

reg [31:0] address;
reg [7:0] data;
reg mode, clk;
wire [7:0] output_data;
wire hit1,hit2,Wait;
wire [31:0] stored_address;
wire [7:0] stored_data;


CACHE_CONTROLLER inst(
	.address(address),
	.data(data),
	.mode(mode),
	.clk(clk),
	.output_data(output_data),
	.hit1(hit1),.hit2(hit2),
	.Wait(Wait),
	.stored_address(stored_address),
	.stored_data(stored_data)
);

initial
begin
	//The block index and block offset is 0-based index
	clk = 1'b1;
	address = 32'b00000000000000000000000000000010;	//At Block-index=0, Block-offset=2
	data =    8'b10110000;	 //The data to be writen at the given address
	mode = 1'b1; //write opertion
	//Initially this block is in main-memory...
	//The block won't be copied to L1 or L2 Cache as we have implemented Write No-allocate policy
	//hence this block 0  would still be in Main memory after the write operation
	#10
	#2
	address = 32'b00000000000000000000000100000000;	//At Block-index=64, Block-offset=0
	data =    8'b10110111;	//This data does not matter here as it is read operation 
	mode = 1'b0; //read operation
	//Initially this block would be found in main-memory
	//As per the Write-back policy, it would be promoted to L2 and then to L1 after this read operation
	//Hence block 64 would be now in L1 and L2 Cache both
	#50
	#2
	address = 32'b00000000000000000000000100000001;	 //At Block-index=64, Block-offset=1
	data =    8'b10110110;	//The data to be writen at the given address
	mode = 1'b1; //Write operation
	//As the block 64 was promoted earlier to L1 Cache
	//This block would now be found in L1 Cache
	#10
	#2
	address = 32'b00000000000000000000000000000010;	 //At Block-index=0, Block-offset=2
	data =    8'b10110111;	//This data does not matter here as it is read operation  
	mode = 1'b0; //Read operation
	//This Block 0 was present in main memory
	//After this read operation , it would be promoted to L1 Cache
	//As it occupies the same line as occupied by Block 64
	//Block 64 would be evicted from L1 and would be found in L2 Cache now
	
	#30
	#2
	address = 32'b00000000000000000000000100000010;	 //At Block-index=64, Block-offset=2
	data =    8'b10111100;	 //The data to be writen at the given address
	mode = 1'b1; //Write operation
	//As Block 64 was removed from L1 Cache earlier to make space for Block 0
	//Block 64 would be now found in L2 Cache
	//As it is write operation, Block 64 would remain in L2 Cache
	#3
	#2
	address = 32'b00000000000000000000000100000000;	 //At Block-index=64, Block-offset=0
	data =    8'b11110100;	 //This data does not matter here as it is read operation 
	mode = 1'b0; //Read operation
	//Now as Block 0 has occupied the same line in L1 as that of Block 64
	//Block 64 would now replace Block 0 in L1 Cache
	//So after this operation Block 64 would be in L1 and Block 0 in L2 cache
	
	
end
always #1 clk = ~clk;
endmodule
