module stream_arbiter #(
  parameter T_DATA_WIDTH = 8,
  T_QOS__WIDTH = 4,
  STREAM_COUNT = 2,
  localparam T_ID___WIDTH = $clog2(STREAM_COUNT)
)(
  input logic clk,
  input logic rst_n,
  // input streams
  input logic [T_DATA_WIDTH-1:0] s_data_i [STREAM_COUNT-1:0],
  input logic [T_QOS__WIDTH-1:0] s_qos_i [STREAM_COUNT-1:0],
  input logic [STREAM_COUNT-1:0] s_last_i ,
  input logic [STREAM_COUNT-1:0] s_valid_i,
  output logic [STREAM_COUNT-1:0] s_ready_o,
  // output stream
  output logic [T_DATA_WIDTH-1:0] m_data_o,
  output logic [T_QOS__WIDTH-1:0] m_qos_o,
  output logic [T_ID___WIDTH-1:0] m_id_o,
  output logic m_last_o,
  output logic m_valid_o,
  input logic m_ready_i
);

  RR_priority_arbiter#(STREAM_COUNT, T_QOS__WIDTH = 4) i_rr_pr(
    input  logic                    clk,
    input  logic                    nrst,
    input  logic                    en,
    input  logic [STREAM_COUNT-1:0] req,
    input  logic [T_QOS__WIDTH-1:0] qos [0:STREAM_COUNT-1],
    output logic [STREAM_COUNT-1:0] grant,
 );

endmodule