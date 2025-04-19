`include "param_def.sv"
`timescale 1ns / 1ps

module add_compare_select(  clk, rst, en_acs,
                            i_constr_len, i_dist, 
                            o_fwd_prv_st, o_sel_node);

input logic clk, rst, en_acs;
input logic i_constr_len;
input logic [2:0] i_dist [`MAX_STATE_NUM][`RADIX]; // distance per transition

output logic [`MAX_STATE_REG_NUM - 1:0] o_fwd_prv_st [`MAX_STATE_NUM]; // hold next state value for each state (index: current state, value: nxt state)
output logic [`MAX_STATE_REG_NUM - 1:0] o_sel_node;

logic [`MAX_STATE_REG_NUM - 1:0] sel_node;

logic [8:0] node_mem [`MAX_STATE_NUM];  // maximum traceback depth of 85

logic [8:0] min_node;

logic [9:0] min_pm;

logic [`MAX_STATE_REG_NUM - 1:0] min_prv_st;

always_ff @(posedge clk) // update and save pm value for each node
begin
    if(rst == 0)
    begin
        for(int i = 0; i < `MAX_STATE_NUM; i++)
        begin
            node_mem[i] <= 0;
        end
    end
    else 
    begin
        if(en_acs == 1)
        begin
            for(int i = 0; i < `MAX_STATE_NUM; i++) // add value from distance of the shortest path, node_mem has 1 cycle delay to i_dist
            begin
                node_mem[i] <= node_mem[o_fwd_prv_st[i]] + i_dist[o_fwd_prv_st[i]][{i[0],i[1]}]; // input bit order is reversed
            end
        end
        else
        begin

        end
    end
end

always_comb // compare all transition to next state, choose smallest distance and output value, need to switch to sequential to read data from bram 
begin
    for(int i = 0; i < `MAX_STATE_NUM; i++)
    begin
        o_fwd_prv_st[i] = 0;
    end
    min_pm = 10'b1111111111;
    min_prv_st = 0;
    
    if(en_acs == 1)
    begin
        for(int i = 0; i < `MAX_STATE_NUM; i++) // calculating min_pm
        begin
            min_pm = 10'b1111111111; // can always choose at least 1 path
            min_prv_st = 0; // reset value for the next iteration
            for(int j = 0; j < `RADIX; j++) // find path with smallest distance 
            begin
                if(i_constr_len == `CONSTR_LEN_3) 
                begin
                    if(node_mem[{i[7:2],j[1:0]}] + i_dist[{i[7:2],j[1:0]}][{i[0],i[1]}] < min_pm) // nxt_state have the same input but different previous state
                    begin
                        min_pm = node_mem[{i[7:2],j[1:0]}] + i_dist[{i[7:2],j[1:0]}][{i[0],i[1]}];
                        min_prv_st = {i[7:2],j[1:0]};
                    end
                end
                else // constraint length 5-7-9
                begin
                    if(node_mem[{j[1:0],i[7:2]}] + i_dist[{j[1:0],i[7:2]}][{i[0],i[1]}] < min_pm)
                    begin
                        min_pm = node_mem[{j[1:0],i[7:2]}] + i_dist[{j[1:0],i[7:2]}][{i[0],i[1]}]; // priority: 00 > 01 > 10 > 11
                        min_prv_st = {j[1:0],i[7:2]};
                    end
                end
            end 
            o_fwd_prv_st[i] = min_prv_st ; // output address is next state, value is previous state
        end
    end
end

always_comb // calculate min_node
begin
    min_node = 9'b111111111; 
    sel_node = 0;
        if(en_acs == 1)
        begin
            for(int i = 0; i < `MAX_STATE_NUM; i++)
            begin
                if(node_mem[o_fwd_prv_st[i]] + i_dist[o_fwd_prv_st[i]][{i[0],i[1]}] < min_node) // compare to node_mem[i], avoid 1 cycle delay
                begin
                    min_node = node_mem[o_fwd_prv_st[i]] + i_dist[o_fwd_prv_st[i]][{i[0],i[1]}];
                    sel_node = i;
                end
            end
        end
end

always_ff @(posedge clk) // output data
begin
    if(rst == 0)
    begin
        o_sel_node <= 0;
    end
    else
    begin
        if(en_acs == 1)
        begin
            o_sel_node <= sel_node;
        end
        else
        begin
            o_sel_node <= o_sel_node;
        end
    end
end

endmodule

