`include "param_def.sv"
`timescale 1ns / 1ps

module slice(   rst, clk, en_extract,
                i_data_frame, 
                o_rx);

input rst,clk,en_extract;
input [`TRACEBACK_DEPTH - 1:0] i_data_frame; // depends on traceback depth, choose between 120 and 60

output reg [`RADIX - 1:0] o_rx; // changed to 4 bit

//reg [3:0] count;

// always @ (posedge clk or negedge rst)  // extract 4 bit (radix-4) at a time
// begin
//     if (rst == 0)
//     begin
//         count <= 4'b1111; // MSB to LSB 
//         o_Rx <= 4'b0000;
//     end
//     else 
//     begin
//         if (en_extract == 1)
//         begin
//             o_Rx <= {i_data[count], i_data[count - 3]}; // changed
//             count <= count - 4; // 3 - 4 = 15
//         end
//         else if(en_extract == 0)
//         begin
//             o_Rx <= 4'b0000;
//             count <= count;
//         end
//     end
// end

endmodule
