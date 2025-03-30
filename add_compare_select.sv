`include "param_def.sv"
`timescale 1ns / 1ps

module add_compare_select(clk, rst, en_acs,
                        i_dist,
                        o_fwd_nxt_st,
                        o_sel_node);

input logic clk, rst, en_acs;
input logic [2:0] i_dist [`MAX_STATE_NUM][`RADIX];

output logic [7:0] o_fwd_nxt_st [`MAX_STATE_NUM]; // hold next state value for each state (index: current state, value: nxt state)
output logic [7:0] o_sel_node;

logic [8:0] pm_mem [`MAX_STATE_NUM]; // hold path metric for each state

logic [1:0] shortest_path [`MAX_STATE_NUM];

always @(posedge clk or negedge rst)
begin
    if(rst == 0)
    begin
        for(int i = 0; i < `MAX_STATE_NUM; i++)
        begin
            pm_mem <= 0;
        end
    end
    else 
    begin
        if(en_acs == 1)
        begin
            for(int i = 0; i < `MAX_STATE_NUM; i++)
            begin
                for(int j = 0; j < `RADIX; j++)
                begin
                    pm_mem[i] = pm_mem[i] + 
                end
            end
        end
        else
        begin

        end
    end
end

always @(*) // find path with the smallest pm and 
begin
    if(rst == 0)
    begin

    end
    else 
    begin
        if(en_acs == 1)
        begin

        end
        else 
        begin

        end
    end
end

endmodule