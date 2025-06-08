// `include "param_def.sv"
// `timescale 1ns / 1ps

// module endec_tb(); 

// logic clk, rst, en;
// logic i_code_rate;
// logic [`MAX_CONSTRAINT_LENGTH*`MAX_CODE_RATE - 1:0] i_gen_poly_flat;
// logic [191:0] i_encoder_data_frame;
// logic [383:0] i_decoder_data_frame; 
// logic [`MAX_STATE_REG_NUM - 1:0] i_prv_encoder_state;

// logic [575:0] o_encoder_data; 
// logic o_encoder_done;
// logic [127:0] o_decoder_data;
// logic o_decoder_done;


// endec_interface EI1 (   .sys_clk(clk),
//                         .rst(rst),
//                         .en(en),
//                         .i_code_rate(i_code_rate),
//                         .i_gen_poly_flat(i_gen_poly_flat),
//                         .i_encoder_data_frame(i_encoder_data_frame), 
//                         .i_decoder_data_frame(i_decoder_data_frame), 
//                         .i_prv_encoder_state(i_prv_encoder_state),
//                         .o_encoder_data(o_encoder_data),
//                         .o_encoder_done(o_encoder_done),
//                         .o_decoder_data(o_decoder_data), 
//                         .o_decoder_done(o_decoder_done));

// always #5 clk = ~clk;

// initial 
// begin
//         clk = 0;
//         en = 1;
//         rst = 0;
//         #16 rst = 1;
// end

// initial
// begin
//     i_code_rate = `CODE_RATE_3; 
//     i_prv_encoder_state = '0; 

//     //constraint length 9: 557, 663, 711
//     i_gen_poly_flat[8:0] = 9'b111101101; // matlab polynomial is reversed
//     i_gen_poly_flat[17:9] = 9'b110011011; 
//     //i_gen_poly_flat[26:18] = 9'b000000000; // must be zeroed out for code rate 2
//     i_gen_poly_flat[26:18] = 9'b100100111;

//     i_decoder_data_frame = 384'b000000111011010101000000100001000100001101110100000100000100000001111011111101011110000100011100001011110110100110100010000010101001011011011000101100000111000111001011010111110001110111001100001000100100010100011101010001011100010110000110101010111100111000001110010011011111110011010010011111110011111010010010001110011111010000110110000111001001100100111011011001011100111100101100;
//     i_encoder_data_frame = 320'b01001111000100100111000111000101001111011000111010011000010100000000000101011111000010111001011100101111111010100110111100011000000100011111000110001000100001010100111010111000101100000011101011110110100110100010101110110010101111001000001011010010011100101110001001010011110001010111001010010100100111101100001010101110;
// end

// always_ff @(posedge o_decoder_done)
// begin
//     $display("Decoder output data is: %b", o_decoder_data);
//     $display("Encoder output data is: %b", o_encoder_data);
//     $finish;
// end

// endmodule


`include "param_def.sv"
`timescale 1ns / 1ps

module endec_tb(); 

logic sys_clk, rst_n;

logic [63:0] m_axis_tdata;
logic m_axis_tlast;
logic m_axis_tready;
logic m_axis_tvalid;

logic [63:0] s_axis_tdata;
logic s_axis_tlast;
logic s_axis_tready;
logic s_axis_tvalid;

logic i_code_rate;
logic [`MAX_CONSTRAINT_LENGTH*`MAX_CODE_RATE - 1:0] i_gen_poly_flat;
logic [191:0] i_encoder_data_frame;
logic [383:0] i_decoder_data_frame; 
logic [`MAX_STATE_REG_NUM - 1:0] i_prv_encoder_state;

logic [575:0] o_encoder_data; 
logic [127:0] o_decoder_data;

logic [639:0] tx_data;
logic [703:0] rx_data;

logic [9:0] tx_count;
logic [9:0] rx_count;

logic rx_done;

logic delay;

assign tx_data[26:0]    = i_gen_poly_flat;
assign tx_data[27]      = i_code_rate;
assign tx_data[35:28]   = i_prv_encoder_state;
assign tx_data[255:64]  = i_encoder_data_frame;
assign tx_data[639:256] = i_decoder_data_frame;
assign o_encoder_data   = rx_data[575:0];
assign o_decoder_data   = rx_data[703:576];

endec_interface EI1 (   .sys_clk(sys_clk), 
                        .rst_n(rst_n),
                        .s_axis_tdata(m_axis_tdata),
                        .s_axis_tlast(m_axis_tlast),
                        .s_axis_tready(m_axis_tready),
                        .s_axis_tvalid(m_axis_tvalid),
                        .s_axis_aclk(sys_clk),
                        .m_axis_tdata(s_axis_tdata),
                        .m_axis_tlast(s_axis_tlast),
                        .m_axis_tready(s_axis_tready),
                        .m_axis_tvalid(s_axis_tvalid),
                        .m_axis_aclk(sys_clk));

always #5 sys_clk = ~sys_clk;

initial 
begin
        sys_clk = 0;
        rst_n = 0;
        #16 rst_n = 1;
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

    i_decoder_data_frame = 384'b000000111100001111101000011110011001010000110100001000110111110111110101010010011101111011011001110011101100100100110000110111100011001100010101000111111100001101001000110111011000100101100110000001110101010010110010101100001100010101111100010101000101011100100011010011010110000001001011000110100110001111110101101001110011101001100010111001111100100111110001011010000000100001111111;
    i_encoder_data_frame = 192'b110110011101101001111011111010100001101000110001110110001010101111100010101000100111101101001110100001010101110001011100010111000101000011101101000000001100010010000011100010001110101010011011;
end

always_ff @(posedge sys_clk)
begin
    if(rst_n == 0)
    begin
        // TX
        m_axis_tvalid <= 0;
        m_axis_tlast <= 0;
        tx_count <= 0;

        // RX
        s_axis_tready <= 0;
        rx_count <= 0;

        rx_done <= 0;

        delay <= 0;
    end
    else
    begin
        if(delay == 1)
            m_axis_tvalid <= 1;
        m_axis_tdata <= tx_data[tx_count +:64];
        if(m_axis_tready == 1)
        begin
            delay <= 1;
            if(delay == 1)
                tx_count <= tx_count + 64;
        end
        else
        begin
            tx_count <= 0;
            delay <= 0;
        end
        if(tx_count == 576)
        begin
            m_axis_tlast <= 1;
        end
        if(m_axis_tlast == 1)
        begin
            m_axis_tlast <= 0;
            m_axis_tvalid <= 0;
            delay <= 0;
        end

        // RX
        s_axis_tready <= 1;
        if(s_axis_tready == 1 && s_axis_tvalid == 1)
        begin
            rx_data[rx_count +:64] <= s_axis_tdata;
            rx_count <= rx_count + 64;
        end
        if(s_axis_tlast == 1)
        begin
            rx_done <= 1;
            rx_count <= 0;
        end
        if(rx_done == 1)
            rx_done <= 0;
    end
end

always_ff @(posedge sys_clk)
begin
    if(rx_done == 1)
    begin
        $display("Decoder output data is: %b", o_decoder_data);
        $display("Encoder output data is: %b", o_encoder_data);
        $finish;
    end
end

endmodule