//`include"xpm_memory.sv"
`include "param_def.sv"
`timescale 1ns / 1ps

module memory(  clk, rst, en_m, 
                i_fwd_prv_st,
                o_bck_prv_st, o_sync);

input logic clk, rst, en_m;
input logic [`MAX_STATE_REG_NUM - 1:0] i_fwd_prv_st [`MAX_STATE_NUM];

output logic [`MAX_STATE_REG_NUM - 1:0] o_bck_prv_st [`MAX_STATE_NUM];
output logic o_sync;

logic [6:0] depth; 
logic wrk_mode;
logic mem_delay;

logic wen;

// Parameters for BRAM configuration
localparam BRAM_DATA_WIDTH = 32; 
localparam BRAM_ADDR_WIDTH = 7; // with traceback depth = 64
localparam NUM_BRAMS = 32;

// BRAM interface signals
logic [BRAM_ADDR_WIDTH - 1:0] bram_addr [2] [NUM_BRAMS]; 
logic [BRAM_DATA_WIDTH - 1:0] bram_din [2] [NUM_BRAMS]; 
logic [BRAM_DATA_WIDTH - 1:0] bram_dout [2] [NUM_BRAMS]; 
logic [BRAM_DATA_WIDTH - 1:0] bram_dout_reg [2] [NUM_BRAMS];

logic sbiterra [NUM_BRAMS];
logic sbiterrb [NUM_BRAMS];
logic dbiterra [NUM_BRAMS];
logic dbiterrb [NUM_BRAMS];

