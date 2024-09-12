module cache_datapath #(
    parameter WIDTH_A = 32,
    parameter WIDTH_D = 32,
    parameter WIDTH_STATE = 3
) (
    input logic                    clk,
    input logic                    rst_n,

    // CPU --> Datapath
    input  logic [WIDTH_A-1:0]     cpu_addr,
    input  logic [WIDTH_D-1:0]     cpu_wdata,

    // Datapath --> CPU 
    output logic [WIDTH_D-1:0]     cpu_rdata,

    // Cache Controller --> Datapath
    input logic                    write_from_interconnect,
    input logic                    write_from_cpu,
    input logic [WIDTH_STATE-1:0]  new_state,

    // Datapath --> Cache Controller
    output logic                   cache_hit,
    output logic                   cache_miss,
    output logic [WIDTH_STATE-1:0] line_state, 
    
    // ACE Controller --> Datapath
    input  logic                   make_unique,
    input  logic                   read_shared,
    input  logic                   write_clean,

    // Datapath --> ACE Controller
    output logic                   invalid,
    output logic                   snoop_miss,
    output logic                   response,
    output logic                   response_data,
    output logic                   B_okay,
    output logic                   R_okay,

    // Interconnect --> Datapath
    // ** SNOOP ADDRESS CHANNEL 
    input  logic [3:0]             AC_SNOOP,
    input  logic [2:0]             AC_PROT,
    input  logic [WIDTH_A-1:0]     AC_ADDR, 
    
    // ** WRITE RESPNOSE CHANNEL
    input  logic [1:0]             BRESP,
    
    // ** READ DATA CHANNEL
    input  logic                   R_ID,
    input  logic                   R_LAST,
    input  logic [3:0]             RRESP,
    input  logic [WIDTH_D-1:0]     RDATA,

    // Datapath --> Interconnect
    // ** SNOOP RESPONSE CHANNEL
    output logic [4:0]             CR_RESP,

    // ** SNOOP DATA CHANNEL
    output logic                   CD_LAST,
    output logic [WIDTH_D-1:0]     CD_DATA

    // ** READ ADDRESS CHANNEL
    output logic [WIDTH_A-1:0]     AR_ADDR,
    output logic                   AR_ID,
    output logic [2:0]             AR_SIZE,
    output logic [1:0]             AR_BURST,
    output logic [7:0]             AR_LEN,
    output logic [2:0]             AR_PROT,
    output logic [3:0]             AR_CACHE,
    output logic [1:0]             AR_BAR,
    output logic [1:0]             AR_DOMAIN,
    output logic [3:0]             AR_SNOOP,

    // ** WRITE ADDRESS CHANNEL
    output logic [WIDTH_A-1:0]     AW_ADDR,
    output logic                   AW_ID,
    output logic [2:0]             AW_SIZE,
    output logic [1:0]             AW_BURST,
    output logic [7:0]             AW_LEN,
    output logic [2:0]             AW_PROT,
    output logic [3:0]             AW_CACHE,
    output logic [1:0]             AW_BAR,
    output logic [1:0]             AW_DOMAIN,
    output logic [2:0]             AW_SNOOP,
    
    
    // ** WRITE DATA CHANNEL
    output logic                   W_ID,
    output logic                   W_LAST,
    output logic [WIDTH_D-1:0]     W_DATA,
);

// CODE ...

endmodule