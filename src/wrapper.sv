`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.02.2026 21:44:50
// Design Name: 
// Module Name: wrapper
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module wrapper(
  input  logic sysclk,
  input  logic nrst,
  input  logic [7:0] data0,
  input  logic [7:0] data1,
  input  logic [7:0] data2,
  input  logic [7:0] data3,
  input  logic [7:0] data4,
  input  logic [7:0] data5,
  input  logic [7:0] data6,
  input  logic [7:0] data7,
  input  logic [3:0] qos0,
  input  logic [3:0] qos1,
  input  logic [3:0] qos2,
  input  logic [3:0] qos3,
  input  logic [3:0] qos4,
  input  logic [3:0] qos5,
  input  logic [3:0] qos6,
  input  logic [3:0] qos7,
  input  logic [7:0] last_i,
  input  logic [7:0] valid_i,
  output logic [7:0] ready_o,
  output logic [2:0] id,
  output logic [7:0] data_o,
  output logic [3:0] qos_o,
  output logic       last_o,
  output logic       valid_o,
  input  logic       ready_i
);

 logic [7:0] s_data_i [0:7];
 logic [3:0] s_qos_i  [0:7];
 
 assign s_data_i[0] = data0;
 assign s_data_i[1] = data1;
 assign s_data_i[2] = data2; 
 assign s_data_i[3] = data3;
 assign s_data_i[4] = data4;
 assign s_data_i[5] = data5;
 assign s_data_i[6] = data6; 
 assign s_data_i[7] = data7;
  
 assign s_qos_i[0] = qos0;
 assign s_qos_i[1] = qos1;
 assign s_qos_i[2] = qos2;
 assign s_qos_i[3] = qos3;
 assign s_qos_i[4] = qos4;
 assign s_qos_i[5] = qos5;
 assign s_qos_i[6] = qos6;
 assign s_qos_i[7] = qos7;

stream_arbiter #(8,4,8) i_arb(
  .clk      (sysclk  ),
  .rst_n    (nrst    ),
  .s_data_i (s_data_i),
  .s_qos_i  (s_qos_i ),
  .s_last_i (last_i ),
  .s_valid_i(valid_i ),
  .s_ready_o(ready_o ),
  .m_data_o (data_o  ),
  .m_qos_o  (qos_o   ),
  .m_id_o   (id      ),
  .m_last_o (last_o  ),
  .m_valid_o(valid_o ),
  .m_ready_i(ready_i )
);
endmodule
