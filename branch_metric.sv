`include "param_def.sv"
`timescale 1ns / 1ps

module branch_metric(clk, rst, en_bm, 
                    i_rx,
                    i_mux,
                    o_distance);   // need to calculate distance, use 3 bits (8 levels) to quantize soft decision

input clk, rst, en_bm;
input [31:0] i_mux; // need input bit, state, nxt_state (nxt_state 2), output to calculate distance
input [`RADIX - 1:0] i_rx; // change to 4 bit 

output [2:0] o_distance [`MAX_TRANSITION_NUM - 1:0];

// reg [2:0] distance [63:0] [1023:0] // should have memory to hold distance value for all possible branch

// //output reg [3:0] HD [3:0][3:0]; // [bit_size], [radix][state]

// output reg [2:0] o_dist [1023:0]; // should output all branch metric for all possible transition

// reg [1:0] pair_bit; 

// integer state;
// integer i_bit;

// always @ (posedge clk or negedge rst)  //  
// if(rst == 0) // 
// begin
//     for(i = 0; i < 16; i = i + 1)
//     begin
//         HD[i] = 0;
//     end
// end
// else
// begin
//         if (en_branch == 1) // need to save 
//         begin // there is 64 possible variations of input 
            
//         end
//         else 
//         begin // all output default to 0
//             for(i = 0; i < 16; i = i + 1)
//             begin
//                 HD[i] = 0;
//             end
//         end
// end

endmodule
