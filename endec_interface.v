// `include "param_def.sv"
// `timescale 1ns / 1ps

// module endec_interface (  sys_clk, rst, en,
//                         i_code_rate,
//                         i_gen_poly_flat,
//                         i_encoder_data_frame,
//                         i_decoder_data_frame,
//                         i_prv_encoder_state,
//                         o_encoder_data, o_encoder_done,
//                         o_decoder_data, o_decoder_done);

// input wire sys_clk, rst, en;
// input wire i_code_rate;
// input wire [`MAX_CONSTRAINT_LENGTH*`MAX_CODE_RATE - 1:0] i_gen_poly_flat;
// input wire [191:0] i_encoder_data_frame; 
// input wire [383:0] i_decoder_data_frame;
// input wire [`MAX_STATE_REG_NUM - 1:0] i_prv_encoder_state;

// output wire [575:0] o_encoder_data; 
// output wire o_encoder_done;
// output wire [127:0] o_decoder_data;
// output wire o_decoder_done;

// endec E1 (
//     .sys_clk(sys_clk),
//     .rst(rst),
//     .en(en),
//     .i_code_rate(i_code_rate),
//     .i_gen_poly_flat(i_gen_poly_flat),
//     .i_encoder_data_frame(i_encoder_data_frame),
//     .i_decoder_data_frame(i_decoder_data_frame),
//     .i_prv_encoder_state(i_prv_encoder_state),
//     .o_encoder_data(o_encoder_data),
//     .o_encoder_done(o_encoder_done),
//     .o_decoder_data(o_decoder_data),
//     .o_decoder_done(o_decoder_done));

// endmodule


`include "param_def.sv"
`timescale 1ns / 1ps
module endec_interface( sys_clk, rst_n,
                        s_axis_tdata,
                        s_axis_tlast,
                        s_axis_tready,
                        s_axis_tvalid,
                        s_axis_aclk,
                        m_axis_tdata,
                        m_axis_tlast,
                        m_axis_tready,
                        m_axis_tvalid,
                        m_axis_aclk);

input wire sys_clk, rst_n;

input wire s_axis_aclk, m_axis_aclk; // to avoid warning in block design

//AXI RX
input wire [63:0] s_axis_tdata;
input wire s_axis_tlast; // valid and ready must already be high
output reg s_axis_tready; // active high
input wire s_axis_tvalid; // active high, deactivate when handshake is complete, handshake complete when both signal is high

//AXI TX
output reg [63:0] m_axis_tdata;
output reg m_axis_tlast; // signal last transfer in a packet
input wire m_axis_tready;
output reg m_axis_tvalid;

reg nxt_rst;
reg nxt_en; 

//Config signals
reg rst; // internal reset signal
reg en;
wire i_code_rate;
wire [`MAX_CONSTRAINT_LENGTH*`MAX_CODE_RATE - 1:0] i_gen_poly_flat;

