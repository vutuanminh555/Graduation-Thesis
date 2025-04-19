`include "param_def.sv"
`timescale 1ns / 1ps

module endec_wrapper (  sys_clk, rst, en,
                        i_code_rate, 
                        i_constr_len,
                        i_mode_sel,
                        i_gen_poly_flat,
                        i_encoder_bit,
                        i_decoder_data_frame,
                        o_encoder_data, o_encoder_done,
                        o_decoder_data, o_decoder_done);

input wire sys_clk, rst, en;

// Configuration inputs
input wire i_code_rate;
input wire i_constr_len;
input wire i_mode_sel;

// Generator polynomial inputs (flattened)
input wire [`MAX_CONSTRAINT_LENGTH*`MAX_CODE_RATE - 1:0] i_gen_poly_flat;

// Encoder interface
input wire i_encoder_bit;
output wire [`MAX_CODE_RATE - 1:0] o_encoder_data;
output wire o_encoder_done;

// Decoder interface
input wire [383:0] i_decoder_data_frame;
output wire [127:0] o_decoder_data;
output wire o_decoder_done;

// Instantiate the original module
endec E1 (
    .sys_clk(sys_clk),
    .rst(rst),
    .en(en),
    .i_code_rate(i_code_rate),
    .i_constr_len(i_constr_len),
    .i_gen_poly_flat(i_gen_poly_flat),
    .i_mode_sel(i_mode_sel),
    .i_encoder_bit(i_encoder_bit),
    .i_decoder_data_frame(i_decoder_data_frame),
    .o_encoder_data(o_encoder_data),
    .o_encoder_done(o_encoder_done),
    .o_decoder_data(o_decoder_data),
    .o_decoder_done(o_decoder_done));

endmodule