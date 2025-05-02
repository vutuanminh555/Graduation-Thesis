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
    i_prv_encoder_state = 8'b01010010; 

    //constraint length 9: 557, 663, 711
    i_gen_poly_flat[8:0] = 9'b111101101; // matlab polynomial is reversed
    i_gen_poly_flat[17:9] = 9'b110011011; 
    i_gen_poly_flat[26:18] = 9'b100100111;

    i_decoder_data_frame = 384'b111011101001001111001001011010010100100100001100111111010110100000100111111010100111100111010111101011110101100101101111001000000101000011001111111001011010000101100111001101000001010110100101001110011111101011011000010010101000000001001110010011001100101100110010010101010001001101010101111100000110011101100001100000001000101101110101100111011011100100001100111111010110100000011011;
    i_encoder_data_frame = 128'b00100100110110111111000010100111001011011100001101100100110100110110110100010000111100111000010010011101011100010010111001011111;
end

always_ff @(posedge o_decoder_done)
begin
    $display("Decoder output data is: %b", o_decoder_data);
    $display("Encoder output data is: %b", o_encoder_data);
    $finish;
end

endmodule





// `include "param_def.sv"
// `timescale 1ns / 1ps

// module endec_tb(); 

// // AXI Interface
// logic sys_clk, rst_n;

// logic [63:0] m_axis_tdata;
// logic m_axis_tlast;
// logic m_axis_tready;
// logic m_axis_tvalid;

// logic [63:0] s_axis_tdata;
// logic s_axis_tlast;
// logic s_axis_tready;
// logic s_axis_tvalid;

// // Data packet
// logic i_code_rate;
// logic [`MAX_CONSTRAINT_LENGTH*`MAX_CODE_RATE - 1:0] i_gen_poly_flat;
// logic [127:0] i_encoder_data_frame;
// logic [383:0] i_decoder_data_frame;
// logic [383:0] o_encoder_data;
// logic [127:0] o_decoder_data;

// logic [63:0] config_data;
// logic [575:0] tx_data;
// logic [511:0] rx_data;

// logic [9:0] tx_count;
// logic [8:0] rx_count;

// logic finish;

// assign config_data[26:0] = i_gen_poly_flat;
// assign config_data[27] = i_code_rate;
// assign tx_data[127:0] = i_encoder_data_frame;
// assign tx_data[511:128] = i_decoder_data_frame;
// assign tx_data[575:512] = config_data;
// assign o_encoder_data = rx_data[383:0];
// assign o_decoder_data = rx_data[511:384];
// always #5 sys_clk = ~sys_clk;

// initial 
// begin
//         // Initialization
//         i_code_rate = `CODE_RATE_3;
//         i_gen_poly_flat[8:0] = 9'b111101101; // matlab polynomial is reversed
//         i_gen_poly_flat[17:9] = 9'b110011011; 
//         i_gen_poly_flat[26:18] = 9'b100100111;
//         i_decoder_data_frame = 384'b111011101001001111001001011010010100100100001100111111010110100000100111111010100111100111010111101011110101100101101111001000000101000011001111111001011010000101100111001101000001010110100101001110011111101011011000010010101000000001001110010011001100101100110010010101010001001101010101111100000110011101100001100000001000101101110101100111011011100100001100111111010110100000011011;
//         i_encoder_data_frame = 128'b10010100111101111011100100110001111000011111101001100110000001001100101110011010111010100101110000101101111001001111011110111010;
//         sys_clk = 0;
//         rst_n = 0;
//         #16 rst_n = 1;
// end

// always_ff @(posedge sys_clk)
// begin
//     if(rst_n == 0)
//     begin
//         m_axis_tdata <= 0;
//         m_axis_tlast <= 0;
//         m_axis_tvalid <= 0;
//         s_axis_tready <= 0;
//         tx_count <= 575;
//         rx_count <= 511;
//     end
//     else
//     begin
//         // TX

//         m_axis_tvalid <= 1;
//         m_axis_tdata <= tx_data[tx_count -:64];
//         if(m_axis_tready == 1)
//             tx_count <= tx_count - 64;
//         if(tx_count == 575 || tx_count == 63)
//             m_axis_tlast <= 1;
//         if(m_axis_tlast == 1 && m_axis_tready == 1)
//             m_axis_tlast <= 0;

//         //RX
//         s_axis_tready <= 1;
//         if(s_axis_tvalid == 1)
//         begin
//             rx_data[rx_count -:64] <= s_axis_tdata;
//             rx_count <= rx_count - 64;
//         end
        
//     end
// end

// always_ff @(posedge sys_clk)
// begin
//     if(rst_n == 0)
//         finish <= 0;
//     else
//     begin
//         if(s_axis_tlast == 1)
//             finish <= 1;
//         if(finish == 1)
//         begin
//             $display("Encoder data is: %b", o_encoder_data);
//             $display("Decoder data is: %b", o_decoder_data);
//             $finish;
//         end
//     end
// end


// endec_interface EI1(.sys_clk(sys_clk),
//                     .rst_n(rst_n),
//                     .s_axis_tdata(m_axis_tdata),
//                     .s_axis_tlast(m_axis_tlast),
//                     .s_axis_tready(m_axis_tready),
//                     .s_axis_tvalid(m_axis_tvalid),
//                     .m_axis_tdata(s_axis_tdata),
//                     .m_axis_tlast(s_axis_tlast),
//                     .m_axis_tready(s_axis_tready),
//                     .m_axis_tvalid(s_axis_tvalid));

// endmodule 