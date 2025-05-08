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

    i_decoder_data_frame = 384'b000000111011010101000000100001000100001101110100000100000100000001111011111101011110000100011100001011110110100110100010000010101001011011011000101100000111000111001011010111110001110111001100001000100100010100011101010001011100010110000110101010111100111000001110010011011111110011010010011111110011111010010010001110011111010000110110000111001001100100111011011001011100111100101100;
    i_encoder_data_frame = 128'b00101010111101110000110101101011111100000110011111010011011111101101010000011101110011001010011100000100110000111000101101001111;
end

always_ff @(posedge o_decoder_done)
begin
    $display("Decoder output data is: %b", o_decoder_data);
    $display("Encoder output data is: %b", o_encoder_data);
    $finish;
end

endmodule