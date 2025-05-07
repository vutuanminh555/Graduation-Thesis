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
// input wire [127:0] i_encoder_data_frame;
// input wire [383:0] i_decoder_data_frame; // 383
// input wire [`MAX_STATE_REG_NUM - 1:0] i_prv_encoder_state;

// output wire [383:0] o_encoder_data; // 383
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
                        m_axis_tdata,
                        m_axis_tlast,
                        m_axis_tready,
                        m_axis_tvalid);

input wire sys_clk, rst_n;

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
wire [127:0] i_encoder_data_frame;
wire [`MAX_STATE_REG_NUM -1:0] i_prv_encoder_state;
wire [383:0] o_encoder_data; 
wire o_encoder_done;
wire [383:0] i_decoder_data_frame;
wire [127:0] o_decoder_data;
wire o_decoder_done;

//for FSM
reg [2:0] state;
reg [2:0] nxt_state;
localparam [2:0] RST = 3'b000;
localparam [2:0] CONF = 3'b001;
localparam [2:0] RX_DATA = 3'b010;
localparam [2:0] WORKING = 3'b011;
localparam [2:0] TX_DATA = 3'b100;

reg [8:0] rx_count;
reg [8:0] tx_count;

reg [63:0] config_data;
reg [511:0] rx_data;
reg [511:0] tx_data;


assign i_gen_poly_flat = config_data[26:0];
assign i_code_rate = config_data[27];
assign i_prv_encoder_state = config_data[35:28];
assign i_encoder_data_frame = rx_data[127:0];  
assign i_decoder_data_frame = rx_data[511:128];

//AXI RX - TX
always @(posedge sys_clk)
begin
    case(state)

        RST:
        begin
            s_axis_tready <= 0; 
            m_axis_tdata <= 0;
            m_axis_tvalid <= 0;
            m_axis_tlast <= 0;
            rx_count <= 0; 
            tx_count <= 0;
        end

        CONF:
        begin
            s_axis_tready <= 1;
            if(s_axis_tvalid == 1 && s_axis_tready == 1 && s_axis_tlast == 1)
            begin
                config_data <= s_axis_tdata;
                s_axis_tready <= 0;
            end
        end

        RX_DATA: 
        begin
            s_axis_tready <= 1;
            if(s_axis_tvalid == 1 && s_axis_tready == 1) 
            begin
                rx_data[rx_count +:64] <= s_axis_tdata; 
                rx_count <= rx_count + 64;
                if(s_axis_tlast == 1) 
                    s_axis_tready <= 0;
            end
        end

        WORKING:
        begin
            s_axis_tready <= 0; 
            m_axis_tvalid <= 0;
            if(o_encoder_done == 1 && o_decoder_done == 1)
                tx_data <= {o_decoder_data, o_encoder_data};
        end

        TX_DATA: 
        begin
            m_axis_tvalid <= 1;
            m_axis_tdata <= tx_data[tx_count +:64];
            if(m_axis_tready == 1) // m_axis_tvalid always = 1 in TX_DATA mode
                tx_count <= tx_count + 64;
            if(tx_count == 448) 
                m_axis_tlast <= 1;
        end

        default:
        begin 
            s_axis_tready <= 0;
            m_axis_tdata <= 0;
            m_axis_tvalid <= 0;
            m_axis_tlast <= 0;
            rx_count <= 0;
            tx_count <= 0;
        end
    endcase
end


// FSM
always @(posedge sys_clk)
begin
    if(rst_n == 0)
    begin
        state <= RST;
        rst <= 0;
        en <= 0;
    end
    else
    begin
        state <= nxt_state;
        rst <= nxt_rst;
        en <= nxt_en;
    end
end

always @(*) // internal reset and en signal
begin
    case(state) 
        RST:
        begin
            nxt_rst = 0;
            nxt_en = 0;
            nxt_state = CONF;
        end

        CONF:
        begin
            nxt_rst = 0; 
            nxt_en = 0;
            if(s_axis_tvalid == 1 && s_axis_tready == 1 && s_axis_tlast == 1)
                nxt_state = RX_DATA;
            else
                nxt_state = CONF;
        end

        RX_DATA:
        begin
            nxt_rst = 0;
            nxt_en = 0;
            if(s_axis_tvalid == 1 && s_axis_tready == 1 && s_axis_tlast == 1)
                nxt_state = WORKING;
            else
                nxt_state = RX_DATA;
        end

        WORKING:
        begin
            nxt_rst = 1;
            nxt_en = 1; 
            if(o_encoder_done == 1 && o_decoder_done == 1) // finished processing data
                nxt_state = TX_DATA;
            else
                nxt_state = WORKING;
        end

        TX_DATA:
        begin
            nxt_rst = 1; 
            nxt_en = 0;
            if(m_axis_tvalid == 1 && m_axis_tready == 1 && m_axis_tlast == 1)
                nxt_state = RST;
            else 
                nxt_state = TX_DATA;
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