`include "param_def.sv"
`timescale 1ns/1ps

module conv_encoder(clk, rst, en_ce,
                    i_gen_poly, i_encoder_bit, i_mode_sel,
                    o_trans_data, o_encoder_data, o_encoder_done); // encode and output all possible output for each transition

input logic clk, rst, en_ce;
input logic [`MAX_CONSTRAINT_LENGTH - 1:0] i_gen_poly [`MAX_CODE_RATE]; 
input logic i_encoder_bit;
input logic i_mode_sel; 

output logic [`SLICED_INPUT_NUM - 1:0] o_trans_data [`MAX_STATE_NUM][`RADIX]; // 6 bit output
output logic [`MAX_CODE_RATE - 1:0] o_encoder_data; // encoded data per bit [`MAX_CODE_RATE - 1:0]
output logic o_encoder_done; // need to implement later

// temp variable for encode mode
logic [`MAX_STATE_REG_NUM - 1:0] e_state; // state doesnt count input bit

always_ff @(posedge clk) // output all 1024 transitions to branch metric modules to calculate
begin
    if(rst == 0)
    begin
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
            for(int i = 0; i < `MAX_STATE_NUM; i++)
            begin
                for(int j = 0; j < `RADIX; j++)
                begin
                    o_trans_data[i][j] <= {encode(i_gen_poly, {i[`MAX_STATE_REG_NUM - 2:0], j[0], j[1]}), 
                                            encode(i_gen_poly, {i[`MAX_STATE_REG_NUM - 1:0], j[0]})}; // second data, first data
                end
            end
        end
        else
        begin
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

always_ff @(posedge clk) // write memory 
begin
    if(rst == 0)
    begin
        e_state <= 0;
    end
    else
    begin
        if(en_ce == 1)
        begin 
            e_state <= {e_state[`MAX_STATE_REG_NUM - 2:0], i_encoder_bit}; // shift and change state
        end
        else 
        begin

        end
    end
end

always_ff @(posedge clk) // read and calculate data from memory
begin 
    if(rst == 0 )
    begin
        o_encoder_data <= 0;
        o_encoder_done <= 0;
    end
    else
    begin
        if(en_ce == 1) 
        begin 
            if(i_mode_sel == `DECODE_MODE)  
            begin
                o_encoder_data <= 0; 
            end
            else if(i_mode_sel == `ENCODE_MODE) 
            begin
                o_encoder_data <= encode(i_gen_poly, {e_state, i_encoder_bit}); 
            end 
            else 
            begin
                o_encoder_data <= 0;
            end  
        end
        else 
        begin
            o_encoder_data <= 0;
            o_encoder_done <= 0;
        end
    end
end

function logic [`MAX_CODE_RATE - 1:0] encode (  input logic [`MAX_CONSTRAINT_LENGTH - 1:0] gen_poly [`MAX_CODE_RATE], // max k outputs 
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
