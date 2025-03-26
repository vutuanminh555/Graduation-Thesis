`include "param_def.sv"
`timescale 1ns/1ps

module conv_encoder(clk, rst, en_ce,
                    i_code_rate, i_constr_len, i_gen_poly, i_encoder_bit, i_mode_sel,
                    o_mux, o_encoder_data, o_encoder_done); // need to calculate distance

input logic clk, rst, en_ce;
input logic i_code_rate;
input logic [1:0] i_constr_len;
input logic [`MAX_CONSTRAINT_LENGTH - 1:0] i_gen_poly [`MAX_CODE_RATE - 1:0]; // max K = 9, max code rate = 3
input logic i_encoder_bit; // 1 bit at a time, radix-4 not related
input logic i_mode_sel; 

output logic [31:0] o_mux; // 2 bit input, 8 bit current state, 8 bit next state 1, 8 bit next state 2, 6 bit output
output logic [`MAX_CODE_RATE - 1:0] o_encoder_data; // encoded data per bit
output logic o_encoder_done;

// temp variables for decode mode using radix-4
logic [`MAX_CONSTRAINT_LENGTH - 2:0] first_state = 0; // state doesnt count input bit
logic [`MAX_CONSTRAINT_LENGTH - 2:0] second_state = 0;
logic [`MAX_CONSTRAINT_LENGTH - 2:0] third_state = 0;
logic [`MAX_CODE_RATE - 1:0] o_first_data; // first to second state
logic [`MAX_CODE_RATE - 1:0] o_second_data; // second to third state
logic [1:0] pair_input; // hardcoded, related to radix 

// temp variable for encode mode
logic [`MAX_CONSTRAINT_LENGTH - 2:0] state = 0; // state doesnt count input bit
logic [`MAX_CODE_RATE - 1:0] encoder_data;

// integer to use with loop
integer pair_input_value; // all possible input
integer state_value;  // all possible state for given K  



always @(posedge clk or negedge rst) // write memory on clock edge 
begin
    if(rst == 0) // default all output and temp signal to 0
    begin
        o_mux <= 0;
        o_encoder_data <= 0;
        o_encoder_done <= 0;
        //first_state <= 0;
    end
    else
    begin
        if(en_ce == 1)
        begin 
            if(i_mode_sel == `DECODE_MODE)  
            begin
                for(state_value = 0; state_value < `MAX_STATE_NUM; state_value = state_value + 1) // scan through every possible state
                begin
                    for(pair_input_value = 0; pair_input_value < `RADIX; pair_input_value = pair_input_value + 1) // scan through all possible input with each state
                    begin  // for each iteration need to calculate 
                        //first_state <= state_value; // reset the cycle
                        o_mux <= {pair_input, first_state, second_state, third_state, o_second_data, o_first_data};
                    end
                end 
            end
            else if(i_mode_sel == `ENCODE_MODE) 
            begin
                //o_encoder_data <= encode(i_gen_poly, {state, i_encoder_bit}); // MSB to LSB
                o_encoder_data <= encoder_data;
                state <= {state[`MAX_CONSTRAINT_LENGTH - 3:0], i_encoder_bit}; // shift and change state
            end 
            else 
            begin

            end  
        end
        else // en_ce != 0
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
        pair_input = 0;
        o_first_data = 0;
        first_state = 0;
        second_state = 0;
        o_second_data = 0;
        third_state = 0;

        encoder_data = 0;
    end
    else
    begin
        if(en_ce == 1) 
        begin 
            if(i_mode_sel == `DECODE_MODE)  // need to shift right 2 times and 2 next state
            begin
                pair_input = 2'(pair_input_value); // get pair_input_value

                first_state = state_value;
                o_first_data = encode(i_gen_poly, {first_state, pair_input[0]}); // calculate the first output data
                second_state = {first_state[`MAX_CONSTRAINT_LENGTH - 3:0], pair_input[0]}; // combine with first bit to create new state, prepare for second bit calculation

                o_second_data = encode(i_gen_poly, {second_state, pair_input[1]}); // calculate the second output data
                third_state = {second_state[`MAX_CONSTRAINT_LENGTH - 3:0], pair_input[1]}; // calculate third state for mux output
            end
            else if(i_mode_sel == `ENCODE_MODE) 
            begin
                encoder_data = encode(i_gen_poly, {state, i_encoder_bit});
            end 
            else 
            begin

            end  
        end
        else // en_ce != 0
        begin
            // o_mux <= 0;
            // o_encoder_data <= 0;
            // o_encoder_done <= 0;
        end
    end
end

function logic[`MAX_CODE_RATE - 1:0] encode (   input logic [`MAX_CONSTRAINT_LENGTH - 1:0] gen_poly [`MAX_CODE_RATE - 1:0], // max k outputs 
                                                input logic [`MAX_CONSTRAINT_LENGTH - 1:0] mux_state); // state combine with input
    static logic[`MAX_CODE_RATE - 1:0] encoded_data = 0;
    integer i;
    integer k;
    for(i = 0; i < `MAX_CODE_RATE; i = i + 1) // calculate all possible outputs
    begin
        for(k = 0; k < `MAX_CONSTRAINT_LENGTH; k = k + 1) // scanning all reg block in polynomials
        begin
            if(gen_poly[k] == 1) // output use k block in state 
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