// Generate 32 True Dual-Port BRAMs using XPM macro
generate
genvar i;
for (i = 0; i < NUM_BRAMS; i = i + 1) 
begin
    xpm_memory_tdpram #(
        .ADDR_WIDTH_A(BRAM_ADDR_WIDTH),
        .ADDR_WIDTH_B(BRAM_ADDR_WIDTH),
        .BYTE_WRITE_WIDTH_A(BRAM_DATA_WIDTH), // not using byte write
        .BYTE_WRITE_WIDTH_B(BRAM_DATA_WIDTH),
        .CLOCKING_MODE("common_clock"),
        .MEMORY_INIT_FILE("none"),
        .MEMORY_INIT_PARAM("0"),
        .MEMORY_OPTIMIZATION("false"), 
        .MEMORY_PRIMITIVE("block"),
        .MEMORY_SIZE(BRAM_DATA_WIDTH * `TRACEBACK_DEPTH * 2), // use both port A and B for writing and reading
        .MESSAGE_CONTROL(0),
        .READ_DATA_WIDTH_A(BRAM_DATA_WIDTH),
        .READ_DATA_WIDTH_B(BRAM_DATA_WIDTH),
        .READ_LATENCY_A(2),
        .READ_LATENCY_B(2),
        .READ_RESET_VALUE_A("1"), // default read value when read data is invalid
        .READ_RESET_VALUE_B("2"),
        .RST_MODE_A("SYNC"),
        .RST_MODE_B("SYNC"),
        .SIM_ASSERT_CHK(0), // simulation debug
        .USE_EMBEDDED_CONSTRAINT(0), 
        .USE_MEM_INIT(0),
        .WAKEUP_TIME("disable_sleep"),
        .WRITE_DATA_WIDTH_A(BRAM_DATA_WIDTH),
        .WRITE_DATA_WIDTH_B(BRAM_DATA_WIDTH),
        .WRITE_MODE_A("NO_CHANGE"), // written data doesnt affect read data
        .WRITE_MODE_B("NO_CHANGE")
    ) td_mem (
        .douta(bram_dout[0][i]), // data out
        .doutb(bram_dout[1][i]),
        .addra(bram_addr[0][i]), 
        .addrb(bram_addr[1][i]),
        .clka(clk),
        .clkb(clk),
        .dina(bram_din[0][i]), // data in
        .dinb(bram_din[1][i]),
        .ena(en_m), // enable signal for all instances
        .enb(en_m),
        .injectdbiterra(1'b0), // simulate double bit error for ECC
        .injectdbiterrb(1'b0),
        .injectsbiterra(1'b0), // simulate single bit error for ECC
        .injectsbiterrb(1'b0),
        .sbiterra(sbiterra[i]), // flag detect error bits
        .sbiterrb(sbiterrb[i]),
        .dbiterra(dbiterra[i]), 
        .dbiterrb(dbiterrb[i]),
        .regcea(1'b1), // update data based on address 
        .regceb(1'b1),
        .rsta(!rst), // active high
        .rstb(!rst),
        .sleep(1'b0), // sleep mode
        .wea(en_m && (wrk_mode == 0)), // write enable signal
        .web(en_m && (wrk_mode == 0)) 
    );
end
endgenerate

always_ff @(posedge clk)  // pipeline reg output
begin
    for(int i = 0; i < NUM_BRAMS; i++)
    begin
        bram_dout_reg[0][i] <= bram_dout[0][i];
        bram_dout_reg[1][i] <= bram_dout[1][i];
    end
end

always_ff @(posedge clk) // Input and output data
begin
    if (rst == 0) 
    begin
        depth <= 0;
        wen <= 0;
        // for (int i = 0; i < `MAX_STATE_NUM; i++) 
        // begin
        //     o_bck_prv_st[i] <= 0;
        // end
        for (int i = 0; i < NUM_BRAMS; i++) 
        begin
        //     bram_din[0][i] <= 0;
        //     bram_din[1][i] <= 0;
            bram_addr[0][i] <= depth;
            bram_addr[1][i] <= depth + 1;
        end
    end
    else if(en_m == 1)
    begin
        // if(en_m == 1)
        // begin
            wen <= ~wen;

            for(int i = 0; i < NUM_BRAMS; i++)
            begin
                bram_addr[0][i] <= depth;
                bram_addr[1][i] <= depth + 1;
            end

            if(wrk_mode == 0) // write mode
            begin
                    for(int i = 0; i < NUM_BRAMS; i++) // working, memory need 1 cycle delay to store data
                    begin
                        bram_din[0][i] <= {i_fwd_prv_st[i*8 + 3], i_fwd_prv_st[i*8 + 2], i_fwd_prv_st[i*8 + 1], i_fwd_prv_st[i*8]};
                        bram_din[1][i] <= {i_fwd_prv_st[i*8 + 7], i_fwd_prv_st[i*8 + 6], i_fwd_prv_st[i*8 + 5], i_fwd_prv_st[i*8 + 4]};
                    end
                if(depth < `TRACEBACK_DEPTH*2 - 2 && wen == 1)
                    depth <= depth + 2;
            end
            else if(wrk_mode == 1) // read mode 
            begin
                for(int i = 0; i < NUM_BRAMS; i++) //32 BRAMs, each holds 8 state value
                begin
                    o_bck_prv_st[i*8]     <= bram_dout_reg[0][i][7:0]; // have 2 cycle delay compared to address
                    o_bck_prv_st[i*8 + 1] <= bram_dout_reg[0][i][15:8];
                    o_bck_prv_st[i*8 + 2] <= bram_dout_reg[0][i][23:16];
                    o_bck_prv_st[i*8 + 3] <= bram_dout_reg[0][i][31:24];

                    o_bck_prv_st[i*8 + 4] <= bram_dout_reg[1][i][7:0];
                    o_bck_prv_st[i*8 + 5] <= bram_dout_reg[1][i][15:8];
                    o_bck_prv_st[i*8 + 6] <= bram_dout_reg[1][i][23:16];
                    o_bck_prv_st[i*8 + 7] <= bram_dout_reg[1][i][31:24];
                end
                if(depth > 0)
                    depth <= depth - 2;
            end
        //end
        // else
        // begin
        //     for (int i = 0; i < `MAX_STATE_NUM; i++) 
        //     begin
        //         o_bck_prv_st[i] <= 0;
        //     end
        // end
    end
end

always_ff @(posedge clk)
begin
    if(rst == 0)
    begin
        wrk_mode <= 0;
        //mem_delay <= 0;
    end
    else
    begin
        if (depth == 6) //`TRACEBACK_DEPTH*2 - 2
            mem_delay <= 1;
        if(mem_delay == 1)
            wrk_mode <= 1;
    end
end


always_ff @(posedge clk) // Output flag
begin
    // if (rst == 0)
    // begin
    //     o_sync <= 0;
    // end
    //else 
    // if(en_m == 1)
    // begin
        //if(en_m == 1)
        //begin
            if(wrk_mode == 0 && depth == 6) //wrk_mode == 0 && depth == `TRACEBACK_DEPTH*2 - 6
            begin
                //if(depth == `TRACEBACK_DEPTH*2 - 6)
                    o_sync <= 1;
            end
        //end 
        // else 
        // begin
        //     o_sync <= 0;
        // end
    //end
end

endmodule