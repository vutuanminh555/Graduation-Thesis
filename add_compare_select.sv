`include "param_def.sv"
`timescale 1ns / 1ps

module add_compare_select(clk, rst, en_acs,
                        i_dist,
                        o_fwd_prv_st,
                        o_sel_node);

input logic clk, rst, en_acs;
input logic [2:0] i_dist [`MAX_STATE_NUM][`RADIX]; // distance per transition

output logic [7:0] o_fwd_prv_st [`MAX_STATE_NUM]; // hold next state value for each state (index: current state, value: nxt state)
output logic [7:0] o_sel_node;

logic [8:0] node_mem [`MAX_STATE_NUM]; // node value
logic [8:0] pm_mem [`MAX_STATE_NUM][`RADIX]; // hold path metric for each transition = node value + distance

logic [8:0] min_node;

always @(posedge clk or negedge rst)
begin
    if(rst == 0)
    begin
        for(int i = 0; i < `MAX_STATE_NUM; i++)
        begin
            node_mem[i] <= 0;
            // for(int j = 0; j <`RADIX; j++)
            // begin
            //     pm_mem[i][j] <= 0;
            // end
        end
    end
    else 
    begin
        if(en_acs == 1)
        begin
            for(int i = 0; i < `MAX_STATE_NUM; i++) // calculate pm for every transition, hold value based on next state
            begin
                node_mem[i] <= node_mem[i] + i_dist[o_fwd_prv_st[i]][i[1:0]]; // add value from distance of the shortest path
                // for(int j = 0; j < `RADIX; j++) // i = state, j = input
                // begin
                //     // delay vs node_mem value ?
                //     //pm_mem[i][j] <= node_mem[i] +  i_dist[i][j]; // distance to transit to next state
                // end
            end
        end
        else
        begin

        end
    end
end

always @(*) // compare all transition to next state, choose smallest distance and output value 
begin
    if(rst == 0)
    begin
        for(int i = 0; i < `MAX_STATE_NUM; i++)
        begin
            o_fwd_prv_st[i] = 0;
            for(int j = 0; j <`RADIX; j++)
            begin
                pm_mem[i][k] = 0;
            end
        end
    end
    else 
    begin
        if(en_acs == 1)
        begin
            for(int i = 0; i < `MAX_STATE_NUM; i++) // need to calculate pm_mem first
            begin
                for(int j = 0; j < `RADIX; j++)
                begin
                    pm_mem[i][k] = node_mem[i] +  i_dist[i][j];
                end
            end

            for(int i = 0; i < `MAX_STATE_NUM; i++) // calculating min_pm
            begin
                automatic logic [2:0] min_pm = 3'b111; // can always choose at least 1 path
                automatic logic [7:0] min_prv_st = 0; 
                for(int j = 0; j < `RADIX; j++) // find path with smallest distance 
                begin
                    if(pm_mem[{j[1:0],i[7:2]}][i[1:0]] < min_pm) // state with the same input and first 6 bit will have the same nxt_state
                    begin
                        min_pm = pm_mem[{j[1:0],i[7:2]}][i[1:0]]; // priority: 00 > 01 > 10 > 11
                        min_prv_st = {j[1:0],i[7:2]};
                    end
                end 
                // all next state have next state, not all current state have next state
                o_fwd_prv_st[i] = min_prv_st ; // output address is next state, value is previous state (can be reduced)
            end
        end
        else 
        begin
            for(int i = 0; i < `MAX_STATE_NUM; i++)
            begin
                o_fwd_prv_st[i] = 0;
            end
        end
    end
end

always @(*) // output min_node
begin
    if(rst == 0)
    begin
        o_sel_node = 0;
        min_node = {9{1'b1}};
    end
    else
    begin
        if(en_acs == 1)
        begin
            min_node = {9{1'b1}};
            for(int i = 0; i < `MAX_STATE_NUM; i++)
            begin
                if(node_mem[i] < min_node)
                begin
                    min_node = node_mem[i];
                    o_sel_node = i;
                end
            end
        end
        else
        begin
            o_sel_node = 0;
        end
    end
end

endmodule