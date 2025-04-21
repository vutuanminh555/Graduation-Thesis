`include "param_def.sv"
`timescale 1ns / 1ps

module endec_tb(); 

logic clk, rst, en;
logic i_code_rate;
logic i_constr_len;
logic [`MAX_CONSTRAINT_LENGTH*`MAX_CODE_RATE - 1:0] i_gen_poly_flat;
logic i_mode_sel;
logic [127:0] i_encoder_data_frame;
logic [383:0] i_decoder_data_frame; 


logic [383:0] o_encoder_data;
logic o_encoder_done;
logic [127:0] o_decoder_data;
logic o_decoder_done;


endec_interface EI1 (   .sys_clk(clk),
                        .rst(rst),
                        .en(en),
                        .i_code_rate(i_code_rate),
                        .i_constr_len(i_constr_len),
                        .i_gen_poly_flat(i_gen_poly_flat),
                        .i_mode_sel(i_mode_sel),
                        .i_encoder_data_frame(i_encoder_data_frame), 
                        .i_decoder_data_frame(i_decoder_data_frame), 
                        .o_encoder_data(o_encoder_data),
                        .o_encoder_done(o_encoder_done),
                        .o_decoder_data(o_decoder_data), 
                        .o_decoder_done(o_decoder_done));

always #5 clk = ~clk;

initial 
begin
        // Initialization
        clk = 0;
        en = 1;
        rst = 0;
        //i_encoder_bit = 0;
        #16 rst = 1;
end

initial
begin
    i_code_rate = `CODE_RATE_3; 
    i_constr_len = `CONSTR_LEN_9; 

    // i_gen_poly_flat[8:0] = 9'b000000111; // matlab polynomial is reversed
    // i_gen_poly_flat[17:9] = 9'b000000101; 
    // i_gen_poly_flat[26:18] = 9'b000000000;

    //constraint length 9: 557, 663, 711
    i_gen_poly_flat[8:0] = 9'b111101101; // matlab polynomial is reversed
    i_gen_poly_flat[17:9] = 9'b110011011; 
    i_gen_poly_flat[26:18] = 9'b100100111;

    i_mode_sel = `ENCODE_MODE;
    i_encoder_data_frame = 128'b10011000010101000110101110000011000000111001111010001001111011101101010000011101110010011110010111111001101011000001011101010001;
    i_decoder_data_frame = 16'b0010100001100111;
    //i_decoder_data_frame = 384'b111011101001110011111010000110001011010000000011101110111101010000101011001100010111100111010101001011100111001010110011001000001110111110010011100110000110000111110111001100011100100001100000011100010011010100011101010001011100010110000110101010111100111111010100111011011100011010110010111010101001110100110011110110001110010011110111111001110101010101010011101010100110010010010110;
end

always_ff @(posedge o_decoder_done)
begin
    $display("Decoder output data is: %b", o_decoder_data);
    $finish;
end

always_ff @(posedge o_encoder_done)
begin
    $display("Encoder output data is: %b", o_encoder_data);
    $finish;
end

endmodule