`include "param_def.sv"
`timescale 1ns / 1ps

module endec(   sys_clk, rst, en,
                i_code_rate,
                i_constr_len,
                i_gen_poly,
                i_mode_sel,
                i_encoder_bit, 
                i_decoder_data_frame, 
                o_encoder_data, o_encoder_done,
                o_decoder_data, o_decoder_done);  

input sys_clk, rst, en;
input i_code_rate;
input [1:0] i_constr_len; 
input [`MAX_CONSTRAINT_LENGTH - 1:0] i_gen_poly [`MAX_CODE_RATE - 1:0];
input i_mode_sel;
input i_encoder_bit;
input [`TRACEBACK_DEPTH - 1:0] i_decoder_data_frame;

output [`MAX_CODE_RATE - 1:0] o_encoder_data;
output o_encoder_done;
output [`DATA_FRAME_LENGTH - 1:0] o_decoder_data;
output o_decoder_done;


logic en_ce, en_s, en_bm, en_acs, en_td, en_t;

logic [`SLICED_INPUT_NUM - 1:0] rx;

logic [`MAX_CONSTRAINT_LENGTH - 1:0] bck_prv_st [`MAX_STATE_NUM - 1:0];

// encoder


logic [15:0] mux_data; // combined data from encoder

logic [2:0] distance [`MAX_STATE_REG_NUM - 1:0][`DECODE_BIT_NUM - 1:0]; // should use 2D vector

logic [`MAX_STATE_REG_NUM - 1:0] fwd_nxt_st [`MAX_STATE_NUM - 1:0];

logic [`MAX_STATE_REG_NUM - 1:0] sel_node;

control C1 (.clk(sys_clk),
            .rst(rst),
            .en(en),
            .o_en_ce(en_ce),
            .o_en_s(en_s),
            .o_en_bm(en_bm),
            .o_en_acs(en_acs),
            .o_en_td(en_td),
            .o_en_t(en_t));

conv_encoder CE1(   .clk(sys_clk),
                    .rst(rst),
                    .en_ce(en_ce),
                    .i_code_rate(i_code_rate), // is it necessary? 
                    .i_constr_len(i_constr_len),
                    .i_gen_poly(i_gen_poly),
                    .i_encoder_bit(i_encoder_bit),
                    .i_mode_sel(i_mode_sel),
                    .o_mux(mux_data),
                    .o_encoder_data(o_encoder_data),
                    .o_encoder_done(o_encoder_done));

slice S1 (  .rst(rst),
            .clk(sys_clk),
            .en_s(en_s),
            .i_code_rate(i_code_rate),
            .i_data_frame(i_decoder_data_frame),
            .o_rx(rx));

branch_metric BM1 ( .clk(sys_clk),
                    .rst(rst),
                    .en_bm(en_bm),
                    .i_rx(rx),
                    .i_mux(mux_data),
                    .o_dist(distance));

add_compare_select ACS1 (   .clk(sys_clk),
                            .rst(rst),
                            .en_acs(en_acs),
                            .i_dist(distance),
                            .o_fwd_nxt_st(fwd_nxt_st),
                            .o_sel_node(sel_node));

trellis_diagr TD1 ( .clk(sys_clk),
            .rst(rst),
            .en_td(en_td),
            .i_fwd_nxt_st(fwd_nxt_st),
            .o_bck_prv_st(bck_prv_st));

traceback T1 (  .clk(sys_clk),
                .rst(rst),
                .en_t(en_t),
                .i_sel_node(sel_node),
                .i_bck_prv_st(bck_prv_st),
                .o_decoder_data(o_decoder_data),
                .o_decoder_done(o_decoder_done));

endmodule
