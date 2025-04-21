`include "param_def.sv"
`timescale 1ns / 1ps

module control( clk, rst, en,
                i_mode_sel, i_sync,
                o_en_ce, o_en_s, o_en_bm, o_en_acs, o_en_m, o_en_t);

input logic clk, rst, en;
input logic i_mode_sel;
input logic i_sync;

output logic o_en_ce, o_en_s, o_en_bm, o_en_acs, o_en_m, o_en_t;

logic [2:0] state, nxt_state;
logic [2:0] mem_delay; 

localparam [2:0] s0  = 3'b000;
localparam [2:0] s1  = 3'b001;
localparam [2:0] s2  = 3'b010;
localparam [2:0] s3  = 3'b011;
localparam [2:0] s4  = 3'b100;
localparam [2:0] s5  = 3'b101;
localparam [2:0] s6  = 3'b110;
localparam [2:0] s7  = 3'b111;


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
            o_en_ce = 0; 
            o_en_s = 1;
            o_en_bm = 0; 
            o_en_acs = 0; 
            o_en_m = 0; 
            o_en_t = 0;
            nxt_state = s2;
        end
        
        s2: // decoder mode
        begin
            o_en_ce = 1; 
            o_en_s = 1;
            o_en_bm = 0; 
            o_en_acs = 0; 
            o_en_m = 0; 
            o_en_t = 0;
            if(i_mode_sel == `DECODE_MODE)
                nxt_state = s3;
            else
                nxt_state = s2;
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
