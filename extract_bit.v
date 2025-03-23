`timescale 1ns / 1ps

module extract_bit(rst,clk,en_extract,i_data,o_Rx);

input rst,clk,en_extract;
input [15:0] i_data;

output reg [1:0] o_Rx;

reg [3:0] count;

always @ (posedge clk or negedge rst)  // extract 4 bit (radix-4) at a time
begin
    if (rst == 0)
    begin
        count <= 4'b1111; // MSB to LSB 
        o_Rx <= 2'b00;
    end
    else 
    begin
        if (en_extract == 1)
        begin
            o_Rx <= {i_data[count], i_data[count - 1]};
            count <= count - 2; // 1 - 2  = 15
        end
        else if(en_extract == 0)
        begin
            o_Rx <= 2'b00;
            count <= count;
        end
    end
end
endmodule
