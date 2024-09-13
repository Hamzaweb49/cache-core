module tb_cache_controller;

    // Testbench signals
    logic       clk;
    logic       reset;
    logic       cache_hit;
    logic       cache_miss;
    logic [2:0] line_state;
    logic [1:0] cpu_request;
    logic       ace_ready;

    logic       read_req;
    logic       write_req;
    logic       invalid_req;
    logic       write_from_cpu;
    logic       write_from_interconnect;
    logic [2:0] new_state;
    logic       cache_complete;
    logic       cache_ready;

    // Instantiate the cache controller module
    cache_controller uut (
        .clk(clk),
        .reset(reset),
        .cache_hit(cache_hit),
        .cache_miss(cache_miss),
        .line_state(line_state),
        .cpu_request(cpu_request),
        .ace_ready(ace_ready),
        .read_req(read_req),
        .write_req(write_req),
        .invalid_req(invalid_req),
        .write_from_cpu(write_from_cpu),
        .write_from_interconnect(write_from_interconnect),
        .new_state(new_state),
        .cache_complete(cache_complete),
        .cache_ready(cache_ready)
    );

    // Generate clock
    initial begin
        clk = 1; 
        forever #5 clk = ~clk;
    end

    // Task to reset the cache controller
    task reset_controller;
        begin
            reset = 1;
            @(posedge clk);
            reset = 0;
            @(posedge clk);
            reset = 1;
        end
    endtask

    // Task to send a read request from the CPU
    task cpu_read_request;
        begin
            cpu_request = 2'b00;  // Read request
            @(posedge clk);
        end
    endtask

    // Task to send a write request from the CPU
    task cpu_write_request;
        begin
            cpu_request = 2'b01;  // Write request
            @(posedge clk);
        end
    endtask

    // Task to simulate a cache hit and miss
    task simulate_cache_hit_and_miss;
        input logic hit, miss;
        begin
            cache_hit = hit;
            cache_miss = miss;
            @(posedge clk);
            cache_hit = 0;
            cache_miss = 0;
        end
    endtask

    // Task to simulate ace_ready signal
    task simulate_ace_ready;
        input logic ready;
        begin
            ace_ready = ready;
            @(posedge clk);
            ace_ready = 0;
        end
    endtask

    // Task to simulate line state changes
    task set_line_state;
        input [2:0] state;
        begin
            line_state = state;
            @(posedge clk);
        end
    endtask

    // Main test sequence
    initial begin
        // Initialize signals
        clk = 0;
        reset = 0;
        cache_hit = 0;
        cache_miss = 0;
        line_state = 3'b000;
        cpu_request = 2'b00;
        ace_ready = 0;

        // Reset the controller
        reset_controller();

        // Test case 1: CPU read request with cache hit
        $display("Test Case 1: CPU Read Request with Cache Hit");
        cpu_read_request();
        simulate_cache_hit_and_miss(1, 0);  // Cache hit
        simulate_ace_ready(1);

        // Test case 2: CPU write request with cache miss
        $display("Test Case 2: CPU Write Request with Cache Miss");
        cpu_write_request();
        simulate_cache_hit_and_miss(0, 1);  // Cache miss
        simulate_ace_ready(1);

        // Test case 3: Set line state to different states
        $display("Test Case 4: Line State Changes");
        set_line_state(3'b001);  // Change line state to 001 (UC)
        set_line_state(3'b010);  // Change line state to 010 (SC)
        set_line_state(3'b100);  // Change line state to 100 (Invalid)

        // End simulation
        $stop;
    end

endmodule
