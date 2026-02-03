module simple_priority_arbiter #(
   parameter STREAM_COUNT = 2
) (
   input  logic [STREAM_COUNT-1:0] req,
   output logic [STREAM_COUNT-1:0] grant
);

logic [STREAM_COUNT-1:0] higher_pri_reqs;

/*assign higher_pri_reqs[STREAM_COUNT-1:1] = higher_pri_reqs[STREAM_COUNT-2:0] | req[STREAM_COUNT-2:0];
assign higher_pri_reqs[0] = 1'b0;
assign grant[STREAM_COUNT-1:0] = req[STREAM_COUNT-1:0] & ~higher_pri_reqs[STREAM_COUNT-1:0];*/

assign higher_pri_reqs[0] = 1'b0;
generate
    for (genvar i=1; i<STREAM_COUNT; i++) begin
        assign higher_pri_reqs[i] = |req[i-1:0];
    end
endgenerate
assign grant = req & ~higher_pri_reqs;

endmodule