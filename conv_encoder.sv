`include "param_def.sv"
`timescale 1ns/1ps

module conv_encoder(clk, rst, en_ce,
                    i_gen_poly, i_code_rate, i_tx_data, i_mode_sel,
                    o_trans_data, o_encoder_data, o_encoder_done); 

input logic clk, rst, en_ce;
input logic [`MAX_CONSTRAINT_LENGTH - 1:0] i_gen_poly [`MAX_CODE_RATE]; 
input logic i_code_rate;
input logic i_tx_data;
input logic i_mode_sel; 

output logic [`SLICED_INPUT_NUM - 1:0] o_trans_data [`MAX_STATE_NUM][`RADIX]; // 6 bit output
output logic [383:0] o_encoder_data; 
output logic o_encoder_done; 

logic [8:0] count_tx;
logic [`MAX_STATE_REG_NUM - 1:0] encoder_state; 

always_ff @(posedge clk) // output all 1024 transitions to branch metric modules to calculate
begin
    if(rst == 0)
    begin
        count_tx <= 383;
        o_encoder_data <= 0;
        o_encoder_done <= 0;
        encoder_state <= 0;
        for(int i = 0; i < `MAX_STATE_NUM; i++)
        begin
            for(int j = 0; j < `RADIX; j++)
            begin
                o_trans_data[i][j] <= 0;
            end
        end
    end
    else
    begin
        if(en_ce == 1)
        begin
            if(i_mode_sel == `ENCODE_MODE) 
            begin
                if(i_code_rate == `CODE_RATE_2)
                begin
                    count_tx <= count_tx - 2;
                    {o_encoder_data[count_tx - 1], o_encoder_data[count_tx]} <= encode(i_gen_poly, {encoder_state, i_tx_data});
                    if(count_tx == 129)
                        o_encoder_done <= 1;
                end
                else if(i_code_rate == `CODE_RATE_3)
                begin
                    count_tx <= count_tx - 3;
                    {o_encoder_data[count_tx - 2], o_encoder_data[count_tx - 1], o_encoder_data[count_tx]} <= encode(i_gen_poly, {encoder_state, i_tx_data});
                    if(count_tx == 2)
                        o_encoder_done <= 1;
                end
                encoder_state <= {encoder_state[`MAX_STATE_REG_NUM - 2:0], i_tx_data}; // shift and change state
            end

            else if(i_mode_sel == `DECODE_MODE)
            begin
                for(int i = 0; i < `MAX_STATE_NUM; i++)
                begin
                    for(int j = 0; j < `RADIX; j++)
                    begin
                        o_trans_data[i][j] <= {encode(i_gen_poly, {i[`MAX_STATE_REG_NUM - 2:0], j[0], j[1]}), 
                                                encode(i_gen_poly, {i[`MAX_STATE_REG_NUM - 1:0], j[0]})}; // second data, first data
                    end
                end
            end
        end
        else
        begin
            o_encoder_data <= 0;
            for(int i = 0; i < `MAX_STATE_NUM; i++)
            begin
                for(int j = 0; j < `RADIX; j++)
                begin
                    o_trans_data[i][j] <= 0;
                end
            end
        end
    end
end

function logic [`MAX_CODE_RATE - 1:0] encode (  input logic [`MAX_CONSTRAINT_LENGTH - 1:0] gen_poly [`MAX_CODE_RATE], 
                                                input logic [`MAX_CONSTRAINT_LENGTH - 1:0] mux_state); // state combine with input
    automatic logic [`MAX_CODE_RATE - 1:0] encoded_data;
    encoded_data = 0;
    for(int i = 0; i < `MAX_CODE_RATE; i++) 
    begin
        for(int k = 0; k < `MAX_CONSTRAINT_LENGTH; k++) 
        begin
            encoded_data[i] ^= (mux_state[k] & gen_poly[i][k]); // flip bit if state[k] == 1 and gen_poly[i][k] == 1
        end
    end
    return encoded_data;
endfunction

endmodule
