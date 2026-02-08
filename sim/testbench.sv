module testbench;
  
  `ifndef GEN_MOD
    `define GEN_MOD "FILE"
  `endif

  `ifndef CHECK_MOD
    `define CHECK_MOD "FILE"
  `endif

  // params
  localparam T_DATA_WIDTH = 8;
  localparam T_QOS__WIDTH = 4;
  localparam STREAM_COUNT = 4;

  // clock
  logic clk = 0;
  always #5 clk = ~clk;

  logic rst_n;
  logic transaction_on = 0;
  int grant_id = -1;
  int last_grant_id = -1;
  
  typedef enum logic [2:0] {
    ST_IDLE      = 3'd0,
    ST_START     = 3'd1,
    ST_TX_ON     = 3'd2,
    ST_LAST      = 3'd3,
    ST_FAIL      = 3'd4
  } state_t;
  state_t state = ST_IDLE;
  
  // interface
  stream_if #(T_DATA_WIDTH, T_QOS__WIDTH, STREAM_COUNT) vif (
    .clk(clk),
    .rst_n(rst_n)
  );

  // DUT
  stream_arbiter #(
    .T_DATA_WIDTH(T_DATA_WIDTH),
    .T_QOS__WIDTH(T_QOS__WIDTH),
    .STREAM_COUNT(STREAM_COUNT)
  ) dut (
    .clk      (clk),
    .rst_n    (rst_n),
    .s_data_i (vif.s_data_i),
    .s_qos_i  (vif.s_qos_i),
    .s_last_i (vif.s_last_i),
    .s_valid_i(vif.s_valid_i),
    .s_ready_o(vif.s_ready_o),
    .m_data_o (vif.m_data_o),
    .m_qos_o  (vif.m_qos_o),
    .m_id_o   (vif.m_id_o),
    .m_last_o (vif.m_last_o),
    .m_valid_o(vif.m_valid_o),
    .m_ready_i(vif.m_ready_i)
  );

  function automatic int get_highest_priority_stream();
    int candidate_streams[$];
    int max_qos = 0;
    int i, j;
    int g_id = -1;
    int n_id = -1;
    int out;
    for (i = 0; i < STREAM_COUNT; i++) begin
      if (last_grant_id+1+i > STREAM_COUNT-1)
        j = last_grant_id+1+i-STREAM_COUNT;
      else j = last_grant_id+1+i;
      if (vif.s_valid_i[j]) begin
        if (vif.s_qos_i[j] > max_qos) begin
          max_qos = vif.s_qos_i[j];
          g_id = j;
        end
      end
    end

    for (i = 0; i < STREAM_COUNT; i++) begin
      if (last_grant_id+1+i > STREAM_COUNT-1)
        j = last_grant_id+1+i-STREAM_COUNT;
      else j = last_grant_id+1+i;
      if (vif.s_valid_i[j]) begin
        if (vif.s_qos_i[j] == 0) begin
          n_id = j;
          break;
        end
      end
    end
    
    if (n_id > last_grant_id & g_id > last_grant_id) out = (n_id > g_id) ? g_id : n_id;
    else if (g_id > last_grant_id) out = g_id;
    else if (n_id > last_grant_id) out = n_id;
    else if (g_id == -1 & n_id == -1) out = 0;
    else if (n_id == -1) out = g_id;
    else if (g_id == -1) out = n_id;
    else out = (n_id > g_id) ? g_id : n_id; 
    return out;
  endfunction
  
  task automatic send_random_stream(int id, int num_transactions, int pkts_per_transaction);
    int actual_num_trans = (num_transactions == 0) ? $urandom_range(1, 5) : num_transactions;
    int actual_pkts_per_trans = (pkts_per_transaction == 0) ? $urandom_range(1, 8) : pkts_per_transaction;
    int expected_grant;
    for (int trans = 0; trans < actual_num_trans; trans++) begin
      logic [T_QOS__WIDTH-1:0] qos  = $urandom_range(0, (1 << T_QOS__WIDTH) - 1);

      for (int pkt = 0; pkt < actual_pkts_per_trans; pkt++) begin

        logic [T_DATA_WIDTH-1:0] data = $urandom;

        vif.s_valid_i[id] <= 1;
        vif.s_data_i[id]  <= data;
        vif.s_qos_i[id]   <= qos;
        vif.s_last_i[id]  <= (pkt == actual_pkts_per_trans-1);

        @(posedge vif.clk);
        vif.s_last_i[id]  <= 0;
        while (!vif.s_ready_o[id]) @(posedge vif.clk);

      end
      if (vif.s_ready_o[id]) transaction_on = 0;
      vif.s_valid_i[id] <= 0;
      
      repeat ($urandom_range(0, 5)) @(posedge vif.clk);
    end
  endtask

  task automatic send_stream_from_file(int id, string fname);
    int fd;
    int data, qos, last, idle;

    fd = $fopen(fname, "r");
    if (fd == 0) $fatal("Cannot open %s", fname);

    while (!$feof(fd)) begin
      $fscanf(fd, "%h %d %d %d\n", data, qos, last, idle);
      
      vif.s_valid_i[id] <= 1;
      vif.s_data_i [id] <= data;
      vif.s_qos_i  [id] <= qos;
      vif.s_last_i [id] <= last;

      @(posedge vif.clk);
      while (!vif.s_ready_o[id]) @(posedge vif.clk);

      vif.s_valid_i[id] <= 0;
      vif.s_last_i [id] <= 0;
      repeat (idle) @(posedge vif.clk);
    end

    $fclose(fd);
  endtask


  task automatic automatic_output_check(int num_periods);
    state_t next_state;
    state = ST_IDLE;

    repeat(num_periods) begin
      #1
      case(state)
        ST_IDLE:  if (vif.s_valid_i != 0)            next_state = ST_START;
        ST_START: if (vif.s_last_i[grant_id])        next_state = ST_LAST;
                  else if (!vif.s_valid_i[grant_id]) next_state = ST_FAIL;
                  else                               next_state = ST_TX_ON;
        ST_TX_ON: if (!vif.s_valid_i[grant_id])       next_state = ST_FAIL;
                  else if(vif.s_last_i[grant_id])    next_state = ST_LAST;
        ST_LAST:  if (vif.s_valid_i == 0)            next_state = ST_IDLE;
                  else                               next_state = ST_START;
        ST_FAIL:  if (vif.s_valid_i == 0)            next_state = ST_IDLE;
                  else                               next_state = ST_START;
      endcase
      if (next_state == ST_START) begin
        last_grant_id = grant_id;
        grant_id = get_highest_priority_stream();
        if (vif.s_last_i[grant_id]) next_state = ST_LAST;
      end

      state = next_state;
      
      if (!vif.m_ready_i) begin
       if (vif.s_ready_o != 0) 
          $error("ERROR: expected s_ready_o=0, actual s_ready_o=%b", vif.s_ready_o);
      end else if (state == ST_IDLE) begin 
        if (vif.m_ready_i & vif.s_ready_o != 2**STREAM_COUNT-1) 
          $error("ERROR: expected s_ready_o=%b, actual s_ready_o=%b", 2**STREAM_COUNT-1, vif.s_ready_o); 
      end else if (state == ST_START | state == ST_TX_ON | state == ST_LAST) begin
        if (vif.m_id_o != grant_id) 
          $error("ERROR: expected m_id_o=%d, actual m_id_o=%d", grant_id, vif.m_id_o);
        else if (vif.s_ready_o != 2**grant_id) 
          $error("ERROR: expected s_ready_o=%b, actual s_ready_o=%b", 2**grant_id, vif.s_ready_o);
        else if (vif.m_data_o != vif.s_data_i[grant_id])
          $error("ERROR: expected m_data_o=%h, actual m_data_o=%h", vif.s_data_i[grant_id], vif.m_data_o);
        else if (vif.m_qos_o != vif.s_qos_i[grant_id])
          $error("ERROR: expected m_qos_o=%d, actual m_qos_o=%d", vif.s_qos_i[grant_id], vif.m_qos_o);
        else if (vif.m_last_o != vif.s_last_i[grant_id])
          $error("ERROR: expected m_last_o=%b, actual m_last_o=%b", vif.s_last_i[grant_id], vif.m_last_o);
       end else if (state == ST_FAIL) begin
        if (vif.m_valid_o)
          $error("ERROR: expected m_valid_o=0, actual m_qos_o=%b", vif.m_valid_o);
       end

      @(posedge clk);
    end
    $finish;
  endtask
  

  task automatic check_output_from_file(string fname);
    int fd;
    logic [T_DATA_WIDTH-1:0] data;
    logic [T_QOS__WIDTH-1:0] qos;
    logic [STREAM_COUNT-1:0] ready;
    logic last, valid;
    int id;

    fd = $fopen(fname, "r");
    if (fd == 0) $fatal("Cannot open %s", fname);
    
    while (!$feof(fd)) begin
      #5;
      if (!vif.m_ready_i) begin
       if (vif.s_ready_o != 0) 
          $error("ERROR: expected s_ready_o=0, actual s_ready_o=%b", vif.s_ready_o);
      end else begin
        $fscanf(fd, "%h %d %d %b %b %b\n", data, qos, id, last, valid, ready);
      
        if (vif.m_id_o != id) 
          $error("ERROR: expected m_id_o=%0d, actual m_id_o=%d", id, vif.m_id_o);
        else if (vif.s_ready_o != ready) 
          $error("ERROR: expected s_ready_o=%b, actual s_ready_o=%b", ready, vif.s_ready_o);
        else if (vif.m_data_o != data)
          $error("ERROR: expected m_data_o=%h, actual m_data_o=%h", data, vif.m_data_o);
        else if (vif.m_qos_o != qos)
          $error("ERROR: expected m_qos_o=%d, actual m_qos_o=%d", qos, vif.m_qos_o);
        else if (vif.m_last_o != last)
          $error("ERROR: expected m_last_o=%b, actual m_last_o=%b", last, vif.m_last_o);
        else if (vif.m_valid_o != valid)
          $error("ERROR: expected m_valid_o=0, actual m_qos_o=%b", valid, vif.m_valid_o);

        @(posedge vif.clk);
      end
    end

    $fclose(fd);
    $finish;
  endtask

  task automatic monitor_output();
    forever begin
      @(posedge vif.clk);
      if (vif.m_valid_o && vif.m_ready_i)
        $display("[%0t] OUT: id=%0d data=%h qos=%0d last=%0d",
                 $time, vif.m_id_o, vif.m_data_o, vif.m_qos_o, vif.m_last_o);
    end
  endtask

  initial begin
  rst_n = 0;
  vif.m_ready_i = 1;
  vif.s_valid_i = 0;
  repeat (5) @(posedge clk);
  rst_n = 1;

    fork
      if(`GEN_MOD == "FILE")fork
        send_stream_from_file(0, "stream0.txt");
        send_stream_from_file(1, "stream1.txt");
        send_stream_from_file(2, "stream2.txt");
        send_stream_from_file(3, "stream3.txt");
      join
      if(`GEN_MOD == "RANDOM")fork 
        send_random_stream(0, 10, 5);
        send_random_stream(1, 10, 5);
        send_random_stream(2, 10, 5);
        send_random_stream(3, 10, 5);
      join

      begin
        repeat (5) @(posedge clk);
        vif.m_ready_i = 0;
        @(posedge clk)
        vif.m_ready_i = 1;
        repeat (6) @(posedge clk);
        vif.m_ready_i = 0;
        @(posedge clk)
        vif.m_ready_i = 1;
        repeat (5) @(posedge clk);
        vif.m_ready_i = 0;
        @(posedge clk)
        vif.m_ready_i = 1;
      end

      if(`CHECK_MOD == "FILE")fork
        check_output_from_file("check_vector.txt");
      join
      if(`CHECK_MOD == "AUTO")fork 
        automatic_output_check(100);
      join

      monitor_output();
    join
  end

endmodule

