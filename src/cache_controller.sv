module cache_controller #(
    parameter WIDTH_STATE = 3
) (
    input logic       clk,
    input logic       reset,

	// cache Datapath -> cache controller
    input logic       cache_hit,
    input logic       cache_miss,
    input logic [WIDTH_STATE-1:0] line_state,
    
    // cpu -> cache controller
    input logic [1:0] cpu_request,
    
    // ace controller -> cache controller
    input logic       ace_ready,

	// cache controller -> ace controller
    output logic      read_req,
    output logic      write_req,
    output logic      invalid_req,
    
    // cache controller -> cache datapath 
    output logic      write_from_cpu,
    output logic      write_from_interconnect,
    output logic [WIDTH_STATE-1:0] new_state,
    output logic      state_sel,

    // cache controller -> cpu
    output logic      cache_complete,
    output logic      cache_ready
);

typedef enum logic [2:0] {
    IDLE            = 3'b000,
    PROCESS_REQUEST = 3'b001,
    ALLOCATE_MEMORY = 3'b010,
    WRITEBACK       = 3'b011,
    INVALIDATE      = 3'b100
} state_t;

state_t state, next_state;

logic read_en, write_en;
logic read_hit_en, write_hit_en;
logic current_UC, current_UD, current_SC, current_SD, current_invalid;
logic new_UC, new_UD, new_SC, new_SD, new_invalid;
logic [4:0] state_select;

// Decoding cache tasks
assign read_en     = (cpu_request == 2'b00) ? 1 : 0;
assign write_en    = (cpu_request == 2'b01) ? 1 : 0;
assign no_task     = (cpu_request == 2'b11) ? 1 : 0;

// Decoding current cache state logic
assign current_UC  = (line_state == 3'b000) ? 1 : 0;
assign current_UD  = (line_state == 3'b001) ? 1 : 0;
assign current_SC  = (line_state == 3'b010) ? 1 : 0;
assign current_SD  = (line_state == 3'b011) ? 1 : 0;
assign current_invalid  = (line_state == 3'b100) ? 1 : 0;

// Encoding next cache state logic
always_comb begin
    // new_state = 3'b111; // Default state
    // Encode states into a single selection vector
    state_select = {new_UC, new_UD, new_SC, new_SD, new_invalid};
    // Use the combined vector to decide the new state
    case (state_select)
        5'b10000: new_state = 3'b000; // new_UC
        5'b01000: new_state = 3'b001; // new_UD
        5'b00100: new_state = 3'b010; // new_SC
        5'b00010: new_state = 3'b011; // new_SD
        5'b00001: new_state = 3'b100; // new_invalid
        default:  new_state = 3'b100; // Fallback state
    endcase
end

always_ff @(posedge clk or negedge reset) begin
    if(!reset) begin
        write_hit_en <= 1'b0;
        read_hit_en  <= 1'b0;
    end else if(read_en) begin
        write_hit_en <= 1'b0;
        read_hit_en  <= 1'b1;
    end else if(write_en) begin
        write_hit_en <= 1'b1;
        read_hit_en  <= 1'b0;
    end
end

always_ff @(posedge clk or negedge reset) begin
    if(!reset) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

always_comb begin
    cache_ready         = 0;
    cache_complete      = 0;
    read_req            = 0;
    write_req           = 0;
    invalid_req         = 0;
    write_from_cpu      = 0;
    write_from_interconnect = 0;
    new_UC              = 0;
    new_UD              = 0;
    new_SC              = 0;
    new_SD              = 0;
    new_invalid         = 0;
    state_sel           = 0;
    case(state)
        IDLE: begin
            cache_ready         = 1;
            if((read_en || write_en)) begin
                next_state = PROCESS_REQUEST;
            end else begin
                next_state = IDLE;
            end
        end

        PROCESS_REQUEST: begin
            if(cache_hit && read_hit_en) begin
                cache_ready     = 1;
                cache_complete  = 1;
                next_state      = IDLE;
            end 
            else if(cache_hit && write_hit_en && (current_UC || current_UD)) begin
                write_from_cpu  = 1;
                cache_ready     = 1;
                cache_complete  = 1;
                state_sel       = 1;
                new_UD          = 1;
                next_state      = IDLE;
            end
            else if (cache_hit && current_invalid && write_hit_en) begin
                invalid_req     = 1;
                next_state      = INVALIDATE;
            end
            else if ((current_invalid && read_hit_en) || (cache_miss && !(current_SD || current_UD))) begin
                read_req    = 1;
                next_state  = ALLOCATE_MEMORY;    
            end 
            else if(cache_miss && (current_SD || current_UD)) begin
                write_req   = 1;
                state_sel   = 1;
                if (current_SD) begin
                    new_SC      = 1;
                end
                if (current_UD) begin
                    new_UC    = 1;
                end
                next_state  = WRITEBACK;
            end 
            else if(cache_hit && write_hit_en && (current_SC || current_SD)) begin
                invalid_req = 1;
                state_sel   = 1;
                if (current_SC) begin
                    new_UC      = 1;
                end
                if (current_SD) begin
                    new_UD    = 1;
                end
                next_state  = INVALIDATE;
            end 
            else begin
                next_state  = PROCESS_REQUEST;
            end

        end

        ALLOCATE_MEMORY: begin
            if (ace_ready) begin
                write_from_interconnect = 1;
                next_state          = PROCESS_REQUEST;
            end
            else if(!ace_ready) begin
                read_req   = 1;
                next_state = ALLOCATE_MEMORY;
            end
        end

        WRITEBACK: begin
            if(!ace_ready) begin
                next_state = WRITEBACK;
                write_req  = 1; 
            end 
            else if (ace_ready) begin
                read_req    = 1;
                next_state  = ALLOCATE_MEMORY;
            end
        end

        INVALIDATE: begin
            if(!ace_ready) begin
                next_state = INVALIDATE; 
            end 
            else if(ace_ready) begin
                cache_complete  = 1;
                cache_ready     = 1;
                new_UD          = 1;
                state_sel       = 1;
                write_from_cpu  = 1;
                next_state = IDLE;
            end 
        end

        default: begin
            next_state = IDLE;
        end
    endcase
end

endmodule