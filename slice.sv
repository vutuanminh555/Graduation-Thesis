`include "param_def.sv"
`timescale 1ns / 1ps

module slice(   clk, rst, en_s,
                i_code_rate,
                i_encoder_data_frame, i_decoder_data_frame, 
                o_tx_data, o_rx_data); 

input logic clk, rst, en_s;
input logic i_code_rate; 
input logic [127:0] i_encoder_data_frame;
input logic [383:0] i_decoder_data_frame;

output logic o_tx_data;
output logic [`SLICED_INPUT_NUM - 1:0] o_rx_data;

logic [6:0] count_tx;
logic [8:0] count_rx;

logic rx_toggle;

always_ff @(posedge clk) // count_tx and count_rx
begin
    if (rst == 0)
    begin
        count_tx <= 127;
        if(i_code_rate == `CODE_RATE_2)
            count_rx <= 255;
        else if(i_code_rate == `CODE_RATE_3)
            count_rx <= 383; 
        rx_toggle <= 0;
    end
    else if (en_s == 1)
    begin
        count_tx <= count_tx - 1;
        rx_toggle <= ~rx_toggle;
        if(i_code_rate == `CODE_RATE_2)
        begin
            if(rx_toggle == 1)
            count_rx <= count_rx - 4;
        end
        else if(i_code_rate == `CODE_RATE_3) 
        begin
            if(rx_toggle == 1)
            count_rx <= count_rx - 6;
        end
    end
end



always_ff @(posedge clk) // o_tx_data and o_rx_data 
begin
    if(rst == 0)
    begin
        o_tx_data <= 0;
        o_rx_data <= 0;
    end
    else
    begin
        o_tx_data <= i_encoder_data_frame[count_tx];
        if(i_code_rate == `CODE_RATE_2)
        begin
            o_rx_data[1:0] <= {i_decoder_data_frame[count_rx - 1], i_decoder_data_frame[count_rx]};
            o_rx_data[4:3] <= {i_decoder_data_frame[count_rx - 3], i_decoder_data_frame[count_rx - 2]};
        end
        else if(i_code_rate == `CODE_RATE_3)
        begin
            o_rx_data[2:0] = {i_decoder_data_frame[count_rx - 2], i_decoder_data_frame[count_rx - 1], i_decoder_data_frame[count_rx]};
            o_rx_data[5:3] = {i_decoder_data_frame[count_rx - 5], i_decoder_data_frame[count_rx - 4], i_decoder_data_frame[count_rx - 3]};
        end
    end
end

endmodule
