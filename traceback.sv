`include "param_def.sv"
`timescale 1ns / 1ps

module traceback(   clk, rst, en_t,
                    i_sel_node, i_bck_prv_st,
                    o_decoder_data, o_decoder_done); 

input logic clk, rst, en_t;
input logic [`MAX_STATE_REG_NUM - 1:0] i_sel_node; 
input logic [`MAX_STATE_REG_NUM - 1:0] i_bck_prv_st [`MAX_STATE_NUM];

output logic [`TRACEBACK_DEPTH*2 - 1:0] o_decoder_data;
output logic o_decoder_done;

logic [`MAX_STATE_REG_NUM - 1:0] chosen_node;
logic [`MAX_STATE_REG_NUM - 1:0] nxt_chosen_node;

logic [6:0] count;
logic [`OUTPUT_BIT_NUM - 1:0] pair_bit;

always_ff @(posedge clk)
begin
    chosen_node <= nxt_chosen_node;
    if(rst == 0)
    begin
        // chosen_node <= 0;
        o_decoder_data <= 0;
        count <= 0;
    end
    else if(en_t == 1)
    begin
        // if(en_t == 1)
        // begin
            //chosen_node <= nxt_chosen_node;
            if(count < `TRACEBACK_DEPTH*2 - 2)
            begin
            o_decoder_data[count] <= pair_bit[0]; 
            o_decoder_data[count + 1] <= pair_bit[1];
            count <= count + 2;
            end
        //end
        // else
        // begin
        //     chosen_node <= i_sel_node; 
        //     o_decoder_data <= 0;
        // end
    end
end

always_ff @(posedge clk)
begin
    if(rst == 0)
    begin
        o_decoder_done <= 0;
    end
    else if(en_t == 1)
    begin
    //     if(en_t == 1)
    //     begin
            if(count == 8) //`TRACEBACK_DEPTH*2 - 2
                o_decoder_done <= 1;
        //end
        // else
        // begin   
        //     o_decoder_done <= 0;
        // end
    end
end

always_comb
begin
    //if(rst == 0)
    //begin
        nxt_chosen_node = i_sel_node;
        pair_bit = chosen_node[1:0];
    //end
    //else 
    //begin
        if(en_t == 1)
        begin
            nxt_chosen_node = i_bck_prv_st[chosen_node];
            // pair_bit = chosen_node[1:0];
        end
        // else
        // begin
        //     nxt_chosen_node = i_sel_node;
        //     pair_bit = 0;
        // end
    //end
end

endmodule
