`include "param_def.sv"
`timescale 1ns / 1ps

module trellis_diagr(   clk, rst, en_td, 
                        i_fwd_prv_st, i_ood,
                        o_bck_prv_st, o_td_full, o_td_empty);

input logic clk, rst, en_td;
input i_ood;
input logic [7:0] i_fwd_prv_st [256];

output logic [7:0] o_bck_prv_st [256];
output logic o_td_full;
output logic o_td_empty;

logic [7:0] td_mem [256][45]; // 256 node, traceback depth = 45 (5*K)
logic [5:0] depth;

logic wrk_mode; // create diagram / output data to traceback

always @(posedge clk or negedge rst) // save data to memory 
begin
    if(rst == 0)
    begin
        for(int i = 0; i < 256; i++)
        begin
            o_bck_prv_st[i] <= 0;
            for(int j = 0; j < 45; j++)
            begin
                td_mem[i][j] <= 0;
            end
        end
        depth <= 0; 
        o_td_full <= 0;
        o_td_empty <= 0;
    end
    else
    begin
        if(en_td == 1)
        begin
            if(wrk_mode == 0) // creating trellis diagram
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
            else if(wrk_mode == 1) // output transition to traceback
            begin
                // for(int i = 0; i < 256; i++)
                // begin
                //     o_bck_prv_st[i] <= td_mem[i][depth];

                // end
                depth <= depth - 1; 
                if(depth == 0)
                begin
                    o_td_empty <= 1; // could use combinational logic
                end
            end
        end
        else
        begin

        end
    end
end

always @(*) // output data
begin
    if(rst == 0)
    begin
        for(int i = 0; i < 256; i++)
        begin
            o_bck_prv_st[i] = 0;
        end
    end
    else
    begin
        if(en_td == 1)
        begin
            for(int i = 0; i < 256; i++)
            begin
                o_bck_prv_st[i] = td_mem[i][depth];
            end
        end
        else
        begin
            for(int i = 0; i < 256; i++)
            begin
                o_bck_prv_st[i] = 0;
            end
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
            if(o_td_full == 1 || i_ood == 1)
            begin
                wrk_mode = 1;
            end
            else
            wrk_mode = 0;
        end
        else
        begin
            wrk_mode = 0;
        end
    end
end

endmodule
