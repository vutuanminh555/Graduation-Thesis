`include "param_def.sv"
`timescale 1ns / 1ps

module endec_tb(); 

logic clk, rst, en;
logic i_code_rate;
logic i_constr_len;
logic [`MAX_CONSTRAINT_LENGTH*`MAX_CODE_RATE - 1:0] i_gen_poly_flat;
logic i_mode_sel;
logic i_encoder_bit;
logic [383:0] i_decoder_data_frame; // pseudo code


logic [`MAX_CODE_RATE - 1:0] o_encoder_data;
logic o_encoder_done;
logic [127:0] o_decoder_data;
logic o_decoder_done;


// reg [5:0] count;
// reg [12:0] index;
// integer file_outputs;
// reg [15:0] in_ram [0:1024];



endec_wrapper EW1 ( .sys_clk(clk),
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

always #5 clk = ~clk;

initial 
begin
        // Initialization
        clk = 0;
        en = 1;
        rst = 0;
        i_encoder_bit = 0;
        #16 rst = 1;
end

initial
begin
    i_code_rate = `CODE_RATE_3; 
    i_constr_len = `CONSTR_LEN_9; 

    // i_gen_poly_flat[8:0] = 9'b000000111; // matlab polynomial is reversed
    // i_gen_poly_flat[17:9] = 9'b000000101; 
    // i_gen_poly_flat[26:18] = 9'b000000000;

    // constraint length 9: 557, 663, 711
    i_gen_poly_flat[8:0] = 9'b111101101; // matlab polynomial is reversed
    i_gen_poly_flat[17:9] = 9'b110011011; 
    i_gen_poly_flat[26:18] = 9'b100100111;

    i_mode_sel = `DECODE_MODE;
    //i_decoder_data_frame = 16'b0010100001100111;
    i_decoder_data_frame = 384'b111011101001110011111010000110001011010000000011101110111101010000101011001100010111100111010101001011100111001010110011001000001110111110010011100110000110000111110111001100011100100001100000011100010011010100011101010001011100010110000110101010111100111111010100111011011100011010110010111010101001110100110011110110001110010011110111111001110101010101010011101010100110010010010110;
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

// initial
// begin
//     index <= 1;
//     $readmemb("C:/Users/vutua/Downloads/Viterbi-Decoder-main/Viterbi-Decoder-main/input - Viterbi.txt", in_ram); 
//     file_outputs = $fopen("output.txt", "w");
//     i_decoder_data_frame = in_ram[0];
// end

// always @ (posedge o_decoder_done)
// begin
//     $display("Output data from input line %d is: %b\n", index, o_decoder_data);
//     $fwrite(file_outputs, "%b\n", o_decoder_data);
//     index <= index + 1;
//     i_decoder_data_frame <= in_ram [index];
//     rst = 0;
//     #1 rst = 1;

//     if(index >=1026)
//     begin
//         $fclose(file_outputs);
//         $finish;
//     end
// end

endmodule


// vsim -L unisims_ver endec.endec_tb endec.glbl