`timescale 1ns/1ps

module convolutional_encoder(clk, rst, en_conv,
                            polynomial, i_bit, mode_select,
                            mux);

input clk, rst, en_conv;
input [7:0] polynomial; // max K = 9
input [1:0] i_bit; // 2 bits at a time, radix-4
input mode_select; 

output [31:0] mux; // 2 bit input, 8 bit current state, 8 bit next state 1, 8 bit next state 2, 6 bit output

//temp signal
// the following signal depend on code rate and constraint length
reg poly_lim;
reg code_word_lim;
reg st_lim;
reg nxt_st_lim;

// memory to hold calculated value
reg [31:0] mux_mem [255:0]; // divided by current state

// integer to use with loop
integer pot_i_bit; // all potential input for decoder
integer cs_len; // constraint length 


always @(posedge clk or negedge rst) // should utilize combinational logic to generate output for maximum speed
begin
    if(rst == 0) // default all output and temp signal to 0
    begin
        mux <= 0;
        for(i = 0; i < 256; i = i + 1)begin
            mux_mem[i] <= 0;
        end
    end
    else
    begin
        if(en_conv == 1) // write value to output and memory only when finished calculating
        begin // need to shift right 2 times and 2 next state
                // need to create 
        end
        else // output signal = 0, temp signal remain the same
        begin
            mux <= 0;
            // temp signal implicitly remain the same
        end
    end
end


endmodule
