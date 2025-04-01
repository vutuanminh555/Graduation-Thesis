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

always @(posedge clk or negedge rst)
begin
    if(rst == 0)
    begin

    end
    else
    begin
        if(en_t == 1)
        begin

        end
        else
        begin

        end
    end
end

always @(*)
begin
    if(rst == 0)
    begin

    end
    else 
    begin
        if(en_t == 1)
        begin

        end
        else
        begin

        end
    end
end

endmodule
