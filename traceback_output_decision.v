`timescale 1ns / 1ps

module traceback_output(clk,rst,en_traceback,i_select_node,
                        i_bck_prv_st_00,i_bck_prv_st_10,i_bck_prv_st_01,i_bck_prv_st_11,
                        o_data,o_done);

input clk,rst,en_traceback;
input [1:0] i_select_node;
input [1:0] i_bck_prv_st_00,i_bck_prv_st_10,i_bck_prv_st_01,i_bck_prv_st_11; 

output reg [7:0] o_data;
output reg o_done;

reg [7:0] select_bit_out;
reg [3:0] count;
reg in_bit;

localparam [1:0] s0 = 2'b00;
localparam [1:0] s1 = 2'b01;
localparam [1:0] s2 = 2'b10;
localparam [1:0] s3 = 2'b11;

reg [1:0] select_node, nxt_select_node; 

always @ (posedge clk or negedge rst)
begin
    if (rst ==0)
    begin
        o_data <= 0;
        o_done <= 0;
        select_bit_out <= 8'b00000000;
        count <= 0;
        select_node <= s0;
    end
    else
    begin
        if (en_traceback == 1) 
        begin
            select_node <= nxt_select_node;
            count <= count + 1;   
        end
        else
        begin // giu nguyen trang thai truoc day 
            select_node <= i_select_node;
            count <= count;
            select_bit_out <= 8'b00000000;
            o_done <= 0;
        end

        if (count == 8 || count > 8) // da du 8 bit
        begin
            count <= 0;
            o_data <= select_bit_out;
            o_done <= 1;
            
        end
        else 
        begin
            select_bit_out[count] <= in_bit;
        end
    end
end

always @ (*) 
begin
    case (select_node) // FSM
    s0: // 00 
    begin  // xay ra khi reset
        if (i_bck_prv_st_00 == 2'b00) // xem lai chi so trong concat
        begin
            nxt_select_node = s0; // 00
        end
        else
        begin
            nxt_select_node = s1; // 01
        end
        in_bit = 0;
    end
    
    s1: // 01
    begin
        if (i_bck_prv_st_01 == 2'b10)
        begin
            nxt_select_node = s2; // 10
        end
        else
        begin
            nxt_select_node = s3; // 11
        end
        in_bit = 0;
    end
    
    s2: // 10
    begin
        if (i_bck_prv_st_10 == 2'b00)
        begin
            nxt_select_node = s0; // 00
        end
        else
        begin
            nxt_select_node = s1; // 01
        end
        in_bit = 1;
    end
    
    s3:
    begin
        if (i_bck_prv_st_11 == 2'b10)
        begin
            nxt_select_node = s2; // 10
        end
        else
        begin
            nxt_select_node = s3; // 11
        end
        in_bit = 1;
    end
    endcase

end

endmodule
