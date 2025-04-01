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

input logic sys_clk, rst, en;
input logic i_code_rate;
input logic [1:0] i_constr_len; 
input logic [`MAX_CONSTRAINT_LENGTH - 1:0] i_gen_poly [`MAX_CODE_RATE];
input logic i_mode_sel;
input logic i_encoder_bit;
input logic [15:0] i_decoder_data_frame; // pseudo code

output logic [`MAX_CODE_RATE - 1:0] o_encoder_data;
output logic o_encoder_done;
output logic [`DATA_FRAME_LENGTH - 1:0] o_decoder_data;
output logic o_decoder_done;

logic ood;
logic cal_done;
logic td_full;

logic en_ce, en_s, en_bm, en_acs, en_td, en_t;

logic [`SLICED_INPUT_NUM - 1:0] rx;

logic [`MAX_CONSTRAINT_LENGTH - 1:0] bck_prv_st [`MAX_STATE_NUM];

// encoder


logic [15:0] mux_data; // combined data from encoder

logic [2:0] distance [`MAX_STATE_NUM][`RADIX]; // should use 2D vector

logic [`MAX_STATE_REG_NUM - 1:0] fwd_prv_st [`MAX_STATE_NUM];

logic [`MAX_STATE_REG_NUM - 1:0] sel_node;

control C1 (.clk(sys_clk),
            .rst(rst),
            .en(en),
            .i_ood(ood),
            .i_cal_done(cal_done),
            .i_td_full(td_full),
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
            .o_rx(rx),
            .o_ood(ood));

branch_metric BM1 ( .clk(sys_clk),
                    .rst(rst),
                    .en_bm(en_bm),
                    .i_rx(rx),
                    .i_mux(mux_data),
                    .o_dist(distance),
                    .o_cal_done(cal_done));

add_compare_select ACS1 (   .clk(sys_clk),
                            .rst(rst),
                            .en_acs(en_acs),
                            .i_dist(distance),
                            .o_fwd_prv_st(fwd_prv_st),
                            .o_sel_node(sel_node));

trellis_diagr TD1 ( .clk(sys_clk),
                    .rst(rst),
                    .en_td(en_td),
                    .i_fwd_prv_st(fwd_prv_st),
                    .o_bck_prv_st(bck_prv_st));

traceback T1 (  .clk(sys_clk),
                .rst(rst),
                .en_t(en_t),
                .i_sel_node(sel_node),
                .i_bck_prv_st(bck_prv_st),
                .o_decoder_data(o_decoder_data),
                .o_decoder_done(o_decoder_done),
                .o_td_full(td_full));

endmodule
