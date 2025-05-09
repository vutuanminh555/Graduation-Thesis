`include "param_def.sv"
`timescale 1ns/1ps

module conv_encoder(clk, rst, en_ce,
                    i_gen_poly, i_code_rate, i_tx_data, i_prv_encoder_state,
                    o_trans_data, o_encoder_data, o_encoder_done); 

input logic clk, rst, en_ce;
input logic [`MAX_CONSTRAINT_LENGTH - 1:0] i_gen_poly [`MAX_CODE_RATE]; 
input logic i_code_rate;
input logic [1:0] i_tx_data;
input logic [`MAX_STATE_REG_NUM - 1:0] i_prv_encoder_state;

output logic [`SLICED_INPUT_NUM - 1:0] o_trans_data [`MAX_STATE_NUM][`RADIX]; // 6 bit output
output logic [959:0] o_encoder_data; 
output logic o_encoder_done; 

logic [9:0] count_tx;
logic [`MAX_STATE_REG_NUM - 1:0] encoder_state; 
logic slice_delay;

always_ff @(posedge clk) // output all 1024 transitions to branch metric modules to calculate
begin
    if(rst == 0)
    begin
        count_tx <= 959; 
        o_encoder_data <= 0;
        o_encoder_done <= 0;
        encoder_state <= i_prv_encoder_state;
        slice_delay <= 0;
    end
    else if(en_ce == 1) 
    begin
        slice_delay <= 1;
        if(o_encoder_done == 0 && slice_delay == 1)
        begin
            if(i_code_rate == `CODE_RATE_2)
            begin
                count_tx <= count_tx - 4;
                {o_encoder_data[count_tx - 1], o_encoder_data[count_tx    ]}   <= encode(i_gen_poly, {encoder_state, i_tx_data[0]});
                {o_encoder_data[count_tx - 3], o_encoder_data[count_tx - 2]}   <= encode(i_gen_poly, {encoder_state[`MAX_STATE_REG_NUM - 2:0], i_tx_data[0], i_tx_data[1]});
            end
            else if(i_code_rate == `CODE_RATE_3)
            begin
                count_tx <= count_tx - 6; 
                {o_encoder_data[count_tx - 2],  o_encoder_data[count_tx - 1],  o_encoder_data[count_tx    ]}    <= encode(i_gen_poly, {encoder_state, i_tx_data[0]});
                {o_encoder_data[count_tx - 5],  o_encoder_data[count_tx - 4],  o_encoder_data[count_tx - 3]}    <= encode(i_gen_poly, {encoder_state[`MAX_STATE_REG_NUM - 2:0], i_tx_data[0], i_tx_data[1]});
            end
            encoder_state <= {encoder_state[`MAX_STATE_REG_NUM - 3:0], i_tx_data[0], i_tx_data[1]}; // shift and change state
        end
        if((count_tx == 323 && i_code_rate == `CODE_RATE_2) || (count_tx == 5 && i_code_rate == `CODE_RATE_3)) 
            o_encoder_done <= 1;

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