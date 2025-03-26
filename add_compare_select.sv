`include "param_def.sv"
`timescale 1ns / 1ps

module add_compare_select(clk, rst, en_acs,
                        i_distance,
                        o_fwd_nxt_st,
                        o_sel_node);

input clk, rst, en_acs;
input [2:0] i_distance [`MAX_TRANSITION_NUM - 1:0];

output reg [7:0] o_fwd_nxt_st [255:0];
output reg [7:0] o_sel_node;

// reg [4:0] sum00, sum10, sum01, sum11; // dai gia tri tu 0 - 16 , phai can den 5 bit
// reg [4:0] min_sum;
// reg [3:0] count;
// reg [1:0] min_node;

// always @(posedge clk or negedge rst) // use radix-4 instead 
// begin
//     if(rst == 0)
//     begin
//         count <= 3'b000;
//         sum00 <= 5'b00000;  
//         sum10 <= 5'b00000;
//         sum01 <= 5'b00000;
//         sum11 <= 5'b00000;
//         o_prv_st_00 <= 2'b00;
//         o_prv_st_01 <= 2'b00;
//         o_prv_st_10 <= 2'b00;
//         o_prv_st_11 <= 2'b00;
//         o_sel_node <= 2'b00;
//     end
//     else 
//     begin
//     if(en_a == 1)  // state should be the state of the last 2 bit, but have to compare 4 possible transition
//     begin   
//                 if(((HD1 + sum00) == (HD5 + sum01)) || ((HD1 + sum00) < (HD5 + sum01)))
//                 begin
//                     sum00 <= HD1 + sum00;
//                     o_prv_st_00 <= 2'b00; 
//                 end
//                 else
//                 begin
//                     sum00 <= HD5 + sum01; 
//                     o_prv_st_00 <= 2'b01;
//                 end
            
            
//                 if(((HD2 + sum00) == (HD6 + sum01)) || ((HD2 + sum00) < (HD6 + sum01)))
//                 begin
//                     sum10 <= HD2 + sum00;
//                     o_prv_st_10 <= 2'b00;
//                 end
//                 else
//                 begin
//                     sum10 <= HD6 + sum01;
//                     o_prv_st_10 <= 2'b01;
//                 end
            
            
            
//                 if(((HD3 + sum10) == (HD7 + sum11)) || ((HD3 + sum10) < (HD7 + sum11)))
//                 begin
//                     sum01 <= HD3 + sum10;
//                     o_prv_st_01 <= 2'b10;
//                 end
//                 else
//                 begin
//                     sum01 <= HD7 + sum11;
//                     o_prv_st_01 <= 2'b11;
//                 end
            
            
            
//                 if(((HD4 + sum10) == (HD8 + sum11)) || ((HD4 + sum10) < (HD8 + sum11)))
//                 begin
//                     sum11 <= HD4 + sum10; 
//                     o_prv_st_11 <= 2'b10;
//                 end
//                 else
//                 begin
//                     sum11 <= HD8 + sum11;
//                     o_prv_st_11 <= 2'b11;
//                 end

//         o_select_node <= min_node;
//         count <= count + 1;
//     end
//     else
//     begin
//         count <= count;
//         sum00 <= sum00;  
//         sum10 <= sum10;
//         sum01 <= sum01;
//         sum11 <= sum11;
//         o_prv_st_00 <= 2'b00;
//         o_prv_st_01 <= 2'b00;
//         o_prv_st_10 <= 2'b00;
//         o_prv_st_11 <= 2'b00;
//         o_sel_node <= 2'b00;
//     end
// end
// end


// always @ (posedge clk or negedge rst) // combinational logic
// begin
//     if(rst == 0)
//     begin 
//         min_sum = 5'b11111;
//         min_node = 2'b00;
//     end
//     else
//     begin
//     if(count == 8 || count > 8)  
//         begin 
//         if(sum00 < min_sum) // thu tu uu tien neu bang nhau: 00 > 10 > 01 > 11
//         begin
//             min_sum = sum00;
//             min_node = 2'b00;
//         end
//         else if(sum10 < min_sum) 
//         begin
//             min_sum = sum10;
//             min_node = 2'b10;
//         end
//         else if(sum01 < min_sum)
//         begin
//             min_sum = sum01;
//             min_node = 2'b01;
//         end
//         else if(sum11 < min_sum)
//         begin
//             min_sum = sum11;
//             min_node = 2'b11;
//         end
//         end
//         else
//         begin
//             min_sum = 5'b11111;
//             min_node = 2'b00;
//         end
//     end
// end

endmodule