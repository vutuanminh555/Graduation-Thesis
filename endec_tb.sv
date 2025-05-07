`include "param_def.sv"
`timescale 1ns / 1ps

module endec_tb(); 

logic clk, rst, en;
logic i_code_rate;
logic [`MAX_CONSTRAINT_LENGTH*`MAX_CODE_RATE - 1:0] i_gen_poly_flat;
logic [127:0] i_encoder_data_frame;
logic [383:0] i_decoder_data_frame; 
logic [`MAX_STATE_REG_NUM - 1:0] i_prv_encoder_state;

logic [383:0] o_encoder_data; 
logic o_encoder_done;
logic [127:0] o_decoder_data;
logic o_decoder_done;


endec_interface EI1 (   .sys_clk(clk),
                        .rst(rst),
                        .en(en),
                        .i_code_rate(i_code_rate),
                        .i_gen_poly_flat(i_gen_poly_flat),
                        .i_encoder_data_frame(i_encoder_data_frame), 
                        .i_decoder_data_frame(i_decoder_data_frame), 
                        .i_prv_encoder_state(i_prv_encoder_state),
                        .o_encoder_data(o_encoder_data),
                        .o_encoder_done(o_encoder_done),
                        .o_decoder_data(o_decoder_data), 
                        .o_decoder_done(o_decoder_done));

always #5 clk = ~clk;

initial 
begin
        clk = 0;
        en = 1;
        rst = 0;
        #16 rst = 1;
end

initial
begin
    i_code_rate = `CODE_RATE_3; 
    i_prv_encoder_state = '0; 

    //constraint length 9: 557, 663, 711
    i_gen_poly_flat[8:0] = 9'b111101101; // matlab polynomial is reversed
    i_gen_poly_flat[17:9] = 9'b110011011; 
    //i_gen_poly_flat[26:18] = 9'b000000000; // must be zeroed out for code rate 2
    i_gen_poly_flat[26:18] = 9'b100100111;

    i_decoder_data_frame = 384'b000000000111100110100000001010001010111101011011010001001101111010010111011100010011101000010101100011101101010110101100101000000100011100011000010101110101110100111000110000111100011110101100000010101110010101001001010100111011001000100100101000010101011000000100100101010110101110110100100101010011010100001001101000011100101101000111010011011101000111000010100101010100011010011000;
    i_encoder_data_frame = 128'b00011011001111001110111011011010100100001100101111011111011001011110011111101101101000001000101110110001011100100001111000110001;
end

always_ff @(posedge o_decoder_done)
begin
    $display("Decoder output data is: %b", o_decoder_data);
    $display("Encoder output data is: %b", o_encoder_data);
    $finish;
end

endmodule