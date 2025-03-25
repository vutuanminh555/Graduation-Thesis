`timescale 1ns / 1ps

module extract_bit(rst,clk,en_extract,
                    i_data, 
                    o_Rx);

input rst,clk,en_extract;
input [59:0] i_data; // depends on traceback depth, choose between 120 and 60

output reg [3:0] o_Rx; // changed to 4 bit

reg [3:0] count;

always @ (posedge clk or negedge rst)  // extract 4 bit (radix-4) at a time
begin
    if (rst == 0)
    begin
        count <= 4'b1111; // MSB to LSB 
        o_Rx <= 4'b0000;
    end
    else 
    begin
        if (en_extract == 1)
        begin
            o_Rx <= {i_data[count], i_data[count - 3]}; // changed
            count <= count - 4; // 3 - 4 = 15
        end
        else if(en_extract == 0)
        begin
            o_Rx <= 4'b0000;
            count <= count;
        end
    end
end
endmodule
