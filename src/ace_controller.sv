module ace_controller (
    input logic clk,
    input logic rst_n,
    
    // Cache Controller --> Ace Controller
    input  logic read_req,
    input  logic write_req,
    input  logic invalid_req,
    
    // Ace Controller --> Cache Controller
    output logic ace_ready,

    // Datapath --> Ace Controller
    input  logic B_okay,
    input  logic R_okay,
    input  logic invalid,
    input  logic snoop_miss,
    input  logic response,
    input  logic response_data,
    
    // Ace Controller --> Datapath
    output logic make_unique_o,
    output logic read_shared_o,
    output logic write_clean_o,
    output logic miss_en,

    // Input: Interconnect --> Ace Controller |----| Output: Ace Controller --> Interconnect
    // ** WRITE ADDRESS CHANNEL
    // -- Input 
    input  logic AW_READY,
    // -- Output  
    output logic AW_VALID,

    // ** WRITE DATA CHANNEL
    // -- Input  
    input  logic W_READY,
    // -- Output  
    output logic W_VALID,

     // ** WRITE RESPNOSE CHANNEL
    // -- Input 
    input  logic B_VALID,
    // -- Output 
    output logic B_READY,

     // ** READ ADDRESS CHANNEL
    // -- Input 
    input  logic AR_READY,
    // -- Output  
    output logic AR_VALID,

    // ** READ DATA CHANNEL
    // -- Input
    input  logic R_VALID,
    // -- Output 
    output logic R_READY,

    // ** SNOOP ADDRESS CHANNEL 
    // -- Input 
    input  logic AC_VALID,
    // -- Output 
    output logic AC_READY,

     // ** SNOOP RESPONSE CHANNEL
    // -- Input 
    input  logic CR_READY,
    // -- Output 
    output logic CR_VALID,

     // ** SNOOP DATA CHANNEL
    // -- Input 
    input  logic CD_READY,
    // -- Output 
    output logic CD_VALID
);

// CODE ...

endmodule