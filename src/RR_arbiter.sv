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
  logic [STREAM_COUNT-1:0] grant_rr_d;
  logic [STREAM_COUNT-1:0] grant_rr;
  logic en_d, nzero_req, nzero_req_d, grant_en;
  
  assign mask       = ~((ptr_r-1) | ptr_r);
  assign masked_req = req & mask;
  assign grant_rr   = (|masked_req) ? masked_grant : unmasked_grant;
  assign grant      = (grant_en)     ? grant_rr   : grant_rr_d;

  simple_priority_arbiter #(STREAM_COUNT) i_masked_sp(
    .req  (masked_req  ),
    .grant(masked_grant)
  );

  simple_priority_arbiter #(STREAM_COUNT) i_unmasked_sp(
    .req  (req           ),
    .grant(unmasked_grant)
  );
  
  assign nzero_req = |req;
  assign grant_en  = en_d | (~nzero_req_d & nzero_req);
  
  always_ff @(posedge clk or negedge nrst) begin
    if (!nrst) begin
      grant_rr_d <= '0;
    end else if (grant_en) begin
      grant_rr_d <= grant_rr;
    end
  end
  
  always_ff @(posedge clk or negedge nrst) begin
    if (!nrst) begin
      en_d        <= 1'b0;
      nzero_req_d <= 1'b0;
    end else begin
      en_d        <= en;
      nzero_req_d <= nzero_req;
    end
  end
  
  always_ff @(posedge clk or negedge nrst)
    if (~nrst)   ptr_r <= 0;
    else if (en) ptr_r <= grant;

endmodule