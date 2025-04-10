`include "param_def.sv"
`timescale 1ns / 1ps

module trellis_diagr(   clk, rst, en_td, 
                        i_fwd_prv_st, i_ood,
                        o_bck_prv_st, o_td_full, o_td_empty);

input logic clk, rst, en_td;
input logic i_ood;
input logic [`MAX_STATE_REG_NUM - 1:0] i_fwd_prv_st [`MAX_STATE_NUM];

output logic [`MAX_STATE_REG_NUM - 1:0] o_bck_prv_st [`MAX_STATE_NUM];
output logic o_td_full;
output logic o_td_empty;

logic [`MAX_STATE_REG_NUM - 1:0] td_mem [`MAX_STATE_NUM][`TRACEBACK_DEPTH];
logic [6:0] depth;

logic wrk_mode;

always @(posedge clk or negedge rst) // save data to memory 
begin
    if(rst == 0)
    begin
        for(int i = 0; i < `MAX_STATE_NUM; i++)
        begin
            for(int j = 0; j < `TRACEBACK_DEPTH; j++)
            begin
                td_mem[i][j] <= 0;
            end
        end
        depth <= 0; 
    end
    else
    begin
        if(en_td == 1)
        begin
            if(wrk_mode == 0) // creating trellis diagram
            begin
                for(int i = 0; i < `MAX_STATE_NUM; i++)
                begin
                    td_mem[i][depth] <= i_fwd_prv_st[i]; 
                end
                if(i_ood == 0)
                    depth <= depth + 1;
            end
            else if(wrk_mode == 1) // output transition to traceback
            begin
                depth <= depth - 1; 
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
        for(int i = 0; i < `MAX_STATE_NUM; i++)
        begin
            o_bck_prv_st[i] = 0;
        end
        o_td_empty = 0;
        o_td_full = 0;
    end
    else
    begin
        if(en_td == 1)
        begin
            for(int i = 0; i < `MAX_STATE_NUM; i++)
            begin
                o_bck_prv_st[i] = td_mem[i][depth];
            end
            if(wrk_mode == 0)
            begin
                if(depth == `TRACEBACK_DEPTH - 1)
                begin
                    o_td_empty = 0; 
                    o_td_full = 1;
                end
                else
                begin
                    o_td_empty = 0; 
                    o_td_full = 0;
                end
            end
            else if(wrk_mode == 1)
            begin
                if(depth == 0)
                begin
                    o_td_empty = 1; 
                    o_td_full = 0;
                end
                else
                begin
                    o_td_empty = 0; 
                    o_td_full = 0;
                end
            end
            else
            begin
                o_td_empty = 0;
                o_td_full = 0;
            end
        end
        else
        begin
            for(int i = 0; i < `MAX_STATE_NUM; i++)
            begin
                o_bck_prv_st[i] = 0;
            end
            o_td_empty = 0;
            o_td_full = 0;
        end
    end
end

always @(posedge clk or negedge rst) // change working mode, use sequential logic to sync with traceback module
begin
    if(rst == 0)
    begin
        wrk_mode <= 0;
    end
    else
    begin
        if(en_td == 1)
        begin 
            if(o_td_full == 1 || i_ood == 1) // only need enable pulse
                wrk_mode <= 1;
        end
        else
        begin
            wrk_mode <= 0;
        end
    end
end

endmodule
