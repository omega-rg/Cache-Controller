`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.10.2019 04:10:03
// Design Name: 
// Module Name: CACHE_CONTROLLER
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

/*******************************************************************
While the Stimuation code has been well-commented
Here we explain the parameters which were reduced/changed for implementing the project on an FPGA
Also other code blocks such as slow clock, 7-segment display are also described
The workflow for the code has been well commented and explained in stimulation code and readme
*******************************************************************/

module CACHE_CONTROLLER(address,clk,data,mode,output_data,hit1, hit2,Wait, clk2,Anode_Activate,seven_seg_out);

/********************************/
parameter no_of_address_bits=11;  
parameter no_of_blkoffset_bits=2;
parameter byte_size=4;          //one block is of 4 bits
/********************************/
parameter no_of_l2_ways=4;      //No. of ways in a set... here 4 as it is 4-way set-associative
parameter no_of_l2_ways_bits=2;     //No. of bits to represent ways, 2 bits are sufficient to represent 4 values
parameter no_of_l2_blocks=16;       //No. of lines in L2 Cache... each line is a set of 4 blocks here
parameter no_of_bytes_l2_block=16;       //No. of bytes in a L2 Cache line= 4* bytes in a block = 4*4=16
parameter l2_block_bit_size=64;          // No. of bits in a L2 Cache line = No.of bytes in a line * byte_size=16*4=64
parameter no_of_l2_index_bits=4;        // 2^4=16 = No. of L2 block lines.....So 4 bits are used here to get the no. of line on L2 Cache
parameter no_of_l2_tag_bits=5;          //No. of tag bits= Address_bits - index_bits- Block_offset = 11 -4 -2 =5
/********************************/
parameter no_of_l1_blocks=8;        // No. of lines in L1 Cache... as one line contains 1 block...it is equal to no. of blocks
parameter no_of_bytes_l1_block=4;       //Each Block has 4 bytes
parameter l1_block_bit_size=16;         //Size of each line = No. of blocks in a line * No. of bytes in a block * Byte_size = 1*4*4=16
parameter no_of_l1_index_bits=3;        //as 2^3=8... So 3 index bits are sufficient to locate a line on L1 Cache
parameter no_of_l1_tag_bits=6;          //No. of tag bits= Address_bits - index_bits- Block_offset = 11 -3 -2 =6
/********************************/
parameter no_of_main_memory_blocks=32; //2^5 //No. of lines in main_memory... as each line contains a single block... No. of lines=No. of blocks here
parameter main_memory_block_size=16;    //Each line has one block... which in turn has 4 bytes and each byte is of 4 bits=1*4*4=16
parameter no_of_bytes_main_memory_block=4;   //Each line has one block and each block has 4 bytes
parameter main_memory_byte_size=128;        //No. of bytes in main memory=No. of lines* No. of bytes in each line=32*4=128
/*************************************/
parameter l1_latency=1;         //It represents the delay in fetching a data from L1 Cache...1 here represents that it would be availabe within that clock cycle only
parameter l2_latency=2;         //It represents the delay in fetching/searching_time in L2 Cache....It will lead to fetching data after passing of 2 clock cycles
parameter main_memory_latency=5;        //It represents the delay in fetching/searching_times in main_memory.. It would lead to fetching data from main memory after passing of 4 clock cycles
/*************************************/

/*************************************/

input [no_of_address_bits-1:0]address;
input clk;
input [byte_size-1:0]data;
input mode;                 //mode=0 : Read     mode=1 : Write
output reg[byte_size-1:0]output_data;
output reg hit1, hit2;              
output reg Wait;            //Wait=1 is a signal for the processor...that the cache controller is currently working on some read/write operation and processor needs to wait before the controller accepts next read/write operation
output reg [3:0]Anode_Activate;
output reg [6:0]seven_seg_out;        
/********************************/

reg [no_of_address_bits-1:0]address_valid;          //For Checking whether there is a stored block at some line in Cache or not
reg [no_of_address_bits-no_of_blkoffset_bits-1:0]main_memory_blk_id;        //Represents the line number to which the address belongs on main memory
reg [no_of_l1_tag_bits-1:0]l1_tag;          //The tag for lines on L1 Cache
reg [no_of_l1_index_bits-1:0]l1_index;      //Represents the index of the line to which the address belongs on L1 Cache
reg [no_of_l2_tag_bits-1:0]l2_tag;      //Represents the index of the line to which the address belongs on L1 Cache
reg [no_of_l2_index_bits-1:0]l2_index;          //The index of the line to which the address belongs on L2 Cache
reg [no_of_blkoffset_bits-1:0]offset;           //Offset gives the index of byte within a block

/********************************/
integer i;                  //integer variables for working in for-loops
integer j;
/********************************/
//the variable given below in various search operation in L1 , L2 and main memory
//specially when we need to evict some block from L1 or L2 Cache
//then it needs to be searched in the L2 or in main memory to update its value there
integer l2_check;
integer l2_check2;
integer l2_checka;
integer l2_check2a;
integer l2_mm_check;
integer l2_mm_check2;
integer l2_mm_iterator;
integer l2_iterator;

integer l1_l2_check;
integer l1_l2_check2;
integer l1_l2_checka;
integer l1_l2_check2a;
integer l1_l2_checkb;
integer l1_l2_check2b;
/********************************/
//Many times we need to evict an block from L1 or L2 Cache..
//so its value needs to be updated in L2 or main Memory
//these are the variable used for evicting operations
//for finding the block present in L1 or L2..its location in L2 or main memory
reg [no_of_l2_ways_bits-1:0]lru_value;
reg [no_of_l2_ways_bits-1:0]lru_value_dummy;

reg [no_of_l2_ways_bits-1:0]lru_value2;
reg [no_of_l2_ways_bits-1:0]lru_value_dummy2;

reg [no_of_l1_tag_bits-1:0]l1_evict_tag;
reg [no_of_l2_tag_bits-1:0]l1_to_l2_tag;
reg [no_of_l2_index_bits-1:0]l1_to_l2_index;

reg [no_of_l1_tag_bits-1:0]l1_evict_tag2;
reg [no_of_l2_tag_bits-1:0]l1_to_l2_tag2;
reg [no_of_l2_index_bits-1:0]l1_to_l2_index2;

reg [no_of_l1_tag_bits-1:0]l1_evict_tag3;
reg [no_of_l2_tag_bits-1:0]l1_to_l2_tag3;
reg [no_of_l2_index_bits-1:0]l1_to_l2_index3;

reg [no_of_l2_tag_bits-1:0]l2_evict_tag;
/********************************/
//to store whether the block to be evicted was found in L2 or main memory or not
reg l1_to_l2_search;
reg l1_to_l2_search2;
reg l1_to_l2_search3;
/*********************************/
//Variables for implementing slow clock for implementation
output reg clk2;        //The slow clock signal
reg [31:0] counter=0;       //A counter variable to implement slow clock
/********************************/
//for the delay counters to implement delays in the L2 Cache
reg [1:0]l2_delay_counter=0;
reg [3:0]main_memory_delay_counter=0;
reg dummy_hit;
reg is_L2_delay=0;
/********************************/
//for the delay counters to implement delays in the main memory
reg [1:0]l2_delay_counter_w=0;
reg [3:0]main_memory_delay_counter_w=0;
reg dummy_hit_w=0;
reg is_L2_delay_w=0;
/************************************/
reg [no_of_address_bits-1:0] stored_address;            //for the delay counters to implement delays in the main memorys
reg stored_mode;                //for the delay counters to implement delays in the main memory
reg [byte_size-1:0]stored_data;         //for the delay counters to implement delays in the main memory
reg Ccount=0;               //for the delay counters to implement delays in the main memory

//MAIN_MEMORY main_memory_instance();
reg [main_memory_block_size-1:0]main_memory[0:no_of_main_memory_blocks-1];
initial 
begin: initialization_main_memory
    integer i;
    for (i=0;i<no_of_main_memory_blocks;i=i+1)
    begin
        main_memory[i]=i;
    end
end

//L1_CACHE_MEMORY l1_cache_memory_instance();
reg [l1_block_bit_size-1:0]l1_cache_memory[0:no_of_l1_blocks-1];
reg [no_of_l1_tag_bits-1:0]l1_tag_array[0:no_of_l1_blocks-1];
reg l1_valid[0:no_of_l1_blocks-1];

initial 
begin: initialization_l1
    integer i;
    for  (i=0;i<no_of_l1_blocks;i=i+1)
    begin
        l1_valid[i]=1'b0;
        l1_tag_array[i]=0;
    end
end

//L2_CACHE_MEMORY l2_cache_memory_instance();
reg [l2_block_bit_size-1:0]l2_cache_memory[0:no_of_l2_blocks-1];
reg [(no_of_l2_tag_bits*no_of_l2_ways)-1:0]l2_tag_array[0:no_of_l2_blocks-1];
reg [no_of_l2_ways-1:0]l2_valid[0:no_of_l2_blocks-1];
reg [no_of_l2_ways*no_of_l2_ways_bits-1:0]lru[0:no_of_l2_blocks-1];

initial 
begin: initialization
    integer i;
    for  (i=0;i<no_of_l2_blocks;i=i+1)
    begin
        l2_valid[i]=0;
        l2_tag_array[i]=0;
        lru[i]=8'b11100100;
    end
end

reg [15:0]seg_display_custom_no;            //the cutom number formed by concatenating the 4 BCD numbers for the 4 LEDs
reg [3:0] digit_bcd;                        //The BCD for a digit
reg [1:0] anode_no;                         //THe high or low for a 7 segment display
reg [19:0] refresh;                         //The counter for activating the four 7 segment displays one by one


reg [3:0] a1;           //BCD for first 7 segment display           //the leftmost is considered first here
reg [3:0] a2;           //BCD for second 7 segment display
reg [3:0] a3;           //BCD for third 7 segment display
reg [3:0] a4;           //BCD for fourth 7 segment display

//always block for implementing slow clock and BCD display
always @(posedge clk)
begin
    //////////////////////////////////////////////////////
    a1=(output_data>9)?1:0;             //THe first digit of BCD for output data would be 1 if output data > 9 or 0 otherwise
    a2=output_data%10;                  //THe second digit of BCD for output data would be its modulo with 10
    a3=(data>9)?1:0;                     //THe first digit of BCD for input data would be 1 if output data > 9 or 0 otherwise
    a4=data%10;                              //THe second digit of BCD for input data would be its modulo with 10
    seg_display_custom_no={a1,a2,a3,a4};       //Concatenating a1, a2, a3, a4 to get the concatenated BCD number for all four 7 segment displays
    refresh <= refresh + 1;                     //increment the refresh counter in every clock
    anode_no = refresh[19:18];                  //Take the 2 most significant bits in refresh counter to decide which 7 segment display would be active at that time
    case(anode_no)
    //Note that the 7 segment displays are active low here
    2'b00: begin
        Anode_Activate = 4'b0111; 
        // LED 1 is active and rest three LEDs inactive
        digit_bcd = seg_display_custom_no[15:12];
        //the 4 digits of the concated number for the specific 7 segment display
          end
    2'b01: begin
        Anode_Activate = 4'b1011; 
        // LED 2 is active and rest three LEDs inactive
        digit_bcd = seg_display_custom_no[11:8];
        //the 4 digits of the concated number for the specific 7 segment display
          end
    2'b10: begin
        Anode_Activate = 4'b1101; 
        // LED 3 is active and rest three LEDs inactive
        digit_bcd = seg_display_custom_no[7:4];
        //the 4 digits of the concated number for the specific 7 segment display
            end
    2'b11: begin
        Anode_Activate = 4'b1110; 
        // LED 4 is active and rest three LEDs inactive
        digit_bcd = seg_display_custom_no[3:0];
        //the 4 digits of the concated number for the specific 7 segment display
           end
    endcase
    //code for getting the 7 segment binary according to the 4 bit BCD
    case(digit_bcd)
    4'b0000: seven_seg_out=7'b1000000; //0
    4'b0001: seven_seg_out=7'b1111001; //1  
    4'b0010: seven_seg_out=7'b0100100; //2
    4'b0011: seven_seg_out=7'b0110000; //3
    4'b0100: seven_seg_out=7'b0011001; //4
    4'b0101: seven_seg_out=7'b0010010; //5
    4'b0110: seven_seg_out=7'b0000010; //6
    4'b0111: seven_seg_out=7'b1111000; //7
    4'b1000: seven_seg_out=7'b0000000; //8
    4'b1001: seven_seg_out=7'b0010000; //9
    endcase
    /////////////////////////////////////////////////////
    //Slow clock for the FPGA
    counter<=counter+1;     //increment the counter in every clk
    if (counter==150000000)
    begin
        clk2<=~clk2;        //toggle the slow clock and reset the counter...once the counter reaches this value
        counter<=0;         //reset the slow clock counter
    end
end

always @(posedge clk2)
begin
    if(Ccount==0 || Wait==0)
        begin
            stored_address=address;
            Ccount=1;
            stored_mode=mode;
            stored_data=data;
        end
    main_memory_blk_id=(stored_address>>no_of_blkoffset_bits)%no_of_main_memory_blocks;
    l2_index=(main_memory_blk_id)%no_of_l2_blocks;
    l2_tag=main_memory_blk_id>>no_of_l2_index_bits;
    l1_index=(main_memory_blk_id)%no_of_l1_blocks;
    l1_tag=main_memory_blk_id>>no_of_l1_index_bits;
    offset=stored_address%no_of_bytes_main_memory_block;
    if (stored_mode==0)
    begin
        $display("Check Started");
        /************************************************************************************************************************************/
        if (l1_valid[l1_index]&&l1_tag_array[l1_index]==l1_tag)
        begin
            //$display("Found in L1 Cache");
            output_data=l1_cache_memory[l1_index][((offset+1)*byte_size-1)-:byte_size];
            hit1=1;
            hit2=0;
            Wait=0;
        end
        /************************************************************************************************************************************/
        else
        begin
            /************************************************************************************************************************************/
            $display("Not Found in L1 Cache");
            hit1=0;
            if (l2_delay_counter<l2_latency && is_L2_delay==0)
            begin
                hit2=0;
                hit1=0;
                l2_delay_counter = l2_delay_counter+1;
                Wait=1;
            end
            else
            begin //c not found in l1
                l2_delay_counter=0;
                hit1=0;
                hit2=1;
                Wait=0;
                dummy_hit=0;
                for (l2_check=0;l2_check<no_of_l2_ways;l2_check=l2_check+1)
                begin
                    if (l2_valid[l2_index][l2_check]&&l2_tag_array[l2_index][((l2_check+1)*no_of_l2_tag_bits-1)-:no_of_l2_tag_bits]==l2_tag)
                    begin
                        dummy_hit=1;
                        l2_check2=l2_check;
                    end
                end
                if (dummy_hit==1) $display("Found in L2 Cache");
                else $display("Not Found in L2 Cache");
                if (dummy_hit==1)
                begin
                    lru_value2=lru[l2_index][((l2_check2+1)*no_of_l2_ways_bits-1)-:no_of_l2_ways_bits];
                    for (l2_iterator=0;l2_iterator<no_of_l2_ways;l2_iterator=l2_iterator+1)
                    begin
                       lru_value_dummy2=lru[l2_index][((l2_iterator+1)*no_of_l2_ways_bits-1)-:no_of_l2_ways_bits];
                       if (lru_value_dummy2>lru_value2)
                       begin
                           lru[l2_index][((l2_iterator+1)*no_of_l2_ways_bits-1)-:no_of_l2_ways_bits]=lru_value_dummy2-1;
                       end
                    end
                    lru[l2_index][((l2_check2+1)*no_of_l2_ways_bits-1)-:no_of_l2_ways_bits]=no_of_l2_ways-1;
                    
                    if (l1_valid[l1_index]==0)
                    begin
                        l1_cache_memory[l1_index]=l2_cache_memory[l2_index][((l2_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size];
                        l1_valid[l1_index]=1;
                        l1_tag_array[l1_index]=l1_tag;
                        output_data=l1_cache_memory[l1_index][((offset+1)*byte_size-1)-:byte_size];
                        dummy_hit=1;
                    end
                    else
                    begin
                        l1_evict_tag2=l1_tag_array[l1_index];
                        l1_to_l2_tag2=l1_evict_tag2>>(no_of_l1_tag_bits-no_of_l2_tag_bits);
                        l1_to_l2_index2={l1_evict_tag2[no_of_l1_tag_bits-no_of_l2_tag_bits-1:0],l1_index};
                        l1_to_l2_search2=0;
                        for (l1_l2_checka=0;l1_l2_checka<no_of_l2_ways;l1_l2_checka=l1_l2_checka+1)
                        begin
                            if (l2_valid[l1_to_l2_index2][l1_l2_checka]&&l2_tag_array[l1_to_l2_index2][((l1_l2_checka+1)*no_of_l2_tag_bits-1)-:no_of_l2_tag_bits]==l1_to_l2_tag2)
                            begin
                                l1_to_l2_search2=1;
                                l1_l2_check2a=l1_l2_checka;
                            end
                        end
                        if (l1_to_l2_search2==1)
                        begin
                            //$display("found l1 eviction in l2");
                            l2_cache_memory[l1_to_l2_index2][((l1_l2_check2a+1)*l1_block_bit_size-1)-:l1_block_bit_size]=l1_cache_memory[l1_index];
                            //$display("%B",l2_cache_memory[l1_to_l2_index][((l1_l2_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size]);
                            l1_cache_memory[l1_index]=l2_cache_memory[l2_index][((l2_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size];
                            //$display("%B",l1_cache_memory[l1_index]);
                            l1_valid[l1_index]=1;
                            l1_tag_array[l1_index]=l1_tag;
                            //$display("%B",l1_tag_array[l1_index]);
                            output_data=l1_cache_memory[l1_index][((offset+1)*byte_size-1)-:byte_size];
                            dummy_hit=1;
                        end
                        else
                        begin
                            main_memory[{l1_evict_tag2,l1_index}]=l1_cache_memory[l1_index];
                            l1_cache_memory[l1_index]=l2_cache_memory[l2_index][((l2_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size];
                            //$display("%B",l1_cache_memory[l1_index]);
                            l1_valid[l1_index]=1;
                            l1_tag_array[l1_index]=l1_tag;
                            //$display("%B",l1_tag_array[l1_index]);
                            output_data=l1_cache_memory[l1_index][((offset+1)*byte_size-1)-:byte_size];
                            dummy_hit=1;
                        end
                    end
                end
                /************************************************************************************************************************************/
                else
                begin //a not found in l2
                    hit1=0;
                    hit2=0;
                    Wait=1;
                    /************************************************************************************************************************************/
                    $display("Not found in L2 cache, Extracting from main memory");
                    
                    if (main_memory_delay_counter<main_memory_latency)
                    begin
                        hit1=0;
                        hit2=0;
                        main_memory_delay_counter = main_memory_delay_counter+1;
                        Wait=1;
                        is_L2_delay=1;
                    end
                    else
                    begin //d
                        main_memory_delay_counter=0;
                        is_L2_delay=0;
                        hit1=0;
                        hit2=0;
                        Wait=0;
                        l2_delay_counter=0;
                        main_memory_delay_counter=0;
                        for (l2_mm_check=0;l2_mm_check<no_of_l2_ways;l2_mm_check=l2_mm_check+1)
                        begin
                            if (lru[l2_index][((l2_mm_check+1)*no_of_l2_ways_bits-1)-:no_of_l2_ways_bits]==0)
                            begin
                                l2_mm_check2=l2_mm_check;
                            end
                        end
                        $display("%D",l2_mm_check2);
                        lru_value=lru[l2_index][((l2_mm_check2+1)*no_of_l2_ways_bits-1)-:no_of_l2_ways_bits];
                        //$display("%D",lru_value);
                        for (l2_mm_iterator=0;l2_mm_iterator<no_of_l2_ways;l2_mm_iterator=l2_mm_iterator+1)
                        begin
                            //$display("Initial");
                            lru_value_dummy=lru[l2_index][((l2_mm_iterator+1)*no_of_l2_ways_bits-1)-:no_of_l2_ways_bits];
                            //$display("%D",lru_value_dummy);
                           if ((lru[l2_index][((l2_mm_iterator+1)*no_of_l2_ways_bits-1)-:no_of_l2_ways_bits])>lru_value)
                           begin
                               //$display("bigger");
                               lru[l2_index][((l2_mm_iterator+1)*no_of_l2_ways_bits-1)-:no_of_l2_ways_bits]=lru_value_dummy-1;
                               lru_value_dummy=lru[l2_index][((l2_mm_iterator+1)*no_of_l2_ways_bits-1)-:no_of_l2_ways_bits];
                               //$display("%D",lru_value_dummy);
                           end
                        end
                        lru[l2_index][((l2_mm_check2+1)*no_of_l2_ways_bits-1)-:no_of_l2_ways_bits]=(no_of_l2_ways-1);
                        $display("%D",lru[l2_index]);
                        
                        if (l2_valid[l2_index][l2_mm_check2]==0)
                        begin
                            $display("Initially not present in l2");
                            l2_cache_memory[l2_index][((l2_mm_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size]=main_memory[main_memory_blk_id];
                            $display("%B",l2_cache_memory[l2_index][((l2_mm_check2+1)*byte_size-1)-:byte_size]);
                            l2_valid[l2_index][l2_mm_check2]=1;
                            $display("%B",l2_valid[l2_index][l2_mm_check2]);
                            l2_tag_array[l2_index][((l2_mm_check2+1)*no_of_l2_tag_bits-1)-:no_of_l2_tag_bits]=l2_tag;
                            $display("%B",l2_tag_array[l2_index][((l2_mm_check2+1)*no_of_l2_tag_bits-1)-:no_of_l2_tag_bits]);
                            ///
                            if (l1_valid[l1_index]==0)
                            begin
                                $display("Initially not present in l1");
                                l1_cache_memory[l1_index]=main_memory[main_memory_blk_id];
                                $display("%B",l1_cache_memory[l1_index]);
                                l1_valid[l1_index]=1;
                                $display("%B",l1_valid[l1_index]);
                                l1_tag_array[l1_index]=l1_tag;
                                $display("%B",l1_tag_array[l1_index]);
                                output_data=l1_cache_memory[l1_index][((offset+1)*byte_size-1)-:byte_size];
                                dummy_hit=0; 
                            end
                            else
                            begin
                                $display("Initially present in l1");
                                l1_evict_tag=l1_tag_array[l1_index];
                                $display("%B",l1_evict_tag);
                                l1_to_l2_tag=l1_evict_tag>>(no_of_l1_tag_bits-no_of_l2_tag_bits);
                                $display("%B",l1_to_l2_tag);
                                l1_to_l2_index={l1_evict_tag[no_of_l1_tag_bits-no_of_l2_tag_bits-1:0],l1_index};
                                $display("%B",l1_to_l2_index);
                                l1_to_l2_search=0;
                                for (l1_l2_check=0;l1_l2_check<no_of_l2_ways;l1_l2_check=l1_l2_check+1)
                                begin
                                    if (l2_valid[l1_to_l2_index][l1_l2_check]&&l2_tag_array[l1_to_l2_index][((l1_l2_check+1)*no_of_l2_tag_bits-1)-:no_of_l2_tag_bits]==l1_to_l2_tag)
                                    begin
                                        l1_to_l2_search=1;
                                        l1_l2_check2=l1_l2_check;
                                    end
                                end
                                if (l1_to_l2_search==1)
                                begin
                                    $display("found l1 eviction in l2");
                                    l2_cache_memory[l1_to_l2_index][((l1_l2_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size]=l1_cache_memory[l1_index];
                                    $display("%B",l2_cache_memory[l1_to_l2_index][((l1_l2_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size]);
                                    l1_cache_memory[l1_index]=l2_cache_memory[l2_index][((l2_mm_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size];
                                    $display("%B",l1_cache_memory[l1_index]);
                                    l1_valid[l1_index]=1;
                                    l1_tag_array[l1_index]=l1_tag;
                                    $display("%B",l1_tag_array[l1_index]);
                                    output_data=l1_cache_memory[l1_index][((offset+1)*byte_size-1)-:byte_size];
                                    dummy_hit=0;
                                end
                                else
                                begin
                                    main_memory[{l1_evict_tag,l1_index}]=l1_cache_memory[l1_index];
                                    l1_cache_memory[l1_index]=l2_cache_memory[l2_index][((l2_mm_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size];
                                    $display("%B",l1_cache_memory[l1_index]);
                                    l1_valid[l1_index]=1;
                                    l1_tag_array[l1_index]=l1_tag;
                                    $display("%B",l1_tag_array[l1_index]);
                                    output_data=l1_cache_memory[l1_index][((offset+1)*byte_size-1)-:byte_size];
                                    dummy_hit=0;
                                end
                            end
                        end
                        /************************************************************************************************************************************/
                        else
                        begin
                            /************************************************************************************************************************************/
                            $display("Initially valid data present in l2");
                            l2_evict_tag=l2_tag_array[l2_index][((l2_mm_check2+1)*no_of_l2_tag_bits-1)-:no_of_l2_tag_bits];
                            main_memory[{l2_evict_tag,l2_index}]=l2_cache_memory[l2_index][((l2_mm_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size];
                            
                            l2_cache_memory[l2_index][((l2_mm_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size]=main_memory[main_memory_blk_id];
                            l2_valid[l2_index][l2_mm_check2]=1;
                            l2_tag_array[l2_index][((l2_mm_check2+1)*no_of_l2_tag_bits-1)-:no_of_l2_tag_bits]=l2_tag;
                            /************************************************************************************************************************************/
                            
                            if (l1_valid[l1_index]==0)
                            begin
                                l1_cache_memory[l1_index]=l2_cache_memory[l2_index][((l2_mm_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size];
                                l1_valid[l1_index]=1;
                                l1_tag_array[l1_index]=l1_tag;
                                output_data=l1_cache_memory[l1_index][((offset+1)*byte_size-1)-:byte_size];
                                dummy_hit=0;
                            end
                            else
                            begin
                                l1_evict_tag3=l1_tag_array[l1_index];
                                l1_to_l2_tag3=l1_evict_tag3>>(no_of_l1_tag_bits-no_of_l2_tag_bits);
                                l1_to_l2_index3={l1_evict_tag3[no_of_l1_tag_bits-no_of_l2_tag_bits-1:0],l1_index};
                                l1_to_l2_search3=0;
                                for (l1_l2_checkb=0;l1_l2_checkb<no_of_l2_ways;l1_l2_checkb=l1_l2_checkb+1)
                                begin
                                    if (l2_valid[l1_to_l2_index3][l1_l2_checkb]&&l2_tag_array[l1_to_l2_index3][((l1_l2_checkb+1)*no_of_l2_tag_bits-1)-:no_of_l2_tag_bits]==l1_to_l2_tag3)
                                    begin
                                        l1_to_l2_search3=1;
                                        l1_l2_check2b=l1_l2_checkb;
                                    end
                                end
                                if (l1_to_l2_search3==1)
                                begin
                                    //$display("found l1 eviction in l2");
                                    l2_cache_memory[l1_to_l2_index3][((l1_l2_check2b+1)*l1_block_bit_size-1)-:l1_block_bit_size]=l1_cache_memory[l1_index];
                                    //$display("%B",l2_cache_memory[l1_to_l2_index][((l1_l2_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size]);
                                    l1_cache_memory[l1_index]=l2_cache_memory[l2_index][((l2_mm_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size];
                                    //$display("%B",l1_cache_memory[l1_index]);
                                    l1_valid[l1_index]=1;
                                    l1_tag_array[l1_index]=l1_tag;
                                    //$display("%B",l1_tag_array[l1_index]);
                                    output_data=l1_cache_memory[l1_index][((offset+1)*byte_size-1)-:byte_size];
                                    dummy_hit=0;
                                end
                                else
                                begin
                                    main_memory[{l1_evict_tag3,l1_index}]=l1_cache_memory[l1_index];
                                    l1_cache_memory[l1_index]=l2_cache_memory[l2_index][((l2_mm_check2+1)*l1_block_bit_size-1)-:l1_block_bit_size];
                                    //$display("%B",l1_cache_memory[l1_index]);
                                    l1_valid[l1_index]=1;
                                    l1_tag_array[l1_index]=l1_tag;
                                    //$display("%B",l1_tag_array[l1_index]);
                                    output_data=l1_cache_memory[l1_index][((offset+1)*byte_size-1)-:byte_size];
                                    dummy_hit=0;
                                end
                            end
                        end
                    end    
                end //a.
            end //c.      
        end
    end
    else
    begin
        output_data=0;
        if (l1_valid[l1_index]&& l1_tag_array[l1_index]==l1_tag)
        begin
            //$display("Found in L1 Cache");
            l1_cache_memory[l1_index][((offset+1)*byte_size-1)-:byte_size]=stored_data;
            Wait=0;
            hit1=1;
            hit2=0;
        end
        else
        begin  /*else not found in L1 starts here*/
            if((l2_delay_counter_w < l2_latency) && is_L2_delay_w==0)
            begin 
                l2_delay_counter_w=l2_delay_counter_w+1;
                hit1=0;
                hit2=0;
                Wait=1;
            end
            else
            begin /*searching in L2 and main memory starts here */
                l2_delay_counter_w=0;
                dummy_hit_w=0;
                hit1=0;
                hit2=0;
                for (l2_checka=0;l2_checka<no_of_l2_ways;l2_checka=l2_checka+1)
                begin
                    if (l2_valid[l2_index][l2_checka]&&l2_tag_array[l2_index][((l2_checka+1)*no_of_l2_tag_bits-1)-:no_of_l2_tag_bits]==l2_tag)
                    begin
                        dummy_hit_w=1;
                        hit2=1;
                        hit1=0;
                        Wait=0;
                        l2_cache_memory[l2_index][(l2_checka*l1_block_bit_size+(offset+1)*byte_size-1)-:byte_size]=stored_data;
                    end
                end
                if (dummy_hit_w==0) 
                begin
                    hit1=0;
                    hit2=0;
                    if(main_memory_delay_counter_w < main_memory_latency)
                    begin
                        main_memory_delay_counter_w=main_memory_delay_counter_w+1;
                        hit1=0;
                        hit2=0;
                        Wait=1;
                        is_L2_delay_w=1;
                    end
                    else
                    begin
                        main_memory_delay_counter_w=0;
                        hit1=0;
                        hit2=0;
                        Wait=0;
                        is_L2_delay_w=0;
                        main_memory[main_memory_blk_id][((offset+1)*byte_size-1)-:byte_size]=stored_data;
                    end
                end
            end /*searching in L2 and Main ends here */
        end    /*else not found in L1 ends here*/
    end
end
endmodule
