module tb_top_level;

    parameter WIDTH_A = 32;
    parameter WIDTH_D = 32;

    logic                clk, rst_n;
    logic [1:0]          cpu_request;
    logic [WIDTH_A-1:0]  cpu_addr;
    logic [WIDTH_D-1:0]  cpu_wdata;
    logic [WIDTH_D-1:0]  cpu_rdata;
    logic                cache_ready, cache_complete;

    // Interconnect signals
    logic                AW_READY, AW_VALID;
    logic [WIDTH_A-1:0]  AW_ADDR;
    logic                AW_ID;
    logic [2:0]          AW_SIZE;
    logic [1:0]          AW_BURST;
    logic [7:0]          AW_LEN;
    logic [2:0]          AW_PROT;
    logic [3:0]          AW_CACHE;
    logic [1:0]          AW_BAR;
    logic [1:0]          AW_DOMAIN;
    logic [2:0]          AW_SNOOP;

    logic                W_READY, W_VALID;
    logic                W_ID, W_LAST;
    logic [WIDTH_D-1:0]  W_DATA;

    logic                B_VALID, B_READY;
  
    logic [1:0]          BRE
