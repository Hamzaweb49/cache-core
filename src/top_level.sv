module top_level #( 
    parameter WIDTH_A = 32,
    parameter WIDTH_D = 32,
    parameter WIDTH_STATE = 3
) (
    input logic                clk,
    input logic                rst_n,
    
    // CPU --> Cache
    input  logic [1:0]         cpu_request,
    input  logic [WIDTH_A-1:0] cpu_addr,
    input  logic [WIDTH_D-1:0] cpu_wdata,

    // Cache --> CPU
    output logic [WIDTH_D-1:0] cpu_rdata,
    output logic               cache_ready,
    output logic               cache_complete,
    
    // Input: Interconnect --> Cache |-----| Output: Cache --> Interconnect
    // ** WRITE ADDRESS CHANNEL
    // -- Input 
    input  logic               AW_READY,
    // -- Output  
    output logic               AW_VALID,
    output logic [WIDTH_A-1:0] AW_ADDR,
    output logic               AW_ID,
    output logic [2:0]         AW_SIZE,
    output logic [1:0]         AW_BURST,
    output logic [7:0]         AW_LEN,
    output logic [2:0]         AW_PROT,
    output logic [3:0]         AW_CACHE,
    output logic [1:0]         AW_BAR,
    output logic [1:0]         AW_DOMAIN,
    output logic [2:0]         AW_SNOOP,
    
    // ** WRITE DATA CHANNEL
    // -- Input  
    input  logic               W_READY,
    // -- Output  
    output logic               W_VALID,
    output logic               W_ID,
    output logic               W_LAST,
    output logic [WIDTH_D-1:0] W_DATA,
    
    // ** WRITE RESPNOSE CHANNEL
    // -- Input 
    input  logic               B_VALID,
    input  logic [1:0]         BRESP,
    // -- Output 
    output logic               B_READY,

    // ** READ ADDRESS CHANNEL
    // -- Input 
    input  logic               AR_READY,
    // -- Output  
    output logic               AR_VALID,
    output logic [WIDTH_A-1:0] AR_ADDR,
    output logic               AR_ID,
    output logic [2:0]         AR_SIZE,
    output logic [1:0]         AR_BURST,
    output logic [7:0]         AR_LEN,
    output logic [2:0]         AR_PROT,
    output logic [3:0]         AR_CACHE,
    output logic [1:0]         AR_BAR,
    output logic [1:0]         AR_DOMAIN,
    output logic [3:0]         AR_SNOOP,

    // ** READ DATA CHANNEL
    // -- Input
    input  logic               R_ID,
    input  logic               R_LAST,
    input  logic               R_VALID,
    input  logic [3:0]         RRESP,
    input  logic [WIDTH_D-1:0] RDATA,
    // -- Output 
    output logic               R_READY,
     
    // ** SNOOP ADDRESS CHANNEL 
    // -- Input 
    input  logic               AC_VALID,
    input  logic [3:0]         AC_SNOOP,
    input  logic [2:0]         AC_PROT,
    input  logic [WIDTH_A-1:0] AC_ADDR,
    // -- Output 
    output logic               AC_READY,
    
    // ** SNOOP RESPONSE CHANNEL
    // -- Input 
    input  logic               CR_READY,
    // -- Output 
    output logic               CR_VALID,
    output logic [4:0]         CR_RESP,

    // ** SNOOP DATA CHANNEL
    // -- Input 
    input  logic               CD_READY,
    // -- Output 
    output logic               CD_VALID,
    output logic               CD_LAST,
    output logic [WIDTH_D-1:0] CD_DATA
);

logic write_from_cpu, write_from_interconnect, ac_enable, read_resp_en;
logic [2:0] new_state, line_state;
logic mux_en, cache_hit, cache_miss, make_unique, read_shared, write_clean;
logic invalid, snoop_miss, response, response_data, B_okay, R_okay;

