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

// Define the states of the Controller
typedef enum logic [3:0]{
    IDLE        = 4'b0000,
    WADDR       = 4'b0001,
    WDATA       = 4'b0010,
    BRESP       = 4'b0011,
    RADDR       = 4'b0100,
    RDATA       = 4'b0101,
    CHECK_SNOOP = 4'b0110,
    CRESP_DATA  = 4'b0111,
    CRESP       = 4'b1000
} state_t;

state_t current_state, next_state;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
end

// Next state and Output logic
always_comb begin
    case(current_state) 
        IDLE: begin
            ace_ready     = 0;
            make_unique_o = 0;
            read_shared_o = 0;
            write_clean_o = 0;
            miss_en       = 0;
            AW_VALID      = 0;
            AR_VALID      = 0;
            W_VALID       = 0;
            B_READY       = 0;
            R_READY       = 0;
            AC_READY      = 1;
            CR_VALID      = 0;
            CD_VALID      = 0; 

            if(write_req) begin
                AW_VALID      = 1;
                write_clean_o = 1;
                if(!AW_READY) begin
                    next_state = WADDR;
                end else begin
                    next_state = WDATA;
                end
            end else if(read_req || invalid_req) begin
                AR_VALID = 1;
                if(!AR_READY) begin
                    next_state = RADDR;
                end else begin
                    next_state = RDATA;
                end
                if(read_req) begin
                    read_shared_o = 1;
                end else begin
                    make_unique_o = 1;
                end
            end else if(AC_VALID) begin
                next_state = CHECK_SNOOP;
            end else begin
                next_state = IDLE;
            end
        end
        WADDR: begin
            ace_ready     = 0;
            make_unique_o = 0;
            read_shared_o = 0;
            write_clean_o = 0;
            miss_en       = 0;
            AW_VALID      = 1;
            AR_VALID      = 0;
            W_VALID       = 0;
            B_READY       = 0;
            R_READY       = 0;
            AC_READY      = 0;
            CR_VALID      = 0;
            CD_VALID      = 0; 

            if(!AW_READY) begin
                next_state = WADDR;
            end else begin
                next_state = WDATA;
            end
        end
        WDATA: begin
            ace_ready     = 0;
            make_unique_o = 0;
            read_shared_o = 0;
            write_clean_o = 0;
            miss_en       = 0;
            AW_VALID      = 0;
            AR_VALID      = 0;
            W_VALID       = 1;
            B_READY       = 0;
            R_READY       = 0;
            AC_READY      = 0;
            CR_VALID      = 0;
            CD_VALID      = 0; 

            if(!W_READY) begin
                next_state = WDATA;
            end else begin
                next_state = BRESP;
            end
        end
        BRESP: begin
            ace_ready     = 0;
            make_unique_o = 0;
            read_shared_o = 0;
            write_clean_o = 0;
            miss_en       = 0;
            AW_VALID      = 0;
            AR_VALID      = 0;
            W_VALID       = 0;
            B_READY       = 1;
            R_READY       = 0;
            AC_READY      = 0;
            CR_VALID      = 0;
            CD_VALID      = 0; 

            if(!B_VALID) begin
                next_state = BRESP;
            end else begin
                if(B_okay) begin
                    next_state = IDLE;
                    ace_ready  = 1;
                end else if (!AR_READY) begin
                    next_state = WADDR;
                    AW_VALID   = 1;
                end else begin
                    next_state = WDATA;
                    AW_VALID   = 1;
                end
            end
        end
        RADDR: begin
            ace_ready     = 0;
            make_unique_o = 0;
            read_shared_o = 0;
            write_clean_o = 0;
            miss_en       = 0;
            AW_VALID      = 0;
            AR_VALID      = 1;
            W_VALID       = 0;
            B_READY       = 0;
            R_READY       = 0;
            AC_READY      = 0;
            CR_VALID      = 0;
            CD_VALID      = 0;

            if(!AR_READY) begin
                next_state = RADDR;
            end else begin 
                next_state = RDATA;
                R_READY    = 1;
            end
        end
        RDATA: begin
            ace_ready     = 0;
            make_unique_o = 0;
            read_shared_o = 0;
            write_clean_o = 0;
            miss_en       = 0;
            AW_VALID      = 0;
            AR_VALID      = 0;
            W_VALID       = 0;
            B_READY       = 1;
            R_READY       = 0;
            AC_READY      = 0;
            CR_VALID      = 0;
            CD_VALID      = 0; 

            if(!R_VALID) begin
                next_state = RDATA;
            end else begin
                if(R_okay) begin
                    next_state = IDLE;
                    ace_ready  = 1;
                end else if(!AR_READY) begin
                    next_state = RADDR;
                    AR_VALID   = 1;
                end else begin
                    next_state = RDATA;
                    AR_VALID   = 1;
                end
            end
        end
        CHECK_SNOOP: begin
        end
    endcase

end

endmodule