`include "param_def.sv"
`timescale 1ns / 1ps

module endec_wrapper (sys_clk, rst, en,
                    i_code_rate, 
                    i_constr_len,
                    i_decision_type,
                    i_mode_sel,
                    i_gen_poly_flat,
                    i_encoder_bit,
                    i_decoder_data_frame,
                    o_encoder_data, o_encoder_done,
                    o_decoder_data, o_decoder_done);

input wire sys_clk,
input wire rst,
input wire en,

// Configuration inputs
input wire i_code_rate,
input wire [1:0] i_constr_len,
input wire i_decision_type,
input wire i_mode_sel,

// Generator polynomial inputs (flattened)
input wire [(`MAX_CONSTRAINT_LENGTH - 1)*(`MAX_CODE_RATE) - 1:0] i_gen_poly_flat,

// Encoder interface
input wire i_encoder_bit,
output wire [`MAX_CODE_RATE - 1:0] o_encoder_data,
output wire o_encoder_done,

// Decoder interface
input wire [383:0] i_decoder_data_frame,
output wire [191:0] o_decoder_data,
output wire o_decoder_done

// Reconstruct the gen_poly array from flattened input
wire [`MAX_CONSTRAINT_LENGTH - 1:0] i_gen_poly [0:`MAX_CODE_RATE - 1];

generate
    genvar i;
    for (i = 0; i < `MAX_CODE_RATE; i = i + 1) begin : gen_poly_reconstruct
        assign i_gen_poly[i] = i_gen_poly_flat[i*`MAX_CONSTRAINT_LENGTH +: `MAX_CONSTRAINT_LENGTH];
    end
endgenerate

// Internal signals
wire ood;
wire td_full;
wire td_empty;

wire en_ce, en_s, en_bm, en_acs, en_td, en_t;

wire [`SLICED_INPUT_NUM*`QUANTIZE_BIT_NUM - 1:0] rx;

wire [`MAX_STATE_REG_NUM - 1:0] bck_prv_st [0:`MAX_STATE_NUM - 1];

wire [`SLICED_INPUT_NUM - 1:0] trans_data [0:`MAX_STATE_NUM - 1][0:`RADIX - 1];

wire [8:0] distance [0:`MAX_STATE_NUM - 1][0:`RADIX - 1];

wire [`MAX_STATE_REG_NUM - 1:0] fwd_prv_st [0:`MAX_STATE_NUM - 1];

wire [`MAX_STATE_REG_NUM - 1:0] sel_node;

// Instantiate the original module
endec endec_inst (
    .sys_clk(sys_clk),
    .rst(rst),
    .en(en),
    .i_code_rate(i_code_rate),
    .i_constr_len(i_constr_len),
    .i_decision_type(i_decision_type),
    .i_gen_poly(i_gen_poly),
    .i_mode_sel(i_mode_sel),
    .i_encoder_bit(i_encoder_bit),
    .i_decoder_data_frame(i_decoder_data_frame),
    .o_encoder_data(o_encoder_data),
    .o_encoder_done(o_encoder_done),
    .o_decoder_data(o_decoder_data),
    .o_decoder_done(o_decoder_done),
    
    // Internal connections
    .ood(ood),
    .td_full(td_full),
    .td_empty(td_empty),
    .en_ce(en_ce),
    .en_s(en_s),
    .en_bm(en_bm),
    .en_acs(en_acs),
    .en_td(en_td),
    .en_t(en_t),
    .rx(rx),
    .bck_prv_st(bck_prv_st),
    .trans_data(trans_data),
    .distance(distance),
    .fwd_prv_st(fwd_prv_st),
    .sel_node(sel_node)
);

endmodule