`include "param_def.sv"
`timescale 1ns / 1ps

module control( clk, rst, en,
                i_mode_sel, i_sync,
                o_en_ce, o_en_s, o_en_bm, o_en_acs, o_en_m, o_en_t);

input logic clk, rst, en;
input logic i_mode_sel;
input logic i_sync;

output logic o_en_ce, o_en_s, o_en_bm, o_en_acs, o_en_m, o_en_t;

logic [3:0] state, nxt_state;
logic [2:0] mem_delay; 

localparam [3:0] s0  = 4'b0000;
localparam [3:0] s1  = 4'b0001;
localparam [3:0] s2  = 4'b0010;
localparam [3:0] s3  = 4'b0011;
localparam [3:0] s4  = 4'b0100;
localparam [3:0] s5  = 4'b0101;
localparam [3:0] s6  = 4'b0110;
localparam [3:0] s7  = 4'b0111;


always_ff @(posedge clk) 
begin
    if (rst == 0)
    begin
        state <= s0;
        mem_delay <= 0;
    end
    else
    begin
        if (en == 1)
        begin
            state <= nxt_state;
            if(state == s6)
                mem_delay <= mem_delay + 1;
        end
        else 
        begin

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
            o_en_m = 0; 
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
            o_en_m = 0; 
            o_en_t = 0;
            nxt_state = s1;
        end
        
        s2: // decoder mode, slicing input data frame
        begin
            o_en_ce = 1; 
            o_en_s = 1;
            o_en_bm = 0; 
            o_en_acs = 0; 
            o_en_m = 0; 
            o_en_t = 0;
            nxt_state = s3;
        end

        s3: // calculate Hamming distance
        begin
            o_en_ce = 1; 
            o_en_s = 1;
            o_en_bm = 1; 
            o_en_acs = 0; 
            o_en_m = 0; 
            o_en_t = 0;
            nxt_state = s4;
        end

        s4: // creating trellis diagram
        begin
            o_en_ce = 1; 
            o_en_s = 1;
            o_en_bm = 1; 
            o_en_acs = 1; 
            o_en_m = 1; 
            o_en_t = 0;
            if(i_sync == 1) 
                nxt_state = s5;
            else
                nxt_state = s4;
        end

        s5: 
        begin
            o_en_ce = 0; 
            o_en_s = 0;
            o_en_bm = 0; 
            o_en_acs = 1; 
            o_en_m = 1; 
            o_en_t = 0;
            nxt_state = s6;
        end

        s6: // mem_delay
        begin
            o_en_ce = 0; 
            o_en_s = 0; 
            o_en_bm = 0; 
            o_en_acs = 0; 
            o_en_m = 1; 
            o_en_t = 0;
            if(mem_delay == 5)
                nxt_state = s7;
            else
                nxt_state = s6;
        end

        s7: // start tracing back
        begin
            o_en_ce = 0; 
            o_en_s = 0; 
            o_en_bm = 0; 
            o_en_acs = 0; 
            o_en_m = 1; 
            o_en_t = 1;
            nxt_state = s7;
        end

        default:
        begin
            o_en_ce = 0; 
            o_en_s = 0; 
            o_en_bm = 0; 
            o_en_acs = 0; 
            o_en_m = 0; 
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
        o_en_m = 0; 
        o_en_t = 0;
        nxt_state = s0;
    end
end


endmodule
