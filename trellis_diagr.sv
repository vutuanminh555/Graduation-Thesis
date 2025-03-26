`include "param_def.sv"
`timescale 1ns / 1ps

module trellis_diagr(  clk, rst, en_td,
                i_fwd_nxt_st,
                o_bck_prv_st);

input clk, rst, en_td;
input [7:0] i_fwd_nxt_st [255:0];

output reg [`MAX_CONSTRAINT_LENGTH - 1:0] o_bck_prv_st [`MAX_STATE_NUM - 1:0];

// reg [3:0] count; 
// reg [1:0] trellis_diagr[0:3][0:7];
// reg [2:0] trace;

// integer i;
// integer k;

// always @ (posedge clk or negedge rst) // need to consider memory depth of 5 times the constraint length with radix-2 (5 x K x k) and half of that with radix-4
// begin
//     if (rst == 0)
//     begin 
//         count <= 0; 
//         trace <= 7;
//         for(i = 0; i < 4; i = i + 1)begin // tuong duong voi 4 x 8 phep gan 32 phan tu 
//             for(k = 0; k < 8; k = k + 1)begin
//                 trellis_diagr[i][k] <= 2'b00; // quy ve nut 00
//             end
//         end
//     end
//     else 
//     begin
//         if (en_memory == 1)  
//         begin
//             if(count < 8)
//             begin
//             trellis_diagr[0][count] <= i_prv_st_00; 
//             trellis_diagr[2][count] <= i_prv_st_10; 
//             trellis_diagr[1][count] <= i_prv_st_01;
//             trellis_diagr[3][count] <= i_prv_st_11;
//             count <= count + 1;
//             end

//             if(count == 8 || count > 8)
//             begin
//                 o_bck_prv_st_00 <= trellis_diagr[0][trace]; 
//                 o_bck_prv_st_10 <= trellis_diagr[2][trace]; 
//                 o_bck_prv_st_01 <= trellis_diagr[1][trace]; 
//                 o_bck_prv_st_11 <= trellis_diagr[3][trace];
//                 if(trace != 0)
//                 trace <= trace - 1;
//             end
//         end
//     end
// end

endmodule
