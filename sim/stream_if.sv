interface stream_if #(
  parameter T_DATA_WIDTH = 8,
            T_QOS__WIDTH = 4,
            STREAM_COUNT = 2
)(
  input logic clk,
  input logic rst_n
);

  // input streams
  logic [T_DATA_WIDTH-1:0] s_data_i   [STREAM_COUNT-1:0];
  logic [T_QOS__WIDTH-1:0] s_qos_i    [STREAM_COUNT-1:0];
  logic [STREAM_COUNT-1:0] s_last_i;
  logic [STREAM_COUNT-1:0] s_valid_i;
  logic [STREAM_COUNT-1:0] s_ready_o;

  // output stream
  logic [T_DATA_WIDTH-1:0] m_data_o;
  logic [T_QOS__WIDTH-1:0] m_qos_o;
  logic [$clog2(STREAM_COUNT)-1:0] m_id_o;
  logic m_last_o;
  logic m_valid_o;
  logic m_ready_i;

endinterface
