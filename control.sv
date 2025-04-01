`include "param_def.sv"
`timescale 1ns / 1ps

module control( clk, rst, en,
                i_ood, i_cal_done, i_td_full,
                o_en_ce, o_en_s, o_en_bm, o_en_acs, o_en_td, o_en_t);

input logic clk, rst, en;
input logic i_ood;
input logic i_cal_done;
input logic i_td_full;

output logic o_en_ce, o_en_s, o_en_bm, o_en_acs, o_en_td, o_en_t;

logic [2:0] state, nxt_state;
logic [1023:0] count;

localparam [2:0] s0 = 000; // reset 
localparam [2:0] s1 = 001; // extract
localparam [2:0] s2 = 010; // branch and add
localparam [2:0] s3 = 011; // memory
localparam [2:0] s4 = 100; // traceback

always @ (posedge clk or negedge rst) 
begin
    if (rst == 0)
    begin
        count <= 0;
        state <= s0;
    end
    else
    begin
        if (en == 1)
        begin
            if(state == s2)
            begin
            count <= count + 1; 
            end
            state <= nxt_state;
        end
        else 
        begin
            count <= count;
            state <= state; 
        end
    end
    
end

always @ (*) // optimize for radix-4
begin
    if(en == 1)
    begin
    case(state)
    s0:
    begin
        o_en_ce = 0; 
        o_en_s = 0; 
        o_en_bm = 0; 
        o_en_acs = 0; 
        o_en_td = 0; 
        o_en_t = 0;
        nxt_state = s1;
    end
    
    s1:
    begin
        o_en_ce = 1; 
        o_en_s = 0; 
        o_en_bm = 0; 
        o_en_acs = 0; 
        o_en_td = 0; 
        o_en_t = 0;
        nxt_state = s2;
    end
    
    s2:
    begin
        o_en_ce = 1; 
        o_en_s = 0; 
        o_en_bm = 1; 
        o_en_acs = 0; 
        o_en_td = 0; 
        o_en_t = 0;
        if(count == 1023)
        nxt_state = s3;
        else
        nxt_state = s2;
    end
    
    s3:
    begin
        o_en_ce = 1; 
        o_en_s = 1; 
        o_en_bm = 1; 
        o_en_acs = 0; 
        o_en_td = 0; 
        o_en_t = 0;
        nxt_state = s4;
    end
    
    s4:
    begin
        o_en_ce = 1; 
        o_en_s = 1; 
        o_en_bm = 1; 
        o_en_acs = 1; 
        o_en_td = 0; 
        o_en_t = 0;
        nxt_state = s4;
    end

    default:
    begin
        // en_extract=0; en_branch=0; en_add=0; en_memory=0; en_traceback=0;
        // nxt_state = s0;
    end
    endcase
    end
    else
    begin
        // en_extract=0; en_branch=0; en_add=0; en_memory=0; en_traceback=0;
        // nxt_state = s0;
    end
end


endmodule
