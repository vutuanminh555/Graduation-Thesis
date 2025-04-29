`include "param_def.sv"
`timescale 1ns / 1ps

module add_compare_select(  clk, rst, en_acs,
                            i_dist, 
                            o_fwd_prv_st, o_sel_node);

input logic clk, rst, en_acs;
input logic [2:0] i_dist [`MAX_STATE_NUM][`RADIX]; // distance per transition

output logic [`MAX_STATE_REG_NUM - 1:0] o_fwd_prv_st [`MAX_STATE_NUM];
output logic [`MAX_STATE_REG_NUM - 1:0] o_sel_node;

logic [8:0] node_mem [`MAX_STATE_NUM];  // use 32 write first bram
logic [8:0] pm [`MAX_STATE_NUM][`RADIX];

logic [7:0] stage1 [128]; // use 16 bram
logic [7:0] stage2 [64]; // use 8 bram
logic [7:0] stage3 [32]; // use 4 bram
logic [7:0] stage4 [16]; // use 2 bram 
logic [7:0] stage5 [8]; // use 1 bram 
logic [7:0] stage6 [4]; 
logic [7:0] stage7 [2];

logic toggle;

always_ff @(posedge clk) // update and save pm value for each node
begin
    if(rst == 0)
    begin
        for(int i = 0; i < `MAX_STATE_NUM; i++)
        begin
            node_mem[i] <= 0;
        end
        toggle <= 0;
    end
    else if(en_acs == 1)
    begin
        toggle <= ~toggle;
        if(toggle == 1)
        begin
            for(int i = 0; i < `MAX_STATE_NUM; i++) // add value from distance of the shortest path, node_mem has 1 cycle delay to i_dist
            begin
                node_mem[i] <= node_mem[o_fwd_prv_st[i]] + i_dist[o_fwd_prv_st[i]][{i[0],i[1]}]; // input bit order is reversed
            end
        end
    end
end

always_ff @(posedge clk)
begin
    if(toggle == 0)
    begin
        for(int i = 0; i < `MAX_STATE_NUM; i++)
        begin
            for(int j = 0; j < `RADIX; j++)
            begin
                pm[i][j] <= node_mem[{j[1:0],i[7:2]}] + i_dist[{j[1:0],i[7:2]}][{i[0],i[1]}];
            end
        end
    end
end

always_comb // compare all transition to next state, choose smallest distance and output value
begin 
    for(int i = 0; i < `MAX_STATE_NUM; i++) // calculating min_pm
    begin
        automatic logic [9:0] min_pm = 10'b1111111111; // can always choose at least 1 path
        automatic logic [`MAX_STATE_REG_NUM - 1:0] min_prv_st = 0; // reset value for the next iteration
        for(int j = 0; j < `RADIX; j++) // find path with smallest distance 
        begin
            if(pm[i][j] < min_pm) // nxt_state have the same input but different previous state
            begin
                min_pm = pm[i][j];
                min_prv_st = {j[1:0],i[7:2]};
            end
        end 
        o_fwd_prv_st[i] = min_prv_st ; // output address is next state, value is previous state
    end
end

always_ff @(posedge clk) // adress = index; value = winner state
begin
    for(int i = 0; i < 128; i++)
    begin   
        stage1[i] <= (node_mem[i*2] > node_mem[i*2+1]) ? i*2 + 1 : i*2; // prioritize small index
    end

    for(int i = 0; i < 64; i++)
    begin
        stage2[i] <= (node_mem[stage1[i*2]] > node_mem[stage1[i*2+1]]) ? stage1[i*2 + 1] : stage1[i*2];
    end

    for(int i = 0; i < 32; i++)
    begin
        stage3[i] <= (node_mem[stage2[i*2]] > node_mem[stage2[i*2+1]]) ? stage2[i*2 + 1] : stage2[i*2];
    end

    for(int i = 0; i < 16; i++)
    begin
        stage4[i] <= (node_mem[stage3[i*2]] > node_mem[stage3[i*2+1]]) ? stage3[i*2 + 1] : stage3[i*2];
    end

    for(int i = 0; i < 8; i++)
    begin
        stage5[i] <= (node_mem[stage4[i*2]] > node_mem[stage4[i*2+1]]) ? stage4[i*2 + 1] : stage4[i*2];
    end

    for(int i = 0; i < 4; i++)
    begin
        stage6[i] <= (node_mem[stage5[i*2]] > node_mem[stage5[i*2+1]]) ? stage5[i*2 + 1] : stage5[i*2];
    end

    for(int i = 0; i < 2; i++)
    begin
        stage7[i] <= (node_mem[stage6[i*2]] > node_mem[stage6[i*2+1]]) ? stage6[i*2 + 1] : stage6[i*2];
    end

    o_sel_node <= (node_mem[stage7[0]] > node_mem[stage7[1]]) ? stage7[1] : stage7[0];
end

endmodule