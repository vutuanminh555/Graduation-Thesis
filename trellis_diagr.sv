`include "param_def.sv"
`timescale 1ns / 1ps

module trellis_diagr(   clk, rst, en_td, 
                        i_fwd_prv_st,
                        o_bck_prv_st, o_td_full);

input logic clk, rst, en_td;
input logic [7:0] i_fwd_prv_st [255:0];

output logic [`MAX_CONSTRAINT_LENGTH - 1:0] o_bck_prv_st [`MAX_STATE_NUM - 1:0];
output logic o_td_full;

logic [7:0] td_mem [255:0][44:0]; // 256 node, traceback depth = 45 (5*K)
logic [5:0] depth;

logic wrk_mode; // create diagram / output data to traceback

always @(posedge clk or negedge rst) // save data to memory 
begin
    if(rst == 0)
    begin
        for(int i = 0; i < 256; i++)
        begin
            for(int j = 0; j < 45; j++)
            begin
                td_mem[i][j] <= 0;
            end
        end
        depth <= 0; 
        o_td_full <= 0;
    end
    else
    begin
        if(en_td == 1)
        begin
            for(int i = 0; i < 256; i++)
            begin
                td_mem[i][depth] <= i_fwd_prv_st[i]; 
            end
            depth <= depth + 1;
            if(depth == 44)
            begin
                o_td_full <= 1;
            end
        end
        else
        begin

        end
    end
end

always @(*) // change working mode
begin
    if(rst == 0)
    begin
        wrk_mode = 0;
    end
    else
    begin
        if(en_td == 1)
        begin 

        end
        else
        begin

        end
    end
end

endmodule
