module stream_arbiter #(
  parameter  T_DATA_WIDTH = 8,
             T_QOS__WIDTH = 4,
             STREAM_COUNT = 2,
  localparam T_ID___WIDTH = $clog2(STREAM_COUNT)
)(
  input  logic clk,
  input  logic rst_n,
  // input streams
  input  logic [T_DATA_WIDTH-1:0] s_data_i [STREAM_COUNT-1:0],
  input  logic [T_QOS__WIDTH-1:0] s_qos_i [STREAM_COUNT-1:0],
  input  logic [STREAM_COUNT-1:0] s_last_i ,
  input  logic [STREAM_COUNT-1:0] s_valid_i,
  output logic [STREAM_COUNT-1:0] s_ready_o,
  // output stream
  output logic [T_DATA_WIDTH-1:0] m_data_o,
  output logic [T_QOS__WIDTH-1:0] m_qos_o,
  output logic [T_ID___WIDTH-1:0] m_id_o,
  output logic m_last_o,
  output logic m_valid_o,
  input  logic m_ready_i
);

  logic [STREAM_COUNT-1:0] grant_onehot;
  logic [T_ID___WIDTH-1:0] id;
  logic [T_DATA_WIDTH-1:0] data;
  logic [T_QOS__WIDTH-1:0] qos;
  logic last;
  
  
  RR_priority_arbiter #(STREAM_COUNT, T_QOS__WIDTH) i_rr_pr(
    .clk  (clk         ),
    .nrst (rst_n       ),
    .en   (last        ),
    .req  (s_valid_i   ),
    .qos  (s_qos_i     ),
    .grant(grant_onehot)
  );


  always_comb begin
    id = 0;
    for (int i = 0; i < STREAM_COUNT; i++) begin
      if (grant_onehot[i]) id = i;
    end
  end

  always_comb begin
    data = 0;
    qos  = 0;
    last = 0;
    for (int i = 0; i < STREAM_COUNT; i++) begin
      if (id == i) begin
        data = s_data_i[i];
        qos  = s_qos_i [i];
        last = s_last_i[i];
      end
    end
  end

  assign m_id_o   = id;
  assign m_data_o = data;
  assign m_qos_o  = qos;
  assign m_last_o = last;

  assign m_valid_o = |s_valid_i;
  assign s_ready_o = (~m_ready_i) ? {STREAM_COUNT{1'b0}} :
                     (|s_valid_i) ? grant_onehot : 
                                    {STREAM_COUNT{1'b1}};

endmodule