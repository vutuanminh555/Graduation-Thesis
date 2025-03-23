`timescale 1ns / 1ps

module branch_metric(rst,en_branch,i_Rx,HD);
input rst, en_branch;
input [3:0] i_Rx; // change to 4 bit 

generate
    genvar i;

endgenerate


output reg [3:0] HD [3:0][3:0]; // [bit_size], [radix][state]

always @ (*)  // need to use genvar variable and generate block 
if(rst == 0) // use integer and for loop
begin
    HD1 = 0;
    HD2 = 0;
    HD3 = 0;
    HD4 = 0;
    HD5 = 0;
    HD6 = 0;
    HD7 = 0;
    HD8 = 0;
end
else
begin
        if (en_branch == 1) // modify for radix-4 
        begin
            case (i_Rx)
            2'b00:
            begin
                HD1 = 2'd0;
                HD2 = 2'd2;
                HD3 = 2'd1;
                HD4 = 2'd1;
                HD5 = 2'd2;
                HD6 = 2'd0;
                HD7 = 2'd1;
                HD8 = 2'd1;
            end
            
            2'b01:
            begin
                HD1 = 2'd1;
                HD2 = 2'd1;
                HD3 = 2'd2;
                HD4 = 2'd0;
                HD5 = 2'd1;
                HD6 = 2'd1;
                HD7 = 2'd0;
                HD8 = 2'd2;
            end
            
            2'b10:
            begin
                HD1 = 2'd1;
                HD2 = 2'd1;
                HD3 = 2'd0;
                HD4 = 2'd2;
                HD5 = 2'd1;
                HD6 = 2'd1;
                HD7 = 2'd2;
                HD8 = 2'd0;
            end
            
            2'b11:
            begin
                HD1 = 2'd2;
                HD2 = 2'd0;
                HD3 = 2'd1;
                HD4 = 2'd1;
                HD5 = 2'd0;
                HD6 = 2'd2;
                HD7 = 2'd1;
                HD8 = 2'd1;
            end
                
            endcase
        end
        else 
        begin
            HD1 = 0;
            HD2 = 0;
            HD3 = 0;
            HD4 = 0;
            HD5 = 0;
            HD6 = 0;
            HD7 = 0;
            HD8 = 0;
    end
end

endmodule