//data for 1 packet
wire [`MAX_STATE_REG_NUM -1:0] i_prv_encoder_state;
wire [191:0] i_encoder_data_frame;
wire [575:0] o_encoder_data; 
wire o_encoder_done;
wire [383:0] i_decoder_data_frame;
wire [127:0] o_decoder_data;
wire o_decoder_done;

//for FSM
reg state;
reg nxt_state;
localparam RST = 1'b0;
localparam WORKING = 1'b1;

reg [9:0] rx_buffer_count = 0;
reg [9:0] tx_count;

reg [639:0] rx_data;
reg [703:0] tx_data;

reg [639:0] rx_data_buffer;
reg endec_finish = 0;
reg rx_data_buffer_ready = 0;
reg prv_en; // to detect posedge en

assign i_gen_poly_flat = rx_data[26:0];
assign i_code_rate = rx_data[27];
assign i_prv_encoder_state = rx_data[35:28];
assign i_encoder_data_frame = rx_data[255:64];  
assign i_decoder_data_frame = rx_data[639:256];


always @(posedge sys_clk)
begin
    case(state)
        RST:
        begin
            rx_data <= rx_data_buffer;
        end

        WORKING:
        begin
            if(o_encoder_done == 1 && o_decoder_done == 1) // sample at the moment both data are done
            begin
                tx_data <= {o_decoder_data, o_encoder_data};
            end
        end

        default:
        begin 

        end
    endcase
end

always @(posedge sys_clk) // RX_DATA
begin
    if(prv_en == 0 && en == 1) // == rising edge of en 
        rx_data_buffer_ready <= 0; // retrieve data for the new cycle
    if(rx_data_buffer_ready == 0) // when buffered data is read by module 
    begin
        s_axis_tready <= 1;
        if(s_axis_tvalid == 1) 
        begin
            rx_data_buffer[rx_buffer_count +:64] <= s_axis_tdata; 
            rx_buffer_count <= rx_buffer_count + 64;
            if(s_axis_tlast == 1)
            begin
                s_axis_tready <= 0;
                rx_data_buffer_ready <= 1;
            end
        end
    end
    else // rx_data_buffer_ready == 1,  rst state 
    begin
        rx_buffer_count <= 0;
        s_axis_tready <= 0;
    end
end

always @(posedge sys_clk) // TX_DATA
begin
    if(o_encoder_done == 1 && o_decoder_done == 1)
        endec_finish <= 1; // hold value even after module go to the next cycle
    if(endec_finish == 1)
    begin
        m_axis_tvalid <= 1;
        m_axis_tdata <= tx_data[tx_count +:64];
        if(m_axis_tready == 1) // m_axis_tvalid always = 1 in TX_DATA mode
            tx_count <= tx_count + 64;
        if(tx_count == 640) // m_axis_tready always = 1 due to FIFO
            m_axis_tlast <= 1;
        if(m_axis_tlast == 1) // only last 1 cycle
        begin
            m_axis_tvalid <= 0;
            m_axis_tlast <= 0;
            endec_finish <= 0; // wait for the next cycle
        end
    end
    else // endec_finish == 0, rst state
    begin
        tx_count <= 0;
        m_axis_tvalid <= 0;
        m_axis_tlast <= 0;
    end
end

// FSM
always @(posedge sys_clk)
begin
    if(rst_n == 0)
    begin
        state <= RST;
        rst <= 0;
        en <= 0;
        prv_en <= 0;
    end
    else
    begin
        state <= nxt_state;
        rst <= nxt_rst;
        en <= nxt_en;
        prv_en <= en;
    end
end

always @(*) // internal reset and en signal
begin
    case(state) 
        RST:
        begin
            nxt_rst = 0;
            nxt_en = 0;
            if(rx_data_buffer_ready == 1 && o_encoder_done == 0 && o_decoder_done == 0) // ensure data reset of previous cycle
                nxt_state = WORKING;
            else 
                nxt_state = RST;
        end

        WORKING:
        begin
            nxt_rst = 1;
            nxt_en = 1; 
            if(o_encoder_done == 1 && o_decoder_done == 1)
                nxt_state = RST;
            else
                nxt_state = WORKING;
        end

        default:
        begin
            nxt_rst = 0;
            nxt_en = 0;
            nxt_state = RST;
        end
    endcase
end

//Instantiate the original module
endec E1 (
    .sys_clk(sys_clk),
    .rst(rst),
    .en(en),
    .i_code_rate(i_code_rate),
    .i_gen_poly_flat(i_gen_poly_flat),
    .i_encoder_data_frame(i_encoder_data_frame),
    .i_decoder_data_frame(i_decoder_data_frame),
    .i_prv_encoder_state(i_prv_encoder_state),
    .o_encoder_data(o_encoder_data),
    .o_encoder_done(o_encoder_done),
    .o_decoder_data(o_decoder_data),
    .o_decoder_done(o_decoder_done));

endmodule