module cache_controller #(
    parameter WIDTH_STATE = 3
) (
    input logic                    clk,
    input logic                    rst_n,
    
    // Datapath --> Cache Controller 
    input  logic                   cache_hit,
    input  logic                   cache_miss,
    input  logic [WIDTH_STATE-1:0] line_state,

    // Cache Controller --> Datapath
    output logic                   write_from_cpu,
    output logic                   write_from_interconnect,
    output logic [WIDTH_STATE-1:0] new_state,

    // CPU --> Cache Controller
    input  logic [1:0]             cpu_request,

    // Cache Controller --> CPU
    output logic                   cache_ready,
    output logic                   cache_complete,

    // ACE Controller --> Cache Controller
    input logic                    ace_ready,
    
    // Cache Controller --> ACE Controller
    output logic                   read_req,
    output logic                   write_req,
    output logic                   invalid_req,
);

// CODE ...

endmodule