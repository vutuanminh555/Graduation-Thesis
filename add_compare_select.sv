`include "param_def.sv"
`timescale 1ns / 1ps

module add_compare_select(  clk, rst, en_acs,
                            i_dist,
                            o_fwd_prv_st, o_sel_node);

input logic clk, rst, en_acs;
input logic [2:0] i_dist [`MAX_STATE_NUM][`RADIX]; // distance per transition

output logic [`MAX_STATE_REG_NUM - 1:0] o_fwd_prv_st [`MAX_STATE_NUM]; // hold next state value for each state (index: current state, value: nxt state)
output logic [`MAX_STATE_REG_NUM - 1:0] o_sel_node;

logic [8:0] node_mem [`MAX_STATE_NUM]; // node value
logic [8:0] pm_mem [`MAX_STATE_NUM][`RADIX]; // hold path metric for each transition = node value + distance

logic [8:0] min_node;

logic [9:0] min_pm;
logic [`MAX_STATE_REG_NUM - 1:0] min_prv_st;

always @(posedge clk or negedge rst) // update and save pm value for each node, working
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
            begin // node_mem is 1 cycle delay compare to pm_mem, i_dist, o_fwd,prv_st
                node_mem[i] <= node_mem[o_fwd_prv_st[i]] + i_dist[o_fwd_prv_st[i]][{i[0],i[1]}]; // input bit order is reversed
                // if(i<4) 
                // begin
                //     $display("node_mem state=%b prv_state is: %b input is: %b", i, o_fwd_prv_st[i], {i[0], i[1]});
                //     $display("i_dist of node_mem %b value is: %d", i, i_dist[o_fwd_prv_st[i]][{i[0],i[1]}]);
                //     $display("previous node_mem %b value is: %d", i, node_mem[o_fwd_prv_st[i]]);
                //     $display("node_mem %b value is: %d\n", i, node_mem[i]);
                // end
            end
            //$display("o_sel_node value is: %b\n", o_sel_node);
        end
        else
        begin

        end
    end
end

always @(*) // compare all transition to next state, choose smallest distance and output value , working, need to check input bits order
begin
    if(rst == 0)
    begin
        for(int i = 0; i < `MAX_STATE_NUM; i++)
        begin
            o_fwd_prv_st[i] = 0;
            for(int j = 0; j <`RADIX; j++)
            begin
                pm_mem[i][j] = 0;
            end
        end
        min_pm = 10'b1111111111;
        // for(int i = 0; i < `MAX_STATE_NUM; i++)
        // begin
            min_prv_st = 0;
        //end
    end
    else 
    begin
        if(en_acs == 1)
        begin
            for(int i = 0; i < `MAX_STATE_NUM; i++) // need to calculate pm_mem first
            begin
                for(int j = 0; j < `RADIX; j++)
                begin
                    pm_mem[i][j] = node_mem[i] +  i_dist[i][j];
                    //if($realtime > 10200ns)
                    //$display("pm_mem state %b input %b value is: %d", i, j, pm_mem[i][j]);
                end
            end

            for(int i = 0; i < `MAX_STATE_NUM; i++) // calculating min_pm, working
            begin
                min_pm = 10'b1111111111; // can always choose at least 1 path
                min_prv_st = 0; // reset value for the next iteration
                for(int j = 0; j < `RADIX; j++) // find path with smallest distance 
                begin
                    if(pm_mem[{j[1:0],i[7:2]}][{i[0],i[1]}] < min_pm) // state with the same input and first 6 bit will have the same nxt_state
                    begin
                        min_pm = pm_mem[{j[1:0],i[7:2]}][{i[0],i[1]}]; // priority: 00 > 01 > 10 > 11
                        min_prv_st = {j[1:0],i[7:2]};
                    end
                    if($realtime > 10200ns)
                    begin
                    //$display("value of i_dist is: %d", i_dist[i][j]);
                    $display("min_pm value is: %b", min_pm);
                    $display("State with the same next state %b is: %b Input value is: %b Distance: %d", i, {j[1:0],i[7:2]}, {i[0],i[1]}, pm_mem[{j[1:0],i[7:2]}][{i[0],i[1]}]);
                    end
                end 
                //all next state have next state, not all current state have next state
                if($realtime > 10200ns)
                $display("Chosen prv_st for nxt_st %b: %b\n", i ,min_prv_st);
                o_fwd_prv_st[i] = min_prv_st ; // output address is next state, value is previous state (can be reduced)
            end
        end
        else 
        begin
            for(int i = 0; i < `MAX_STATE_NUM; i++)
            begin
                o_fwd_prv_st[i] = 0;
                for(int j = 0; j <`RADIX; j++)
                begin
                    pm_mem[i][j] = 0;
                end
            end
            min_pm = 10'b1111111111;
            //for(int i = 0; i < `MAX_STATE_NUM; i++)
            //begin
                min_prv_st = 0;
            //end
        end
    end
end

// always @(posedge clk or negedge rst) // delay pm_mem and o_fwd_prv_st
// begin
//     if(rst == 0)
//     begin
//         for(int i = 0; i < `MAX_STATE_NUM; i++)
//         begin
//             o_fwd_prv_st[i] <= 0;
//             for(int j = 0; j <`RADIX; j++)
//             begin
//                 pm_mem[i][j] <= 0;
//             end
//         end
//     end
//     else
//     begin
//         if(en_acs == 1)
//         begin
//             for(int i = 0; i < `MAX_STATE_NUM; i++) // need to calculate pm_mem first
//             begin
//                 for(int j = 0; j < `RADIX; j++)
//                 begin
//                     pm_mem[i][j] <= node_mem[i] +  i_dist[i][j];
//                 end
//                 o_fwd_prv_st[i] <= min_prv_st[i];
//             end
//         end
//         else
//         begin
//             for(int i = 0; i < `MAX_STATE_NUM; i++)
//             begin
//                 o_fwd_prv_st[i] <= 0;
//                 for(int j = 0; j <`RADIX; j++)
//                 begin
//                     pm_mem[i][j] <= 0;
//                 end
//             end
//         end
//     end
// end

always @(*) // calculate and output min_node
begin
    if(rst == 0)
    begin
        min_node = 9'b111111111;
        o_sel_node = 0;
    end
    else
    begin
        if(en_acs == 1)
        begin
            min_node = 9'b111111111;
            for(int i = 0; i < `MAX_STATE_NUM; i++) // `MAX_STATE_NUM
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
            min_node = 9'b111111111;
            o_sel_node = 0;
        end
    end
end

endmodule