`include "param_def.sv"
`timescale 1ns / 1ps

module control( clk, rst, en,
                o_en_ce, o_en_s, o_en_bm, o_en_acs, o_en_m, o_en_t);

input clk, rst, en;

output reg o_en_ce, o_en_s, o_en_bm, o_en_acs, o_en_m, o_en_t;

reg [2:0] state, nxt_state;
reg [3:0] count;

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
            count <= count + 1; 
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
        o_en_m = 0; 
        o_en_t = 0;
        nxt_state = s1;
    end
    
    s1:
    begin
        o_en_ce = 1; 
        o_en_s = 1; 
        o_en_bm = 1; 
        o_en_acs = 1; 
        o_en_m = 1; 
        o_en_t = 1;
        nxt_state = s1; // s2
    end
    
    s2:
    begin
        // en_extract=1; en_branch=1; en_add=1; en_memory=0; en_traceback=0;
        // nxt_state = s3;
    end
    
    s3:
    begin
        // en_extract=1; en_branch=1; en_add=1; en_memory=1; en_traceback=0;
        // if(count < 11)
        //     nxt_state = s3;
        // else 
        //     nxt_state = s4;
    end
    
    s4:
    begin
        // en_extract=0; en_branch=0; en_add=0; en_memory=1; en_traceback=1; // tat cac module khong dung den
        // nxt_state = s4;
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
