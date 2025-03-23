`timescale 1ns / 1ps

module branch_metric(rst,en_branch,i_Rx,HD);
input rst, en_branch;
input [3:0] i_Rx; // change to 4 bit 



//output reg [3:0] HD [3:0][3:0]; // [bit_size], [radix][state]

output reg [2:0] HD [15:0];

reg [1:0] pair_bit; 

integer i;
integer bit_pos;

always @ (*)  // need to use genvar variable and generate block 
if(rst == 0) // use integer and for loop
begin
    for(i = 0; i < 16; i = i + 1)
    begin
        HD[i] = 0;
    end
end
else
begin
        if (en_branch == 1) // modify for radix-4 (utilize radix-2)
        begin
            for(i = 0, bit_pos = 0; i < 2; i = i + 1)
            begin
                pair_bit = {i_Rx[3 - bit_pos], i_Rx[3 - bit_pos - 1]};
                bit_pos << 2; // = bit_pos*4: to use with HD 
                case (pair_bit)
                2'b00:
                begin
                    HD[bit_pos] = 2'd0; // 1st pair: 0 -> 7, 2nd pair: 8 -> 15
                    HD[bit_pos + 1] = 2'd2;
                    HD[bit_pos + 2] = 2'd1;
                    HD[bit_pos + 3] = 2'd1;
                    HD[bit_pos + 4] = 2'd2;
                    HD[bit_pos + 5] = 2'd0;
                    HD[bit_pos + 6] = 2'd1;
                    HD[bit_pos + 7] = 2'd1;                
                end
                
                2'b01:
                begin
                    HD[bit_pos] = 2'd1;
                    HD[bit_pos + 1] = 2'd1;
                    HD[bit_pos + 2] = 2'd2;
                    HD[bit_pos + 3] = 2'd0;
                    HD[bit_pos + 4] = 2'd1;
                    HD[bit_pos + 5] = 2'd1;
                    HD[bit_pos + 6] = 2'd0;
                    HD[bit_pos + 7] = 2'd2;
                end
                
                2'b10:
                begin
                    HD[bit_pos] = 2'd1;
                    HD[bit_pos + 1] = 2'd1;
                    HD[bit_pos + 2] = 2'd0;
                    HD[bit_pos + 3] = 2'd2;
                    HD[bit_pos + 4] = 2'd1;
                    HD[bit_pos + 5] = 2'd1;
                    HD[bit_pos + 6] = 2'd2;
                    HD[bit_pos + 7] = 2'd0;
                end
                
                2'b11:
                begin
                    HD[bit_pos] = 2'd2;
                    HD[bit_pos + 1] = 2'd0;
                    HD[bit_pos + 2] = 2'd1;
                    HD[bit_pos + 3] = 2'd1;
                    HD[bit_pos + 4] = 2'd0;
                    HD[bit_pos + 5] = 2'd2;
                    HD[bit_pos + 6] = 2'd1;
                    HD[bit_pos + 7] = 2'd1;
                end
                    
                default:
                begin
                    HD[bit_pos] = 2'd0;
                    HD[bit_pos + 1] = 2'd0;
                    HD[bit_pos + 2] = 2'd0;
                    HD[bit_pos + 3] = 2'd0;
                    HD[bit_pos + 4] = 2'd0;
                    HD[bit_pos + 5] = 2'd0;
                    HD[bit_pos + 6] = 2'd0;
                    HD[bit_pos + 7] = 2'd0;
                end
                
                endcase

                bit_pos = bit_pos + 2; // bit_pos = 0 and 2 
            end
        end
        else 
        begin // all output default to 0
            for(i = 0; i < 16; i = i + 1)
            begin
                HD[i] = 0;
            end
        end
end

endmodule
