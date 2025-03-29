`include "param_def.sv"
`timescale 1ns/1ps

module conv_encoder(clk, rst, en_ce,
                    i_code_rate, i_constr_len, i_gen_poly, i_encoder_bit, i_mode_sel,
                    o_mux, o_encoder_data, o_encoder_done); // encode and output all possible output for each transition

input logic clk, rst, en_ce;
input logic i_code_rate;
input logic [1:0] i_constr_len;
input logic [`MAX_CONSTRAINT_LENGTH - 1:0] i_gen_poly [`MAX_CODE_RATE - 1:0]; // max K = 9, max code rate = 3
input logic i_encoder_bit; // 1 bit at a time, radix-4 not related
input logic i_mode_sel; 

output logic [15:0] o_mux; // 2 bit input, 8 bit current state, 6 bit output
output logic [`MAX_CODE_RATE - 1:0] o_encoder_data; // encoded data per bit
output logic o_encoder_done;

// temp variables for decode mode using radix-4
logic [`MAX_CODE_RATE - 1:0] d_o_first_data; // first to second state
logic [`MAX_CODE_RATE - 1:0] d_o_second_data; // second to third state 

// temp variable for encode mode
logic [`MAX_STATE_REG_NUM - 1:0] e_state; // state doesnt count input bit
logic [`MAX_CODE_RATE - 1:0] encoder_data;

// variables to use with decode mode value scanning
logic [1:0] d_pair_input_value; // all possible input
logic [`MAX_STATE_REG_NUM - 1:0] d_state_value;  // all possible state for given K  



always @(posedge clk or negedge rst) // write memory on clock edge 
begin
    if(rst == 0) // default all output and temp signal to 0
    begin
        o_mux <= 0;
        o_encoder_data <= 0;
        o_encoder_done <= 0;
        d_state_value <= 0;
        d_pair_input_value <= 0;
        e_state <= 0;
    end
    else
    begin
        if(en_ce == 1)
        begin 
            if(i_mode_sel == `DECODE_MODE)  
            begin
                d_pair_input_value <= d_pair_input_value + 1; // 1 state need 4 input value
                if(d_state_value == `MAX_STATE_NUM - 1) // control through state value, not input value
                begin
                    //d_state_value <= d_state_value; // reach maximum possible value
                end
                else if(d_pair_input_value == `RADIX - 1)
                begin
                    d_state_value <= d_state_value + 1; // only increase when have gone through all 4 possible inputs
                end
                o_mux <= {d_pair_input_value, d_state_value, d_o_second_data, d_o_first_data};
            end
            else if(i_mode_sel == `ENCODE_MODE) 
            begin
                o_encoder_data <= encoder_data;
                e_state <= {e_state[`MAX_STATE_REG_NUM - 2:0], i_encoder_bit}; // shift and change state
            end 
            else 
            begin

            end  
        end
        else 
        begin
            o_mux <= 0;
            o_encoder_data <= 0;
            o_encoder_done <= 0;
        end
    end
end

always @(*) // read and calculate data from memory
begin 
    if(rst == 0 )
    begin
        d_o_first_data = 0;
        d_o_second_data = 0;
        e_state = 0;
        encoder_data = 0;
    end
    else
    begin
        if(en_ce == 1) 
        begin 
            if(i_mode_sel == `DECODE_MODE)  // need to shift right 2 times and 2 next state
            begin
                d_o_first_data = encode(i_gen_poly, {d_state_value, d_pair_input_value[0]}); // calculate the first output data
                d_o_second_data = encode(i_gen_poly, {d_state_value[`MAX_STATE_REG_NUM - 2:0], d_pair_input_value[0], d_pair_input_value[1]}); // calculate the second output data
            end
            else if(i_mode_sel == `ENCODE_MODE) 
            begin
                encoder_data = encode(i_gen_poly, {e_state, i_encoder_bit});
            end 
            else 
            begin

            end  
        end
        else 
        begin

        end
    end
end

function automatic logic[`MAX_CODE_RATE - 1:0] encode ( input logic [`MAX_CONSTRAINT_LENGTH - 1:0] gen_poly [`MAX_CODE_RATE - 1:0], // max k outputs 
                                                        input logic [`MAX_CONSTRAINT_LENGTH - 1:0] mux_state); // state combine with input
    logic [`MAX_CODE_RATE - 1:0] encoded_data;
    encoded_data = 0;
    for(int i = 0; i < `MAX_CODE_RATE; i++) // calculate all possible outputs
    begin
        for(int k = 0; k < `MAX_CONSTRAINT_LENGTH; k++) // scanning all reg block in polynomials
        begin
            if(gen_poly[i][k] == 1) // output i use k block in state 
            begin
                encoded_data[i] ^= mux_state[k]; // flip bit if state[k] == 1
            end
            else
            begin

            end
        end
    end
    return encoded_data;
endfunction

endmodule
