//
// ������ͼ�񳬲���
// ������1280*720 �����غ�һ���� HDMI �����
// ��ǿ���ز�����ԭ����һ��
`timescale 1ns / 1ps

module video_sampling #(
  // ���������ؼ���λ��
  parameter               X_BITS = 12,
  parameter               Y_BITS = 12,
  // ԭ��Ƶ������������
  parameter V_ACT = 12'd720,
  parameter H_ACT = 12'd1280,
  // ����ϵ��
  parameter S_F = 2
)(
  input               clk,        // ����ʱ��
  input               rst,        // ��λ�ź�

  input       [15:0]  i_rgb565,   // ԭʼͼ������
  output      [15:0]  o_rgb565,   // ���ź��ͼ������
  output reg          vs_out,     // �����ͬ���ź�
  output reg          hs_out      // �����ͬ���ź�
);

reg [X_BITS-1:0] h_count;
reg [Y_BITS-1:0] v_count;
reg [X_BITS-1:0] x_act;
reg [Y_BITS-1:0] y_act;

reg [15:0]  input_frame [0:1279][0:719];  // ����һ֡����
reg [15:0]  scaled_frame [0:639][0:359];  // ���һ֡����

reg [15:0]   scaled_pixel;                // ���ź������ rgb565 ����



endmodule
