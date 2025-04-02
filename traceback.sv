`include "param_def.sv"
`timescale 1ns / 1ps

module traceback(   clk, rst, en_t,
                    i_sel_node, i_bck_prv_st, i_td_empty,
                    o_decoder_data, o_decoder_done);

input logic clk, rst, en_t;
input logic [7:0] i_sel_node; 
input logic [7:0] i_bck_prv_st [256];
input logic i_td_empty;

output logic [7:0] o_decoder_data;
output logic o_decoder_done;

logic [7:0] chosen_node;
logic [7:0] nxt_chosen_node;

logic [3:0] count;
logic [1:0] pair_bit;

always @(posedge clk or negedge rst)
begin
    if(rst == 0)
    begin
        chosen_node <= 0;
        o_decoder_data <= 0;
        count <= 0;
    end
    else
    begin
        if(en_t == 1)
        begin
            chosen_node <= nxt_chosen_node;
            o_decoder_data[count] <= pair_bit[1];
            o_decoder_data[count + 1] <= pair_bit[0];
            count <= count + 2;
            $display("o_decoder_data value is: %b\n", o_decoder_data);
        end
        else
        begin
            chosen_node <= i_sel_node; // i_sel_node should output chosen node before en_t == 1
            o_decoder_data <= 0;
        end
    end
end

always @(*)
begin
    if(rst == 0)
    begin
        nxt_chosen_node = 0;
        o_decoder_done = 0;
    end
    else 
    begin
        if(en_t == 1)
        begin
            nxt_chosen_node = i_bck_prv_st[chosen_node];
            pair_bit = chosen_node[1:0];
            if(count == 8)
            begin
                o_decoder_done = 1;
            end
        end
        else
        begin
            nxt_chosen_node = i_sel_node;
            o_decoder_done = 0;
        end
    end
end

endmodule
