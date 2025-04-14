`include "param_def.sv"
`timescale 1ns / 1ps

module slice(   clk, rst, en_s, // use dual port BRAM with AXI DMA
                i_code_rate, i_data_frame, 
                o_rx, o_ood); 

input logic clk, rst, en_s;
input logic i_code_rate; 
input logic [383:0] i_data_frame; // should be divided by 4 and 6, close to 7*constraint length*sliced_input_num, choose 384

output logic [`SLICED_INPUT_NUM - 1:0] o_rx;
output logic o_ood; // detect end of file or file pointer  

logic [8:0] count; // pseudo code, need to change later

// pseudo code, need to implement later with PS 
always_ff @(posedge clk)
begin
    if (rst == 0)
    begin
        count <= 384; 
    end
    else 
    begin
        if (en_s == 1)
        begin 
            if(i_code_rate == `CODE_RATE_2)
            begin
                if(count == 3)
                count <= count;
                else
                count <= count - 4;
            end
            else if(i_code_rate == `CODE_RATE_3) 
            begin
                if(count == 5)
                count <= count;
                else
                count <= count - 6;
            end
        end
        else
        begin
            count <= count;
        end
    end
end

always_comb // o_rx
begin
    if(rst == 0)
    begin
        o_rx = 0;
        o_ood = 0;
    end
    else
    begin
        if(en_s == 1)
        begin
            if(i_code_rate == `CODE_RATE_2)
            begin
                o_rx[1:0] = {i_data_frame[count - 1], i_data_frame[count]};
                o_rx[4:3] = {i_data_frame[count - 3], i_data_frame[count - 2]};
                o_rx[2] = 0;
                o_rx[5] = 0;
                if(count == 3)
                o_ood = 1;
                else
                o_ood = 0;
            end
            else if(i_code_rate == `CODE_RATE_3)
            begin
                o_rx[2:0] = {i_data_frame[count - 2], i_data_frame[count - 1], i_data_frame[count]};
                o_rx[5:3] = {i_data_frame[count - 5], i_data_frame[count - 4], i_data_frame[count - 3]};
                if(count == 5)
                o_ood = 1;
                else
                o_ood = 0;
            end
            else
            begin
                o_rx = 0;
                o_ood = 0;
            end
        end
        else
        begin
            o_rx = 0;
            o_ood = 0;
        end
    end
end

endmodule
