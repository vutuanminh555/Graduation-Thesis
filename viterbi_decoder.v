`timescale 1ns / 1ps

module viterbi_decoder(sys_clk,rst,en,i_data,o_data,o_done); // need to change wire width 

input sys_clk,rst,en;
input [59:0] i_data;

output [19:0] o_data;
output o_done;

wire en_c,en_e,en_b,en_a,en_m,en_t;

wire [1:0] rx;

wire [1:0] bck_prv_st [255:0];

// encoder
wire [7:0] gen_poly;
wire i_bit;
wire mode_sel;

wire [31:0] mux;

wire [2:0] dist [1023:0];

wire [7:0] prv_st [255:0];

wire [7:0] sel_node;

control C1 (.clk(sys_clk),
            .rst(rst),
            .en(en),
            .en_c(en_c),
            .en_e(en_e),
            .en_b(en_b),
            .en_a(en_a),
            .en_m(en_m),
            .en_t(en_t));

convolutional_encoder Ce1(.clk(sys_clk),
                        .rst(rst),
                        .en_c(en_c),
                        .gen_poly(gen_poly),
                        .i_bit(i_bit),
                        .mode_sel(mode_sel),
                        .o_mux(mux));

extract_bit Ex1 (   .rst(rst),
                    .clk(sys_clk),
                    .en_e(en_e),
                    .i_data(i_data),
                    .o_Rx(rx));

branch_metric Br1 (.clk(sys_clk),
                    .rst(rst),
                    .en_b(en_b),
                    .i_Rx(rx),
                    .i_mux(mux),
                    .o_dist(dist));

add_compare_select Add1 (   .clk(sys_clk),
                            .rst(rst),
                            .en_a(en_a),
                            .i_dist(dist),
                            .o_prv_st(prv_st),
                            .o_sel_node(sel_node));

memory M1 (.clk(sys_clk),
            .rst(rst),
            .en_m(en_m),
            .i_prv_st(prv_st),
            .o_bck_prv_st(bck_prv_st));

traceback_output Tr1 (  .clk(sys_clk),
                        .rst(rst),
                        .en_t(en_t),
                        .i_sel_node(sel_node),
                        .i_bck_prv_st(bck_prv_st),
                        .o_data(o_data),
                        .o_done(o_done));

endmodule
