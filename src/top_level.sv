module top_level #( 
    parameter WIDTH_A = 32,
    parameter WIDTH_D = 32
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

//  CODE ...

endmodule