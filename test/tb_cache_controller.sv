module tb_cache_controller;

    // Testbench signals
    logic clk, reset;                              // Clock and reset signals
    logic cache_hit, cache_miss;                   // Cache hit and miss signals
    logic ace_ready;                               // ACE protocol ready signal
    logic [2:0] line_state;                        // Cache line state
    logic [1:0] cpu_request;                       // CPU request signal (2-bit)

    // Output signals from UUT (Unit Under Test)
    logic read_req, write_req, invalid_req;        // Request signals for read, write, and invalidate
    logic write_from_cpu, write_from_interconnect; // Write sources from CPU or interconnect
    logic [2:0] new_state;                         // New state of the cache line
    logic state_sel;                               // State selection signal
    logic cache_complete, cache_ready;             // Cache operation complete and ready flags

    // Randomized input signals for testing
    logic [1:0] random_cpu_request;                // Random CPU request (2-bit)
    logic random_ace_ready;                        // Random ACE ready signal

    // Reference model signals (expected values)
    logic ref_cache_ready, ref_cache_complete;     // Reference model output signals for cache readiness and completeness
    logic ref_read_req, ref_write_req, ref_invalid_req;    // Reference signals for requests
    logic ref_write_from_cpu, ref_write_from_interconnect; // Reference write source signals
    logic [2:0] ref_new_state;                     // Expected new state
    logic ref_state_sel;                           // Expected state selection signal

    // Instantiate cache controller (Unit Under Test - UUT)
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
        .state_sel(state_sel),
        .cache_complete(cache_complete),
        .cache_ready(cache_ready)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // 100MHz clock
    end

    // Task for initialization of signals
    task init;
        begin
            clk = 0;
            reset = 0;
            cache_hit = 0;
            cache_miss = 0;
            ace_ready = 0;
            line_state = 3'b000;
            cpu_request = 2'b11;
            random_cpu_request = 2'b11;
            random_ace_ready = 0;
            ref_cache_ready = 0;
            ref_cache_complete = 0;
            ref_read_req = 0;
            ref_write_req = 0;
            ref_invalid_req = 0;
            ref_write_from_cpu = 0;
            ref_write_from_interconnect = 0;
            ref_new_state = 3'b000;
            ref_state_sel = 0;
        end
    endtask

    // Task for reset sequence
    task reset_dut;
        begin
            reset = 0; // Assert reset
            repeat(10) @(posedge clk);
            reset = 1; // Deassert reset
        end
    endtask

    // Task to drive inputs using randomized values
    task driver();
        integer i;
        begin
            for (i = 0; i < 200; i = i + 1) begin
                @(posedge clk);                    // Wait for the next clock cycle
                random_cpu_request = $urandom % 4; // Generate random 2-bit CPU request
                // Check if cpu_request is 10, and if so, change it to 00
                if (random_cpu_request == 2'b10) begin
                    random_cpu_request = 2'b00;
                end
                // Check if cpu_request is 11, and if so, change it to 01
                else if (random_cpu_request == 2'b11) begin
                    random_cpu_request = 2'b01;
                end
                random_ace_ready = $urandom % 2;   // Generate random ACE ready signal
                drive_inputs(random_cpu_request, random_ace_ready);
                @(posedge clk);                    // Wait for the next clock cycle
            end
        end
    endtask

    // Task to apply inputs to the DUT
    task drive_inputs(
        input logic [1:0] request,
        input logic ace_ready_in
    );
        begin
            cpu_request = request;                 // Drive CPU request input
            ace_ready = ace_ready_in;              // Drive ACE ready input

            // Randomize cache hit/miss and line state for testing
            cache_hit = $urandom % 2;              // Randomly assign cache hit 
            cache_miss = ~cache_hit;               // Cache miss is inverse of hit
            line_state = $urandom % 8;             // Randomize line state (3-bit)

            // Wait for cache to be ready
            while (!cache_ready) @(posedge clk);

            @(posedge clk);                        // Wait for the next clock cycle
        end
    endtask

    // Reference model to generate expected outputs based on inputs
    task reference_model();
        forever begin
            @(posedge clk); // Wait for clock edge
            // Initialize reference model outputs
            ref_cache_ready = 0;
            ref_cache_complete = 0;
            ref_read_req = 0;
            ref_write_req = 0;
            ref_invalid_req = 0;
            ref_write_from_cpu = 0;
            ref_write_from_interconnect = 0;
            ref_new_state = 3'b000;
            ref_state_sel = 0;

            // Reference model logic simulating expected behavior based on cache miss and line state
            if (cache_miss) begin
                if (line_state == 3'b011 || line_state == 3'b001) begin
                    ref_write_req = 1;
                    ref_state_sel = 1;
                    ref_new_state = (line_state == 3'b011) ? 3'b011 : 3'b000;
                end 
                else if (!(line_state == 3'b011 || line_state == 3'b001)) begin
                    ref_read_req = 1;
                end
            end

            // Expected behavior based on CPU request
            case (cpu_request)
                2'b00: begin
                    if (cache_hit) begin
                        ref_cache_ready = 1;
                        ref_cache_complete = 1;
                    end else if (line_state == 3'b100) begin
                        ref_read_req = 1;
                    end
                end
                2'b01: begin
                    if (cache_hit) begin
                        ref_cache_ready = 1;
                        ref_cache_complete = 1;
                        ref_write_from_cpu = 1;
                        ref_new_state = 3'b001;
                    end else if (line_state == 3'b100) begin
                        ref_invalid_req = 1;
                    end
                end
                default: begin
                    ref_cache_ready = cache_ready;
                    ref_cache_complete = cache_complete;
                end
            endcase

            @(posedge clk); // Wait for the next clock edge
        end
    endtask

    // Monitor task to check UUT outputs against the reference model
    task monitor();
        forever begin
            @(posedge clk); // Wait for clock edge

            @(posedge clk); // Wait for the next clock edge
            while(!(cache_ready && cache_complete && read_req && write_req && invalid_req && write_from_cpu && write_from_interconnect && new_state && state_sel)) @(posedge clk)
            
            // Compare the reference model with actual output from UUT
            if (cache_ready !== ref_cache_ready ||
                cache_complete !== ref_cache_complete ||
                read_req !== ref_read_req ||
                write_req !== ref_write_req ||
                invalid_req !== ref_invalid_req ||
                write_from_cpu !== ref_write_from_cpu ||
                write_from_interconnect !== ref_write_from_interconnect ||
                new_state !== ref_new_state ||
                state_sel !== ref_state_sel) 
            begin
                $display("ERROR: Cache Controller Output Mismatch at time %0t", $time);
                $display("Expected - cache_ready: %b, cache_complete: %b, read_req: %b, write_req: %b, invalid_req: %b, write_from_cpu: %b, write_from_interconnect: %b, new_state: %b, state_sel: %b",
                    ref_cache_ready, ref_cache_complete, ref_read_req, ref_write_req, ref_invalid_req, ref_write_from_cpu, ref_write_from_interconnect, ref_new_state, ref_state_sel);
                $display("Actual   - cache_ready: %b, cache_complete: %b, read_req: %b, write_req: %b, invalid_req: %b, write_from_cpu: %b, write_from_interconnect: %b, new_state: %b, state_sel: %b",
                    cache_ready, cache_complete, read_req, write_req, invalid_req, write_from_cpu, write_from_interconnect, new_state, state_sel);
            end else begin
                $display("Monitor Passed: Cache Controller working correctly for CPU request %b at time %0t", cpu_request, $time);
            end
        end
    endtask

    // Main testbench flow
    initial begin
        init();         // Initialize signals
        reset_dut();    // Apply reset

        // Start the monitor task in parallel
        fork
            reference_model();
            monitor(); // Continuous monitoring
        join_none

        // Drive the inputs using the driver task
        driver();

        $finish;
    end

    // VCD dump for waveform analysis
    initial begin
        $dumpfile("cache_controller.vcd");   // Output file for waveform
        $dumpvars(0);                        // Dump all variables
    end

endmodule