`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.10.2019 03:56:56
// Design Name: 
// Module Name: MAIN_MEMORY
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


module MAIN_MEMORY();

parameter no_of_main_memory_blocks=16384; //2^14 No. of lines in main memory
parameter main_memory_block_size=32;        //No. of bits in a single line = No. of blocks in a line * no. of bits in a block =1*32=32
parameter no_of_bytes_main_memory_block=4;  //No. of bytes in a single given line on main memory ...No. of blocks in a single line * no. of bytes in a block = 1*4=4
parameter byte_size=8;          //No. of bits in a byte =8
parameter main_memory_byte_size=65536; //no_of_main_memory_blocks*no_of_bytes_main_memory_block

reg [main_memory_block_size-1:0]main_memory[0:no_of_main_memory_blocks-1];
initial 
begin: initialization_main_memory
    integer i;
    for (i=0;i<no_of_main_memory_blocks;i=i+1)
    begin
        main_memory[i]=i;       //we can randomly intialize with some other value as well here
    end
end
endmodule
