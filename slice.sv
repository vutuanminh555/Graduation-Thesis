`include "param_def.sv"
`timescale 1ns / 1ps

module slice(   rst, clk, en_s, 
                i_code_rate ,i_data_frame, 
                o_rx, o_ood); 

input logic rst, clk, en_s;
input logic i_code_rate;
input logic [275:0] i_data_frame; // should be divided by 4 and 6, close to traceback_depth*sliced_input_num, choose 276

output logic [`SLICED_INPUT_NUM - 1:0] o_rx;
output logic o_ood; // detect end of file or file pointer  

logic [8:0] count; // pseudo code, need to change later

// pseudo code, need to implement later with PS
always @ (posedge clk or negedge rst)  // need to differentiate between k = 2 and k = 3
begin
    if (rst == 0)
    begin
        count <= 15; // for testing 
    end
    else 
    begin
        if (en_s == 1)
        begin 
            if(i_code_rate == `CODE_RATE_2)
            begin
                count <= count - 4;
                if(count == 3)
                count <= count;
            end
            else if(i_code_rate == `CODE_RATE_3) // not tested yet
            begin
                count <= count - 6;
                if(count == 5)
                count <= count;
            end
        end
        else
        begin
            count <= count;
        end
    end
end

always @(*)
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
            end
            else if(i_code_rate == `CODE_RATE_3)
            begin
                o_rx[2:0] = {i_data_frame[count - 2], i_data_frame[count - 1], i_data_frame[count]};
                o_rx[5:3] = {i_data_frame[count - 5], i_data_frame[count - 4], i_data_frame[count - 3]};
            end
            else
            begin
                o_rx = 0;
                o_ood = 0;
            end

            if(count == 3 || count == 5) // testing
            begin
                o_ood = 1; // simulating end of file, should turn on 2 cycle after for delay between modules 
            end
            else
            begin
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
