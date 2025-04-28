`include "param_def.sv"
`timescale 1ns / 1ps

module endec_tb(); 

logic clk, rst, en;
logic i_code_rate;
logic i_constr_len;
logic [`MAX_CONSTRAINT_LENGTH*`MAX_CODE_RATE - 1:0] i_gen_poly_flat;
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
        #16 rst = 1;
end

initial
begin
    i_code_rate = `CODE_RATE_2; 
    i_constr_len = `CONSTR_LEN_3; 

    i_gen_poly_flat[8:0] = 9'b000000111; // matlab polynomial is reversed
    i_gen_poly_flat[17:9] = 9'b000000101; 
    i_gen_poly_flat[26:18] = 9'b000000000;

    //constraint length 9: 557, 663, 711
    // i_gen_poly_flat[8:0] = 9'b111101101; // matlab polynomial is reversed
    // i_gen_poly_flat[17:9] = 9'b110011011; 
    // i_gen_poly_flat[26:18] = 9'b100100111;

    i_encoder_data_frame = 128'b10011000010101000110101110000011000000111001111010001001111011101101010000011101110010011110010111111001101011000001011101010001;
    i_decoder_data_frame = 256'b1110111110000110011100111000100010000110100100101111010100011010101001111110110011011001111110111110000110010001101010011111101100001101011111100001011100111011000000001101010010111101010010000110101001111110111101100111001110000101110000001110111110111110;
end

always_ff @(posedge o_decoder_done)
begin
    $display("Decoder output data is: %b", o_decoder_data);
    //$display("Encoder output data is: %b", o_encoder_data);
    $finish;
end

endmodule





// `include "param_def.sv"
// `timescale 1ns / 1ps

// module endec_tb(); 

// // AXI Interface
// logic sys_clk, rst_n;

// logic [31:0] axi_tx_tdata;
// logic axi_tx_tlast;
// logic axi_tx_tready;
// logic axi_tx_tvalid;

// logic [31:0] axi_rx_tdata;
// logic axi_rx_tlast;
// logic axi_rx_tready;
// logic axi_rx_tvalid;

// // Data packet
// logic i_code_rate;
// logic i_constr_len;
// logic i_mode_sel;
// logic [`MAX_CONSTRAINT_LENGTH*`MAX_CODE_RATE - 1:0] i_gen_poly_flat;
// logic [127:0] i_encoder_data_frame;
// logic [383:0] i_decoder_data_frame;


// endec_interface EI1   ( .sys_clk(sys_clk), 
//                         .rst_n(rst_n),
//                         .axi_rx_tdata(axi_tx_tdata),
//                         .axi_rx_tlast(axi_tx_tlast),
//                         .axi_rx_tready(axi_tx_tready),
//                         .axi_rx_tvalid(axi_tx_tvalid),
//                         .axi_tx_tdata(axi_rx_tdata),
//                         .axi_tx_tlast(axi_rx_tlast),
//                         .axi_tx_tready(axi_rx_tready),
//                         .axi_tx_tvalid(axi_rx_tvalid));

// always #5 sys_clk = ~sys_clk;

// initial 
// begin
//         // Initialization
//         i_code_rate = `CODE_RATE_2;
//         i_constr_len = `CONSTR_LEN_3;
//         i_mode_sel = `DECODE_MODE;
//         i_gen_poly_flat[8:0] = 9'b000000111; 
//         i_gen_poly_flat[17:9] = 9'b000000101; 
//         i_gen_poly_flat[26:18] = 9'b000000000;
//         i_decoder_data_frame = 16'b1101101010100110;
//         i_encoder_data_frame = 128'b10011000010101000110101110000011000000111001111010001001111011101101010000011101110010011110010111111001101011000001011101010001;
//         sys_clk = 0;
//         rst_n = 0;
//         //i_encoder_bit = 0;
//         #16 rst_n = 1;
// end

// initial
// begin
//     // axi_tx_tdata <= 
//     // axi_tx_tlast <=
//     // axi_tx_tvalid <=

//     // axi_rx_tready <= 
// end

// always_ff @(posedge sys_clk)
// begin
//     if(rst_n == 0)
//     begin
//         axi_tx_tdata <= 0;
//         axi_tx_tlast <= 0;
//         axi_tx_tvalid <= 0;
//         axi_rx_tready <= 0;
//     end
//     else
//     begin
//         if(axi_tx_tready == 1) // receiver is ready
//         begin

//         end
//     end
// end

// endmodule 