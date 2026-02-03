module RR_arbiter#(
  parameter STREAM_COUNT = 2
) (
  input  logic                    clk,
  input  logic                    nrst,
  input  logic                    en,
  input  logic [STREAM_COUNT-1:0] req,
  output logic [STREAM_COUNT-1:0] grant
);
   
  logic [STREAM_COUNT-1:0] ptr_r;
  logic [STREAM_COUNT-1:0] mask;
  logic [STREAM_COUNT-1:0] masked_req;
  logic [STREAM_COUNT-1:0] masked_grant;
  logic [STREAM_COUNT-1:0] unmasked_grant;
   
  assign mask       = ~((ptr_r-1) | ptr_r);
  assign masked_req = req & mask;
  assign grant      = (|masked_req) ? masked_grant : unmasked_grant;

  simple_priority_arbiter #(STREAM_COUNT) i_masked_sp(
    .req  (masked_req  ),
    .grant(masked_grant)
  );

  simple_priority_arbiter #(STREAM_COUNT) i_unmasked_sp(
    .req  (unmasked_req  ),
    .grant(unmasked_grant)
  );

  always_ff @(posedge clk or negedge nrst)
    if (~nrst) ptr_r <= 1;
    else if (en & |req) ptr_r <= grant;

endmodule