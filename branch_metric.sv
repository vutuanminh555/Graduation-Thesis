`include "param_def.sv"
`timescale 1ns / 1ps

module branch_metric(rst, en_bm, 
                    i_rx, i_trans_data,
                    o_dist);    // use 3 bit (8 levels) to quantize, from 0 to 3.3V (not implemented yet)
                                // calculate distance, store in memory and then output branch metric for each input

input logic rst, en_bm;
input logic [`SLICED_INPUT_NUM - 1:0] i_trans_data [`MAX_STATE_NUM][`RADIX];
input logic [`SLICED_INPUT_NUM - 1:0] i_rx; 

output logic [2:0] o_dist [`MAX_STATE_NUM][`RADIX]; // 3 bit distance, 8 bit current state, 2 input bit 

always_comb // output bm to o_dist
begin
    if(rst == 0)
    begin
        for(int i = 0; i < `MAX_STATE_NUM; i++)
        begin
            for(int j = 0; j < `RADIX; j++)
            begin
                o_dist[i][j] = 0;
            end
        end
    end
    else
    begin
        if(en_bm == 1)
        begin
            for(int i = 0; i < `MAX_STATE_NUM; i++)
            begin
                for(int j = 0; j < `RADIX; j++)
                begin
                    o_dist[i][j] = $countones(i_rx ^ i_trans_data[i][j]);
                end
            end
        end
        else 
        begin
            for(int i = 0; i < `MAX_STATE_NUM; i++)
            begin
                for(int j = 0; j < `RADIX; j++)
                begin
                    o_dist[i][j] = 0;
                end
            end
        end
    end
end

endmodule