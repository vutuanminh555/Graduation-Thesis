`include "param_def.sv"
`timescale 1ns / 1ps

module endec_tb(); 

logic clk, rst, en; // need changing
logic i_code_rate;
logic [1:0] i_constr_len;
logic [`MAX_CONSTRAINT_LENGTH - 1:0] i_gen_poly [`MAX_CODE_RATE - 1:0];
logic i_mode_sel;
logic i_encoder_bit;
logic [`TRACEBACK_DEPTH - 1:0] i_decoder_data_frame;


logic [`MAX_CODE_RATE - 1:0] o_encoder_data;
logic o_encoder_done;
logic [`DATA_FRAME_LENGTH - 1:0] o_decoder_data;
logic o_decoder_done;

endec E1 (  .sys_clk(clk), // add code rate. constraint length. poly input 
            .rst(rst),
            .en(en),
            .i_code_rate(i_code_rate),
            .i_constr_len(i_constr_len),
            .i_gen_poly(i_gen_poly),
            .i_mode_sel(i_mode_sel),
            .i_encoder_bit(i_encoder_bit), 
            .i_decoder_data_frame(i_decoder_data_frame), 
            .o_encoder_data(o_encoder_data),
            .o_encoder_done(o_encoder_done),
            .o_decoder_data(o_decoder_data), 
            .o_decoder_done(o_decoder_done));

always #5 clk = ~clk;

initial 
begin
        // Khởi tạo tín hiệu
        clk = 0;
        rst = 1;
        en = 1;
        
        // Reset
        #10 rst = 0;
        #1 rst = 1;
        
end

initial
begin
    i_code_rate = `CODE_RATE_2;
    i_constr_len = 1;
    i_gen_poly[0] = 9'b000000111;
    i_gen_poly[1] = 9'b000000101;
    i_gen_poly[2] = 9'b000000000;
    i_mode_sel = `DECODE_MODE;
    i_encoder_bit = 1'b0;
    i_decoder_data_frame = 16'b1101101010100110;
end

endmodule
