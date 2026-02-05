module RR_priority_arbiter#(
   parameter STREAM_COUNT = 2,
             T_QOS__WIDTH = 4
) (
   input  logic                    clk,
   input  logic                    nrst,
   input  logic                    en,
   input  logic [STREAM_COUNT-1:0] req,
   input  logic [T_QOS__WIDTH-1:0] qos [STREAM_COUNT-1:0],
   output logic [STREAM_COUNT-1:0] grant
);
   
  logic [T_QOS__WIDTH-1:0] max_qos;
  logic [T_QOS__WIDTH-1:0] active_qos [STREAM_COUNT-1:0];
  logic [STREAM_COUNT-1:0] active_req;
 
  always_comb begin
    for (int i = 0; i < STREAM_COUNT; i = i + 1) 
      active_qos[i] = req[i] ? qos[i] : 0;
  end

  always_comb begin
    for (int i = 0; i < STREAM_COUNT; i++)
      active_req[i] = ((qos[i] == max_qos) | (qos[i] == 0)) & req[i];
  end

  max_finder #(STREAM_COUNT, T_QOS__WIDTH) i_max(
    .values   (active_qos),
    .max_value(max_qos)
   );
  
  RR_arbiter #(STREAM_COUNT) i_rr(
    .clk  (clk),
    .nrst (nrst),
    .req  (active_req),
    .en   (en),
    .grant(grant)
  );

endmodule