`include "param_def.sv"
`timescale 1ns / 1ps

module branch_metric(clk, rst, en_bm, 
                    i_rx,
                    i_mux,
                    o_dist);    // use 3 bit (8 levels) to quantize, from 0 to 3.3V (not implemented yet)
                                // calculate distance, store in memory and then output branch metric for each input

input clk, rst, en_bm;
input [15:0] i_mux;
input [`RADIX - 1:0] i_rx; // change to 4 bit 

output [2:0] o_dist [`MAX_STATE_REG_NUM - 1:0][`RADIX - 1:0]; // 3 bit distance, 8 bit current state, 2 input bit 

reg [2:0] bm_mem [`MAX_CODE_RATE*DECODE_BIT_NUM - 1:0][`MAX_STATE_REG_NUM - 1:0][`RADIX - 1:0]; // memory: 3 bits distance, 6 possible input bits, 8 bit state, 4 input bit  

always @(posedge clk or negedge rst)
begin
    if(rst == 0)  
    begin
        for(int i = 0; i < `MAX_STATE_REG_NUM; i = i + 1)
        begin
            for(int k = 0; k < `RADIX; k = k + 1)
            begin
                bm_mem[i][k] <= 0; // default to 0 
            end
        end
        for(int i = 0; i < `MAX_TRANSITION_NUM; i = i + 1)
        begin
            o_dist[i] <= 0;
        end
    end
    else
    begin
        if (en_branch == 1) // need to save 
        begin // there is 64 possible variations of input 
            
        end
        else 
        for(int i = 0; i < `MAX_TRANSITION_NUM; i = i + 1)
        begin
            o_dist[i] <= 0;
        end
    end
end

endmodule
