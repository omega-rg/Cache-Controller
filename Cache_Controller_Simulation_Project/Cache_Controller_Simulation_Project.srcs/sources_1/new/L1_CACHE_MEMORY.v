`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.10.2019 02:48:05
// Design Name: 
// Module Name: L1_CACHE_MEMORY
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


module L1_CACHE_MEMORY();
parameter no_of_l1_blocks=64;        //No. of lines in L1 Cache
parameter no_of_bytes_l1_block=4;     //No. of bytes in a single block
parameter l1_block_bit_size=32;         //size of a L1 Cache block =No. of bytes in a block * byte size
parameter byte_size=8;                  //No. of bits in a byte
parameter no_of_address_bits=32;        //the bits in address
parameter no_of_l1_index_bits=6;        //the no. of bits required for indexing as 2^6=64
parameter no_of_blkoffset_bits=2;       //as there are 4 bytes in a block... to index the bytes in a block
parameter no_of_l1_tag_bits=24;         //No. of bits in tag= No. of address bits - No. of index bits - No. of offset bits=32-6-2=24

reg [l1_block_bit_size-1:0]l1_cache_memory[0:no_of_l1_blocks-1];    //An array of blocks for L1 Cache memory where each element contains No. of l1_block_bit_size bits
reg [no_of_l1_tag_bits-1:0]l1_tag_array[0:no_of_l1_blocks-1];  //Tag array for L1 Cache memory where each element contains no_of_tag_bits bits
reg l1_valid[0:no_of_l1_blocks-1];      //The valid array for L1 Cache containing 1 if it is valid or 0 if invalid
                                        //valid means if there is some block stored at some location in L1 Cache...initially as Cache is empty...all postions are invalid

initial 
begin: initialization_l1           
    integer i;
    for  (i=0;i<no_of_l1_blocks;i=i+1)
    begin
        l1_valid[i]=1'b0;   //initially as the cache is empty...all the locations on the Cache are invalid
        l1_tag_array[i]=0;  //set tag to 0...we can set tag to some other random value as well
    end
end
endmodule
