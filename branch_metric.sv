`include "param_def.sv"
`timescale 1ns / 1ps

module branch_metric(clk, rst, en_bm, 
                    i_rx, i_mux,
                    o_dist, o_cal_done);    // use 3 bit (8 levels) to quantize, from 0 to 3.3V (not implemented yet)
                                // calculate distance, store in memory and then output branch metric for each input

input logic clk, rst, en_bm;
input logic [15:0] i_mux;
input logic [`SLICED_INPUT_NUM - 1:0] i_rx; 

output logic [2:0] o_dist [`MAX_STATE_NUM][`RADIX]; // 3 bit distance, 8 bit current state, 2 input bit 
output logic o_cal_done;

logic [2:0] bm_mem [`MAX_INPUT_NUM][`MAX_STATE_NUM][`RADIX]; // memory: 3 bits distance, 6 slice bits, 8 bits state, 2 bits input 
logic [2:0] cal_dist [`MAX_INPUT_NUM];

always @(posedge clk or negedge rst)
begin
    if(rst == 0)
    begin
        for(int i = 0; i < `MAX_INPUT_NUM; i++) 
        begin
            for(int j = 0; j < `MAX_STATE_NUM; j++)
            begin
                for(int k = 0; k < `RADIX; k++)
                begin
                    bm_mem[i][j][k] <= 0; 
                end 
            end
        end
    end
    else
    begin
        if (en_bm == 1)  
        begin
            for(int i = 0; i < `MAX_INPUT_NUM; i++)   // finish after 1024 cycle, after that can start outputing distance
            begin
                bm_mem[i][i_mux[13:6]][i_mux[15:14]] <= cal_dist[i]; // possible input, state, input
                // bm_mem 1 cycle slower than cal_dist
                //if(i < 4)
                //$display("Iteration %d   bm_mem value is: %d cal_dist value is: %d", i, bm_mem[i][i_mux[13:6]][i_mux[5:0]], cal_dist[i]); 
            end
        end
        else 
        begin
        
        end
    end
end

always @(*) // precalculate bm, working
begin 
    if(rst == 0)
    begin
        for(int i = 0; i < `MAX_INPUT_NUM; i++)
        begin
            cal_dist[i] = 0;
        end
    end
    else
    begin
        if(en_bm == 1)
        begin
            for(int i = 0; i < `MAX_INPUT_NUM; i++) // calculate hamming distance for each possible input
            begin
                cal_dist[i] = $countones(6'(i) ^ i_mux[`SLICED_INPUT_NUM - 1:0]); // count 1 and write result
            end
        end
        else
        begin
            for(int i = 0; i < `MAX_INPUT_NUM; i++)
            begin
                cal_dist[i] = 0;
            end
        end
    end
end

always @(*) // output bm to o_dist
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
        o_cal_done = 0;
    end
    else
    begin
        if(en_bm == 1)
        begin
            for(int i = 0; i < `MAX_STATE_NUM; i++)
            begin
                for(int j = 0; j < `RADIX; j++)
                begin
                    o_dist[i][j] = bm_mem[i_rx][i][j];
                    //if(i < 4)
                    //$display("received bits are: %b state is: %b input is: %b distance is: %d", i_rx, i, j, o_dist[i][j]);
                end
            end
            if(i_mux[15:6] == '1) // last possible state with last possible input
                o_cal_done = 1; // sync with bm_mem update
            else
                o_cal_done = 0; // turn off when conv_encoder turn off
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
            o_cal_done = 0;
        end
    end
end

endmodule
