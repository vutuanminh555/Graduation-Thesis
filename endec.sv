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


wire en_c, en_e, en_b, en_a, en_m, en_t;

wire [`RADIX - 1:0] rx;

wire [`MAX_CONSTRAINT_LENGTH - 1:0] bck_prv_st [`MAX_STATE_NUM - 1:0];

// encoder


wire [31:0] mux_data; // combined data from encoder

wire [2:0] distance [`MAX_TRANSITION_NUM - 1:0];

wire [`MAX_SHIFT_REG_NUM - 1:0] fwd_nxt_st [`MAX_STATE_NUM - 1:0];

wire [`MAX_SHIFT_REG_NUM - 1:0] sel_node;

control C1 (.clk(sys_clk),
            .rst(rst),
            .en(en),
            .o_en_c(en_c),
            .o_en_e(en_e),
            .o_en_b(en_b),
            .o_en_a(en_a),
            .o_en_m(en_m),
            .o_en_t(en_t));

conv_encoder CE1(   .clk(sys_clk),
                    .rst(rst),
                    .en_c(en_c),
                    .i_code_rate(i_code_rate),
                    .i_constr_len(i_constr_len),
                    .i_gen_poly(i_gen_poly),
                    .i_encoder_bit(i_encoder_bit),
                    .i_mode_sel(i_mode_sel),
                    .o_mux(mux_data),
                    .o_encoder_data(o_encoder_data),
                    .o_encoder_done(o_encoder_done));

slice S1 (  .rst(rst),
            .clk(sys_clk),
            .en_e(en_e),
            .i_data_frame(i_decoder_data_frame),
            .o_rx(rx));

branch_metric BM1 ( .clk(sys_clk),
                    .rst(rst),
                    .en_b(en_b),
                    .i_rx(rx),
                    .i_mux(mux_data),
                    .o_distance(distance));

add_compare_select ACS1 (   .clk(sys_clk),
                            .rst(rst),
                            .en_a(en_a),
                            .i_distance(distance),
                            .o_fwd_nxt_st(fwd_nxt_st),
                            .o_sel_node(sel_node));

trellis_diagr TD1 ( .clk(sys_clk),
                    .rst(rst),
                    .en_m(en_m),
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
