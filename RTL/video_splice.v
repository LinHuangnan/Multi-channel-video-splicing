module video_splice(
   input                clk,
   input                rst,

   // cmos1	
   input                cmos1_pclk,    // ����ʱ��
   input                cmos1_de,      // ��ͬ��
   input                cmos1_vs,      // ��ͬ��
   input       [15:0]   cmos1_data,    // rgb565 ����
   // cmos2
   input                cmos2_pclk,    // ����ʱ��
   input                cmos2_de,      // ��ͬ��
   input                cmos2_vs,      // ��ͬ��
   input       [15:0]   cmos2_data,    // rgb565 ����
   // cmos3
   input                cmos3_pclk,    // ����ʱ��
   input                cmos3_de,      // ��ͬ��
   input                cmos3_vs,      // ��ͬ��
   input       [15:0]   cmos3_data,    // rgb565 ����
   // cmos4
   input                cmos4_pclk,    // ����ʱ��
   input                cmos4_de,      // ��ͬ��
   input                cmos4_vs,      // ��ͬ��
   input       [15:0]   cmos4_data,    // rgb565 ����

   // output
   output               global_pclk,
   output               global_de,
   output               global_vs,
   output               global_data
   );





   
endmodule