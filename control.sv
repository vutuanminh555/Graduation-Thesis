`include "param_def.sv"
`timescale 1ns / 1ps

module control( clk, rst, en,
                i_mode_sel, i_ood, i_td_full,
                o_en_ce, o_en_s, o_en_bm, o_en_acs, o_en_td, o_en_t);

input logic clk, rst, en;
input logic i_mode_sel;
input logic i_ood;
input logic i_td_full;

output logic o_en_ce, o_en_s, o_en_bm, o_en_acs, o_en_td, o_en_t;

logic [2:0] state, nxt_state;

localparam [2:0] s0 = 000;
localparam [2:0] s1 = 001;
localparam [2:0] s2 = 010;
localparam [2:0] s3 = 011;

always_ff @(posedge clk) 
begin
    if (rst == 0)
    begin
        state <= s0;
    end
    else
    begin
        if (en == 1)
        begin
            state <= nxt_state;
        end
        else 
        begin
            state <= state; 
        end
    end
    
end

always_comb 
begin
    if(en == 1)
    begin
        case(state)
        s0: // reset 
        begin
            o_en_ce = 0; 
            o_en_s = 0; 
            o_en_bm = 0; 
            o_en_acs = 0; 
            o_en_td = 0; 
            o_en_t = 0; 
            if (i_mode_sel == `DECODE_MODE)
                nxt_state = s2;
            else // encode mode
                nxt_state = s1;
        end
        
        s1: // encoder mode
        begin
            o_en_ce = 1; 
            o_en_s = 0;
            o_en_bm = 0; 
            o_en_acs = 0; 
            o_en_td = 0; 
            o_en_t = 0;
            nxt_state = s1;
        end
        
        s2: // decoder mode, creating trellis diagram
        begin
            o_en_ce = 1; 
            o_en_s = 1;
            o_en_bm = 1; 
            o_en_acs = 1; 
            o_en_td = 1; 
            o_en_t = 0;
            if(i_ood == 1 || i_td_full == 1) 
            begin
                nxt_state = s3;
            end
            else
            begin
                nxt_state = s2;
            end
        end
        
        s3: // start tracing back
        begin
            o_en_ce = 0; 
            o_en_s = 0; 
            o_en_bm = 0; 
            o_en_acs = 0; 
            o_en_td = 1; 
            o_en_t = 1;
            nxt_state = s3;
        end

        default:
        begin
            o_en_ce = 0; 
            o_en_s = 0; 
            o_en_bm = 0; 
            o_en_acs = 0; 
            o_en_td = 0; 
            o_en_t = 0;
            nxt_state = s0;
        end
        endcase
    end
    else
    begin
        o_en_ce = 0; 
        o_en_s = 0; 
        o_en_bm = 0; 
        o_en_acs = 0; 
        o_en_td = 0; 
        o_en_t = 0;
        nxt_state = s0;
    end
end


endmodule
