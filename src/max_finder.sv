module max_finder #(
  parameter N  = 8,
            WL = 4
)(
  input  logic [WL-1:0] values [0:N-1],
  output logic [WL-1:0] max_value
);

  logic [WL-1:0] max_val;
    
  always_comb begin
    max_val = values[0];
    for (int i = 1; i < N; i++) begin
      max_val = (max_val > array[i]) ? max_val : array[i];
    end
  end

  assign max_value = max_val;

endmodule