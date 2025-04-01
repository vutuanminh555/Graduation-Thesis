`include "param_def.sv"
`timescale 1ns / 1ps

module slice(   rst, clk, en_s, 
                i_code_rate ,i_data_frame, 
                o_rx,
                o_ood); // need to sync with bm to only output data after finish calculating all possible bm

input logic rst, clk, en_s;
input logic i_code_rate;
input logic [15:0] i_data_frame; // should be divided by 4 and 6, close to traceback_depth*sliced_input_num, choose 276

output logic [`SLICED_INPUT_NUM - 1:0] o_rx;
output logic o_ood; // detect end of file or file pointer  

logic [3:0] count;

// pseudo code, need to implement later with PS
always @ (posedge clk or negedge rst)  // need to differentiate between k = 2 and k = 3
begin
    if (rst == 0)
    begin
        o_rx <= 0;
        count <= 4'b1111;
        o_ood <= 0;
    end
    else 
    begin
        if (en_s == 1)
        begin 
            if(i_code_rate == `CODE_RATE_2)
            begin
                o_rx[1:0] <= {i_data_frame[count - 1], i_data_frame[count]};
                o_rx[4:3] <= {i_data_frame[count - 3], i_data_frame[count - 2]};
                count <= count - 4;
            end
            else if(i_code_rate == `CODE_RATE_3) // not tested yet
            begin
                o_rx[2:0] <= {i_data_frame[count], i_data_frame[count - 2]};
                o_rx[5:3] <= {i_data_frame[count - 3], i_data_frame[count - 5]};
                count <= count - 6;
            end
            if(count == 3) // testing
            begin
                o_ood <= 1; // simulating end of file
            end
            else
            begin
                o_rx <= 0;
            end
        end
        else
        begin
            o_rx <= 0;
            count <= count;
        end
    end
end

endmodule
