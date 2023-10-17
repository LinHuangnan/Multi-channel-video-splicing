/* =======================================================================
* Copyright (c) 2023, MongooseOrion.
* All rights reserved.
*
* The following code snippet may contain portions that are derived from
* OPEN-SOURCE communities, and these portions will be licensed with: 
*
* <NULL>
*
* If there is no OPEN-SOURCE licenses are listed, it indicates none of
* content in this Code document is sourced from OPEN-SOURCE communities. 
*
* In this case, the document is protected by copyright, and any use of
* all or part of its content by individuals, organizations, or companies
* without authorization is prohibited, unless the project repository
* associated with this document has added relevant OPEN-SOURCE licenses
* by github.com/MongooseOrion. 
*
* Please make sure using the content of this document in accordance with 
* the respective OPEN-SOURCE licenses. 
* 
* THIS CODE IS PROVIDED BY https://github.com/MongooseOrion. 
* =======================================================================
*/
// 对上 1/4 高度画面进行操作，将画面缩小到 1/16
// 输入规格：1280x720

module video_sampling_1#(
    parameter WR_ADDR_LEN = 'd8, 
    parameter RD_ADDR_LEN = 'd5,
    parameter IMAGE_TAG = 4'd1,
    parameter DQ_WIDTH = 12'd32,
    parameter VIDEO_WIDTH = 'd1280,
    parameter VIDEO_HEIGHT = 'd720
)(
    input               clk,
    input               rst,
    // 信号输入
    input               de_in,
    input               vs_in,
    input       [15:0]  rgb565_in,
    // DDR 存储
    input                                   rd_clk,
    input       [RD_ADDR_LEN - 1'b1 : 0]    rd_addr,
    output      [DQ_WIDTH*8-1'b1:0]         rd_data,
    input                                   rd_valid,
    output reg                              data_out_ready,
    output reg  [3:0]                       trans_id,
    output reg                              row_end_flag,
    output reg                              frame_end_flag
);

parameter COLUMN_NUM_QD = VIDEO_WIDTH / 'd4;
parameter ROW_NUM_QD = VIDEO_HEIGHT / 'd4;

wire        pose_vs_in;
wire        nege_vs_in;
wire        wr_en;
wire        pose_rd_valid;

reg [WR_ADDR_LEN - 1'b1 : 0]    wr_addr_temp;
reg [WR_ADDR_LEN - 1'b1 : 0]    wr_addr;
reg                             wr_en_tr;
reg                             wr_en_final;
reg [15:0]                      wr_data_temp;
reg [DQ_WIDTH-1'b1:0]           wr_data;
reg [1:0]                       data_len_cnt;   // 存入 DRAM 的单个数据为两个 RGB565 像素
reg                             vs_in_1;
reg                             frame_valid;
reg                             de_in_1;
reg [1:0]                       href_count;
reg [2:0]                       pix_count;
reg [15:0]                      pix_full_count;
reg                             rd_valid_d1;
reg [1:0]                       rd_valid_count;


// 帧有效信号，确保数据按帧顺序存储
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        vs_in_1 <= 'b0;
    end
    else begin
        vs_in_1 <= vs_in;
    end
end
assign pose_vs_in = ((vs_in) && (~vs_in_1)) ? 1'b1 : 1'b0;
assign nege_vs_in = ((~vs_in) && (vs_in_1)) ? 1'b1 : 1'b0;


always @(posedge clk or negedge rst) begin
    if(!rst) begin
        frame_valid <= 'b0;
    end
    else if(nege_vs_in) begin
        frame_valid <= 1'b1;
    end
    else if(pose_vs_in) begin
        frame_valid <= 1'b0;
    end
    else begin
        frame_valid <= frame_valid;
    end
end


// 行计数和抽样，间隔 3 行
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        de_in_1 <= 'b0;
    end
    else begin
        de_in_1 <= de_in;
    end
end
assign pose_de_in = ((de_in) && (~de_in_1)) ? 1'b1 : 1'b0;
assign nege_de_in = ((~de_in) && (de_in_1)) ? 1'b1 : 1'b0;

always @(posedge clk or negedge rst) begin
    if(!rst) begin
        href_count <= 'b0;
    end
    else if(frame_valid) begin
        if((pose_de_in == 1'b1) && (href_count < 4'd4)) begin
            href_count <= href_count + 1'b1;
        end
        else if((pose_de_in == 1'b1) && (href_count == 4'd4)) begin
            href_count <= 4'b1;
        end
        else begin
            href_count <= href_count;
        end
    end
    else begin
        href_count <= 2'b0;
    end
end


// 写使能信号
/*always @(posedge clk or negedge rst) begin
    if(!rst) begin
        wr_en <= 'b0;
    end
    else if((href_count == 4'd1) && (de_in == 1'b1)) begin
        wr_en <= 1'b1;
    end
    else begin
        wr_en <= 1'b0;
    end
end*/
assign wr_en = ((href_count == 4'd1) && (de_in_1 == 1'b1)) ? 1'b1 : 1'b0;


// 每五个像素丢中间三个像素数据
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        pix_count <= 'b0;
    end
    else if(wr_en) begin
        if(pix_count == 2'd3) begin
            pix_count <= 2'd0;
        end
        else begin
            pix_count <= pix_count + 1'b1;
        end
    end
    else begin
        pix_count <= 2'b0;
    end
end


// 实际写使能信号
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        wr_en_tr <= 'b0;
    end
    else if((wr_en == 1'b1) && (pix_count == 2'd0)) begin
        wr_en_tr <= 1'b1;
    end
    else begin
        wr_en_tr <= 1'b0;
    end
end
// 补足写数据 1 个延迟
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        wr_en_final <= 'b0;
    end
    else begin
        wr_en_final <= wr_en_tr;
    end
end


// 写数据 RGR565 像素个数计数
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        data_len_cnt <= 'b0;
    end
    else if((wr_en == 1'b1) && (pix_count == 2'd0)) begin
        if(data_len_cnt == 2'd2) begin
            data_len_cnt <= 2'd1;
        end
        else begin
            data_len_cnt <= data_len_cnt + 1'b1;
        end
    end
    else begin
        data_len_cnt <= data_len_cnt;
    end
end


// 写数据信号，该片段造成两个单位延迟 
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        wr_data_temp <= 'b0;
    end
    else begin
        wr_data_temp <= rgb565_in;
    end
end

always @(posedge clk or negedge rst) begin
    if(!rst) begin
        wr_data <= 'b0;
    end
    else if((wr_en == 1'b1) && (pix_count == 2'd0)) begin
        wr_data <= {16'b0,wr_data_temp};
    end
    else if(data_len_cnt == 2'd2) begin
        wr_data <= {wr_data_temp,wr_data[15:0]};        // 后来的数据放前面
    end
    else begin
        wr_data <= wr_data;
    end
end


// 写地址信号
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        wr_addr_temp <= 'b0;
    end
    else if((wr_en_tr == 1'b1) && (data_len_cnt == 2'd2)) begin
        wr_addr_temp <= wr_addr_temp + 1'b1;
    end
    else begin
        wr_addr_temp <= wr_addr_temp;
    end
end
// 补足写数据 1 个延迟
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        wr_addr <= 'b0;
    end
    else begin
        wr_addr <= wr_addr_temp;
    end
end


sdram_sampling wr_buffer(
    .wr_data    (wr_data),      // input [31:0]
    .wr_addr    (wr_addr),      // input [5:0]
    .wr_en      (wr_en_final),        // input
    .wr_clk     (clk),          // input
    .wr_rst     (!rst),         // input
    .rd_addr    (rd_addr),      // input [5:0]
    .rd_data    (rd_data),      // output [255:0]
    .rd_clk     (rd_clk),       // input
    .rd_rst     (!rst)        // input
);


// 传输事务 ID
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        trans_id <= 4'b0;
    end
    else begin
        trans_id <= IMAGE_TAG;
    end
end


// 写准备信号，在有效信号输入后通过判定写地址数值来确定拉高
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        rd_valid_d1 <= 'b0;
    end
    else begin
        rd_valid_d1 <= rd_valid;
    end
end
assign pose_rd_valid = ((rd_valid) && (~rd_valid_d1)) ? 1'b1 : 1'b0;

always @(posedge clk or negedge rst) begin
    if(!rst) begin
        rd_valid_count <= 'b0;
    end
    else if(pose_rd_valid) begin
        if(rd_valid_count == 2'd2) begin
            rd_valid_count <= 2'd1;
        end
        else begin
            rd_valid_count <= rd_valid_count + 1'b1;
        end
    end
    else begin
    rd_valid_count <= rd_valid_count;
    end
end

// 判定存入数据量是否已经足够进行一次突发传输
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        data_out_ready <= 'b0;
    end
    else if(rd_valid_d1) begin
        if(rd_valid_count == 2'd1) begin
            if(wr_addr >= 'd128) begin
                data_out_ready <= 1'b1;
            end
            else begin
                data_out_ready <= 1'b0;
            end
        end
        else if(rd_valid_count == 2'd2) begin
            if(wr_addr >= 'd0) begin
                data_out_ready <= 1'b1;
            end
            else begin
                data_out_ready <= 1'b0;
            end
        end
        else begin
            data_out_ready <= 1'b0;
        end
    end
    else begin
        data_out_ready <= 1'b0;
    end
end


// 行结束标志
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        pix_full_count <= 'b0;
    end
    else if(wr_en_tr) begin
        pix_full_count <= pix_full_count + 1'b1;
    end
    else if(pix_full_count == (COLUMN_NUM_QD*ROW_NUM_QD)) begin
        pix_full_count <= 16'd0;
    end
    else begin
        pix_full_count <= pix_full_count;
    end
end

always @(posedge clk or negedge rst) begin
    if(!rst) begin
        row_end_flag <= 'b0;
    end
    else if((pix_full_count + 1'b1) % COLUMN_NUM_QD == 'b0) begin
        row_end_flag <= 1'b1;
    end
    else begin
        row_end_flag <= 1'b0;
    end
end


// 帧结束标志
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        frame_end_flag <= 'b0;
    end
    else if(pix_full_count == COLUMN_NUM_QD * ROW_NUM_QD - 1'b1) begin
        frame_end_flag <= 1'b1;
    end
    else begin
        frame_end_flag <= 1'b0;
    end
end

endmodule