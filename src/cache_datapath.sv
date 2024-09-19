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
    input logic                    mux_en,

    // Datapath --> Cache Controller
    output logic                   cache_hit,
    output logic                   cache_miss,
    output logic [WIDTH_STATE-1:0] line_state, 
    
    // ACE Controller --> Datapath
    input  logic                   make_unique,
    input  logic                   read_shared,
    input  logic                   write_clean,
    input  logic                   ac_enable,
    input  logic                   read_resp_en,

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
    input  logic                   B_ID,
    
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
    output logic [WIDTH_D-1:0]     CD_DATA,

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
    output logic                   W_STRB,
    output logic                   W_LAST,
    output logic [WIDTH_D-1:0]     W_DATA
);
typedef struct packed {
    logic [31:0] data;
    logic [26:0] tag;
    logic        valid_bit;
    logic [2:0]  state;
} cache_line;
  
cache_line cache [7:0];             // cache lines

logic [26:0] tag, tag_snoop;
logic [2:0] index, index_snoop;
logic [1:0]block_offset_snoop, block_offset;
logic [2:0] next_state_r, next_state_ac, next_state;
logic check_dirty;
// CR_RESP bits 
logic is_shared;


// Assign current state of a cache line as output to the cache controller
assign line_state = cache[index].state;

assign  tag          = cpu_addr[31:5]; // 27 bits
assign  index        = cpu_addr[4:2];
assign  block_offset = cpu_addr[1:0];

assign tag_snoop = AC_ADDR[31:5];
assign index_snoop = AC_ADDR[4:2];
assign block_offset_snoop = AC_ADDR[1:0];

// Checking Tag And Valid Bit
always_comb begin
    if (cache[index].tag == tag && cache[index].valid_bit == 1) begin    
        cache_hit = 1;
        cache_miss = 0;
    end else begin
        cache_hit  = 0;
        cache_miss = 1;
    end
end

// Check for hit or miss on Snoop request from interconnect
always_comb begin
    if((cache[index_snoop].tag == tag_snoop) && (cache[index_snoop].valid_bit == 1)) begin
        snoop_miss = 0;
    end else begin
        snoop_miss = 1;
    end
end

// Invalid signal to ace controller indicating the requested line by snoop is in invalid state or not
assign invalid = (cache[index_snoop].state == 3'b100) ? 1'b1 : 1'b0;

// This value indicate that Cache is a write-back cache
assign AW_CACHE = 4'b1010;
assign AR_CACHE = 4'b1010;

// Write response and read response message to Ace controller
always_comb begin
    if(BRESP == 00 || BRESP == 01) begin
        B_okay = 1;
    end else begin
        B_okay = 0;
    end
end

always_comb begin
    if(RRESP[1:0] == 00 || RRESP[1:0] == 01) begin
        R_okay = 1;
    end else begin
        R_okay = 0;
    end
end      

// Check the response on Read Data channel to determine the next state of a cache line
always_comb begin
    if(!read_resp_en) begin
        next_state_r = cache[index].state;
    end else begin
        case(RRESP[3:2])
            2'b00: next_state_r = 3'b000;
            2'b01: next_state_r = 3'b001;
            2'b10: next_state_r = 3'b010;
            2'b11: next_state_r = 3'b011;
            default: next_state_r = cache[index].state;
        endcase
    end
end

// Mux to select new state of cache line between input from the interconnect and from cache controller
always_comb begin
    if(mux_en) begin
        next_state = new_state;
    end else begin
        next_state = next_state_r;
    end
end

always_comb begin
    if(write_clean) begin
        AW_BAR[0] = 0;
        AW_DOMAIN = 2'b00;
        AW_SNOOP = 3'b010;
    end else if(read_shared) begin
        AR_BAR[0] = 0;
        AR_DOMAIN = 2'b10;
        AR_SNOOP = 4'b0001;
    end else if(make_unique) begin
        AR_BAR[0] = 0;
        AR_DOMAIN = 2'b10;
        AR_SNOOP = 4'b1100;
    end
end

assign CD_DATA = cache[index_snoop].data;
assign CD_LAST = 1'b1;
assign check_dirty = ((cache[index_snoop].state == 3'b001) || (cache[index_snoop].state == 3'b011)) ? 1'b1 : 1'b0;
assign is_shared = ((cache[index_snoop].state == 3'b010) || (cache[index_snoop].state == 3'b011)) ? 1'b1 : 1'b0;

always_comb begin
    if(!ac_enable) begin
        next_state_ac = cache[index_snoop].state;
    end else begin
        case(AC_SNOOP) 
            4'b0000: begin
                // READ ONCE
                response_data = 1;
                response = 0;
                next_state_ac = cache[index_snoop].state;
                if(snoop_miss || invalid) begin
                    CR_RESP = 5'b00000;
                end else begin
                    CR_RESP = 5'b01001;
                    // if(pass_dirty && is_shared) begin
                    //     CR_RESP = 5'b01101;
                    // end else if(pass_dirty) begin
                    //     CR_RESP = 5'b00101;
                    // end else if(is_shared) begin
                    //     CR_RESP = 5'b01001;
                    // end else begin
                    //     CR_RESP = 5'b00001;
                    // end
                end
            end
            4'b0001, 4'b0010, 4'b0011: begin
                // READ SHARED && READ CLEAN && READ NOT SHARED DIRTY
                response_data = 1;
                response = 0;
                if(snoop_miss || invalid) begin
                    CR_RESP = 5'b00000;
                    next_state_ac = cache[index_snoop].state;
                end else begin
                    CR_RESP = 5'b01001;
                    if(check_dirty) begin
                        next_state_ac = 3'b011; // Shared Dirty
                    end else begin
                        next_state_ac = 3'b010; // Shared Clean
                    end
                end
            end
            4'b0111: begin
                // READ UNIQUE
                response = 0;
                response_data = 1;
                next_state_ac = 3'b100; // Invalid state
                if(snoop_miss || invalid) begin
                    CR_RESP = 5'b00000;
                end else begin
                    if(check_dirty) begin
                        CR_RESP = 5'b00101;
                    end else begin
                        CR_RESP = 5'b00001;
                    end
                end
            end
            default: begin
                response = 0;
                response_data = 0;
                next_state_ac = cache[index_snoop].state;
                CR_RESP = 5'b00000;
            end
        endcase
    end
end



// Read, write address and write data channel signals
assign AR_ADDR = cpu_addr; 
assign AW_ADDR = {cache[index].tag, index, block_offset};
assign W_DATA = cache[index].data; 
assign W_LAST = 1'b1;



// Asynchronous Read
assign cpu_rdata = cache[index].data;

// Synchronous Write
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (int i = 0; i < 8; i++) begin
            cache[i].valid_bit <= 0;
            cache[i].tag       <= 0;
            cache[i].state     <= 3'b100; // Invalid
            cache[i].data      <= 0;
        end
    end
    // Writing Data From CPU To Cache
    else if (write_from_cpu) begin
        cache[index].valid_bit <= 1;
        cache[index].data      <= cpu_wdata;
        cache[index].state     <= next_state;  
    end 
    // Writing Data From Main Mem To Cache
    else if (write_from_interconnect) begin                         
        cache[index].valid_bit <= 1;
        cache[index].state     <= next_state;
        cache[index].data      <= RDATA;
        cache[index].tag       <= tag; 
    end 
    else begin
        cache[index_snoop].state <= next_state_ac;
        cache[index].state       <= next_state;
    end

end

endmodule
