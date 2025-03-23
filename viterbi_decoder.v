`timescale 1ns / 1ps

module viterbi_decoder(sys_clk,rst,en,i_data,o_data,o_done); // need to change wire width 

input sys_clk,rst,en;
input [15:0] i_data;

output [7:0] o_data;
output o_done;

wire en_e,en_b,en_a,en_m,en_t;
wire [1:0] rx;
wire [1:0] hd1,hd2,hd3,hd4,hd5,hd6,hd7,hd8;
wire [1:0] prv_st_00,prv_st_10,prv_st_01,prv_st_11;
wire [1:0] node;
wire [1:0] bck_prv_st_00,bck_prv_st_10,bck_prv_st_01,bck_prv_st_11;

control C1 (.clk(sys_clk),
            .rst(rst),
            .en(en),
            .en_extract(en_e),
            .en_branch(en_b),
            .en_add(en_a),
            .en_memory(en_m),
            .en_traceback(en_t));

extract_bit Ex1 (.rst(rst),
                 .clk(sys_clk),
                 .en_extract(en_e),
                 .i_data(i_data),
                 .o_Rx(rx));
                 
branch_metric Br1 (.rst(rst),
                   .en_branch(en_b),
                   .i_Rx(rx),
                   .HD1(hd1),
                   .HD2(hd2),
                   .HD3(hd3),
                   .HD4(hd4),
                   .HD5(hd5),
                   .HD6(hd6),
                   .HD7(hd7),
                   .HD8(hd8));

add_compare_select Add1 (.clk(sys_clk),
                         .rst(rst),
                         .en_add(en_a),
                         .HD1(hd1),
                         .HD2(hd2),
                         .HD3(hd3),
                         .HD4(hd4),
                         .HD5(hd5),
                         .HD6(hd6),
                         .HD7(hd7),
                         .HD8(hd8),
                         .o_prv_st_00(prv_st_00),
                         .o_prv_st_10(prv_st_10),
                         .o_prv_st_01(prv_st_01),
                         .o_prv_st_11(prv_st_11),
                         .o_select_node(node));

 memory M1 (.clk(sys_clk),
            .rst(rst),
            .en_memory(en_m),
            .i_prv_st_00(prv_st_00),
            .i_prv_st_10(prv_st_10),
            .i_prv_st_01(prv_st_01),
            .i_prv_st_11(prv_st_11),
            .o_bck_prv_st_00(bck_prv_st_00),
            .o_bck_prv_st_10(bck_prv_st_10),
            .o_bck_prv_st_01(bck_prv_st_01),
            .o_bck_prv_st_11(bck_prv_st_11));

traceback_output Tr1 (.clk(sys_clk),
                      .rst(rst),
                      .en_traceback(en_t),
                      .i_select_node(node),
                      .i_bck_prv_st_00(bck_prv_st_00),
                      .i_bck_prv_st_10(bck_prv_st_10),
                      .i_bck_prv_st_01(bck_prv_st_01),
                      .i_bck_prv_st_11(bck_prv_st_11),
                      .o_data(o_data),
                      .o_done(o_done));

endmodule
