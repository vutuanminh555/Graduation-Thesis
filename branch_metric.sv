`include "param_def.sv"
`timescale 1ns / 1ps

module branch_metric(clk, rst, en_bm, 
                    i_rx,
                    i_mux,
                    o_dist);    // use 3 bit (8 levels) to quantize, from 0 to 3.3V (not implemented yet)
                                // calculate distance, store in memory and then output branch metric for each input

input logic clk, rst, en_bm;
input logic [15:0] i_mux;
input logic [`SLICED_INPUT_NUM - 1:0] i_rx; 

output logic [2:0] o_dist [`MAX_STATE_REG_NUM - 1:0][`DECODE_BIT_NUM - 1:0]; // 3 bit distance, 8 bit current state, 2 input bit 

logic [2:0] bm_mem [`SLICED_INPUT_NUM - 1:0][`MAX_STATE_REG_NUM - 1:0][`DECODE_BIT_NUM - 1:0]; // memory: 3 bits distance, 6 slice bits, 8 bits state, 2 bits input 
logic [2:0] cal_dist [`SLICED_INPUT_NUM - 1:0];


always @(posedge clk or negedge rst)
begin
    if(rst == 0)  // add cal_dist = 0
    begin
        for(int i = 0; i < `MAX_INPUT_NUM; i++) // test index again 
        begin
            for(int j = 0; j < `MAX_STATE_NUM; j++)
            begin
                for(int k = 0; k < `RADIX; k++)
                begin
                    bm_mem[i][j][k] <= 0; // default to 0
                end 
            end
        end
        // for(int i = 0; i < `MAX_STATE_NUM; i++)
        // begin
        //     for(int j = 0; j < `RADIX; j++)
        //     begin
        //         o_dist[i][j] <= 0;
        //     end
        // end
    end
    else
    begin
        if (en_bm == 1)  
        begin
            for(int i = 0; i < `MAX_INPUT_NUM; i++)  // save to memory
            begin
                bm_mem[i][i_mux[13:6]][i_mux[5:0]] <= cal_dist[i];
            end
        end
        else 
        begin
            // for(int i = 0; i < `MAX_STATE_NUM; i++)
            // begin
            //     for(int j = 0; j < `RADIX; j++)
            //     begin
            //         o_dist[i][j] <= 0;
            //     end
            // end
        end
    end
end

always @(*) // precalculate bm
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
        for(int i = 0; i < `MAX_INPUT_NUM; i++) // for each possible input
        begin
            logic [`SLICED_INPUT_NUM - 1:0] diff;
            diff = 6'(i);
            diff = diff ^ i_mux[`SLICED_INPUT_NUM - 1:0]; // different bits become 1
            cal_dist[i] = $countones(diff); // count 1 and write result
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
                o_dist[i][j] <= 0;
            end
        end
    end
    else
    begin
        for(int i = 0; i < `MAX_STATE_NUM; i++)
        begin
            for(int k = 0; k < `RADIX; k++)
            begin
                o_dist[i][k] = bm_mem[i_rx][i][k]; 
            end
        end
    end
end

always @(*) // fsm 
begin

end

endmodule