// Cache Datapath Instantiation
cache_datapath #(
    .WIDTH_A(WIDTH_A),
    .WIDTH_D(WIDTH_D),
    .WIDTH_STATE(WIDTH_STATE)
) datapath (
    .clk                    (clk),
    .rst_n                  (rst_n),
    .cpu_addr               (cpu_addr),
    .cpu_wdata              (cpu_wdata),
    .cpu_rdata              (cpu_rdata),
    .write_from_interconnect(write_from_interconnect),
    .write_from_cpu         (write_from_cpu),
    .new_state              (new_state),
    .mux_en                 (mux_en),
    .cache_hit              (cache_hit),
    .cache_miss             (cache_miss),
    .line_state             (line_state),
    .make_unique            (make_unique),
    .read_shared            (read_shared),
    .write_clean            (write_clean),
    .ac_enable              (ac_enable),
    .read_resp_en           (read_resp_en),
    .invalid                (invalid),
    .snoop_miss             (snoop_miss),
    .response               (response),
    .response_data          (response_data),
    .B_okay                 (B_okay),
    .R_okay                 (R_okay),
    .AC_SNOOP               (AC_SNOOP),
    .AC_PROT                (AC_PROT),
    .AC_ADDR                (AC_ADDR),
    .BRESP                  (BRESP),
    .B_ID                   (B_ID),
    .R_ID                   (R_ID),
    .R_LAST                 (R_LAST),
    .RRESP                  (RRESP),
    .RDATA                  (RDATA),
    .CR_RESP                (CR_RESP),
    .CD_LAST                (CD_LAST),
    .CD_DATA                (CD_DATA),
    .AR_ADDR                (AR_ADDR),
    .AR_ID                  (AR_ID),
    .AR_SIZE                (AR_SIZE),
    .AR_BURST               (AR_BURST),
    .AR_LEN                 (AR_LEN),
    .AR_PROT                (AR_PROT),
    .AR_CACHE               (AR_CACHE),
    .AR_BAR                 (AR_BAR),
    .AR_DOMAIN              (AR_DOMAIN),
    .AR_SNOOP               (AR_SNOOP),
    .AW_ADDR                (AW_ADDR),
    .AW_ID                  (AW_ID),
    .AW_SIZE                (AW_SIZE),
    .AW_BURST               (AW_BURST),
    .AW_LEN                 (AW_LEN),
    .AW_PROT                (AW_PROT),
    .AW_CACHE               (AW_CACHE),
    .AW_BAR                 (AW_BAR),
    .AW_DOMAIN              (AW_DOMAIN),
    .AW_SNOOP               (AW_SNOOP),
    .W_STRB                 (W_STRB),
    .W_LAST                 (W_LAST),
    .W_DATA                 (W_DATA)
);

// Cache Controller Instantiation (Assumed Ports)
cache_controller #(
    .WIDTH_STATE(WIDTH_STATE)
) cache_ctrl (
    .clk                    (clk),
    .rst_n                  (rst_n),
    .cpu_request            (cpu_request),
    .cache_hit              (cache_hit),
    .cache_miss             (cache_miss),
    .line_state             (line_state),
    .ace_ready              (ace_ready),
    .read_req               (read_req),
    .write_req              (write_req),
    .invalid_req            (invalid_req),
    .write_from_cpu         (write_from_cpu),
    .write_from_interconnect(write_from_interconnect),
    .new_state              (new_state),
    .state_sel              (mux_en),
    .cache_ready            (cache_ready),
    .cache_complete         (cache_complete)
);

// ACE Controller Instantiation (Assumed Ports)
ace_controller ace_ctrl (
    .clk          (clk),
    .rst_n        (rst_n),
    .read_req     (read_req),
    .write_req    (write_req),
    .invalid_req  (invalid_req),
    .ace_ready    (ace_ready),
    .B_okay       (B_okay),
    .R_okay       (R_okay),
    .invalid      (invalid),
    .snoop_miss   (snoop_miss),
    .response     (response),
    .response_data(response_data),
    .make_unique_o(make_unique),
    .read_shared_o(read_shared),
    .write_clean_o(write_clean),
    .ac_enable    (ac_enable),
    .read_resp_en (read_resp_en),
    .AW_VALID     (AW_VALID),
    .AW_READY     (AW_READY),
    .AR_VALID     (AR_VALID),
    .AR_READY     (AR_READY),
    .W_VALID      (W_VALID),
    .W_READY      (W_READY),
    .B_VALID      (B_VALID),
    .B_READY      (B_READY),
    .R_VALID      (R_VALID),
    .R_READY      (R_READY),

    .AC_VALID     (AC_VALID),
    .AC_READY     (AC_READY),

    .CR_READY     (CR_READY),
    .CR_VALID     (CR_VALID),
    .CD_READY     (CD_READY),
    .CD_VALID     (CD_VALID)
);

endmodule
