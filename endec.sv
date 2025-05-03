`include "param_def.sv"
`timescale 1ns / 1ps

module endec(   sys_clk, rst, en,
                i_code_rate,
                i_gen_poly_flat,
                i_encoder_data_frame, 
                i_decoder_data_frame, 
                i_prv_encoder_state,
                o_encoder_data, o_encoder_done,
                o_decoder_data, o_decoder_done);
                //p_bram_addr, p_bram_din, p_bram_dout, p_bram_dout_reg, p_fwd_prv_st, p_count, p_state, p_nxt_state, p_mem_delay, p_sync, p_en_ce, p_en_s, p_en_acs, p_en_m, p_en_t);  

input logic sys_clk, rst, en;
input logic i_code_rate; 
input logic [`MAX_CONSTRAINT_LENGTH*`MAX_CODE_RATE - 1:0] i_gen_poly_flat;
input logic [127:0] i_encoder_data_frame;
input logic [383:0] i_decoder_data_frame; 
input logic [`MAX_STATE_REG_NUM - 1:0] i_prv_encoder_state;

output logic [383:0] o_encoder_data;
output logic o_encoder_done;
output logic [127:0] o_decoder_data; 
output logic o_decoder_done;

// Memory probe
// output logic [6:0] p_bram_addr;
// output logic [31:0] p_bram_din; // bram_din not working properly
// output logic [31:0] p_bram_dout;
// output logic [31:0] p_bram_dout_reg;

// // 
// output logic [`MAX_STATE_REG_NUM - 1:0] p_fwd_prv_st;

// output logic [6:0] p_count;

// output logic [2:0] p_state, p_nxt_state;
// output logic [4:0] p_mem_delay;

// output logic p_sync;
// output logic p_en_ce;
// output logic p_en_s;
// output logic p_en_acs;
// output logic p_en_m;
// output logic p_en_t;



logic [`MAX_CONSTRAINT_LENGTH - 1:0] i_gen_poly [`MAX_CODE_RATE];
generate
    genvar i;
    for (i = 0; i < `MAX_CODE_RATE; i = i + 1) 
    begin
        assign i_gen_poly[i] = i_gen_poly_flat[i*`MAX_CONSTRAINT_LENGTH +: `MAX_CONSTRAINT_LENGTH];
    end
endgenerate

logic sync;

logic en_ce, en_s, en_acs, en_m, en_t;

logic tx_data;

logic [`SLICED_INPUT_NUM - 1:0] rx_data;

logic [`MAX_STATE_REG_NUM - 1:0] bck_prv_st [`MAX_STATE_NUM];

logic [`SLICED_INPUT_NUM - 1:0] trans_data [`MAX_STATE_NUM][`RADIX];

logic [2:0] distance [`MAX_STATE_NUM][`RADIX];

logic [`MAX_STATE_REG_NUM - 1:0] fwd_prv_st [`MAX_STATE_NUM];

logic [`MAX_STATE_REG_NUM - 1:0] sel_node;



// assign p_fwd_prv_st = fwd_prv_st[0];


// assign p_sync = sync;
// assign p_en_ce = en_ce;
// assign p_en_s = en_s;
// assign p_en_acs = en_acs;
// assign p_en_m = en_m;
// assign p_en_t = en_t;

control C1 (.clk(sys_clk),
            .rst(rst),
            .en(en),
            .i_sync(sync),
            .o_en_ce(en_ce),
            .o_en_s(en_s),
            .o_en_acs(en_acs),
            .o_en_m(en_m),
            .o_en_t(en_t));
            // .p_state(p_state),
            // .p_nxt_state(p_nxt_state),
            // .p_mem_delay(p_mem_delay));

conv_encoder CE1(   .clk(sys_clk),
                    .rst(rst),
                    .en_ce(en_ce), 
                    .i_gen_poly(i_gen_poly),
                    .i_code_rate(i_code_rate),
                    .i_tx_data(tx_data), 
                    .i_prv_encoder_state(i_prv_encoder_state),
                    .o_trans_data(trans_data),
                    .o_encoder_data(o_encoder_data),
                    .o_encoder_done(o_encoder_done)); 

slice S1 (  .clk(sys_clk), 
            .rst(rst), 
            .en_s(en_s),
            .i_code_rate(i_code_rate),
            .i_encoder_data_frame(i_encoder_data_frame),
            .i_decoder_data_frame(i_decoder_data_frame),
            .o_tx_data(tx_data),
            .o_rx_data(rx_data));

branch_metric BM1 ( .clk(sys_clk),
                    .i_rx_data(rx_data),
                    .i_trans_data(trans_data),
                    .o_dist(distance));

add_compare_select ACS1 (   .clk(sys_clk),
                            .rst(rst),
                            .en_acs(en_acs),
                            .i_dist(distance),
                            .o_fwd_prv_st(fwd_prv_st),
                            .o_sel_node(sel_node));

memory M1 ( .clk(sys_clk),
            .rst(rst),
            .en_m(en_m),
            .i_fwd_prv_st(fwd_prv_st),
            .o_bck_prv_st(bck_prv_st),
            .o_sync(sync));
            // .p_bram_addr(p_bram_addr), // probe signal 
            // .p_bram_din(p_bram_din), 
            // .p_bram_dout(p_bram_dout), 
            // .p_bram_dout_reg(p_bram_dout_reg));

traceback T1 (  .clk(sys_clk),
                .rst(rst),
                .en_t(en_t),
                .i_sel_node(sel_node),
                .i_bck_prv_st(bck_prv_st),
                .o_decoder_data(o_decoder_data),
                .o_decoder_done(o_decoder_done));
                //.p_count(p_count));

endmodule
