module tb_ace_controller;
    // Clock and Reset
    logic clk;
    logic rst_n;

    // Inputs to ace_controller
    logic read_req;
    logic write_req;
    logic invalid_req;
    
    // Outputs from ace_controller
    logic ace_ready;

    // Inputs from Datapath
    logic B_okay;
    logic R_okay;
    logic invalid;
    logic snoop_miss;
    logic response;
    logic response_data;

    // Outputs from ace_controller
    logic make_unique_o;
    logic read_shared_o;
    logic write_clean_o;
    logic miss_en;

    // Interconnect signals
    logic AW_READY;
    logic AW_VALID;
    logic W_READY;
    logic W_VALID;
    logic B_VALID;
    logic B_READY;
    logic AR_READY;
    logic AR_VALID;
    logic R_VALID;
    logic R_READY;
    logic AC_VALID;
    logic AC_READY;
    logic CR_READY;
    logic CR_VALID;
    logic CD_READY;
    logic CD_VALID;

    // Instantiate the ace_controller
    ace_controller uut (
        .clk(clk),
        .rst_n(rst_n),
        .read_req(read_req),
        .write_req(write_req),
        .invalid_req(invalid_req),
        .ace_ready(ace_ready),
        .B_okay(B_okay),
        .R_okay(R_okay),
        .invalid(invalid),
        .snoop_miss(snoop_miss),
        .response(response),
        .response_data(response_data),
        .make_unique_o(make_unique_o),
        .read_shared_o(read_shared_o),
        .write_clean_o(write_clean_o),
        .miss_en(miss_en),
        .AW_READY(AW_READY),
        .AW_VALID(AW_VALID),
        .W_READY(W_READY),
        .W_VALID(W_VALID),
        .B_VALID(B_VALID),
        .B_READY(B_READY),
        .AR_READY(AR_READY),
        .AR_VALID(AR_VALID),
        .R_VALID(R_VALID),
        .R_READY(R_READY),
        .AC_VALID(AC_VALID),
        .AC_READY(AC_READY),
        .CR_READY(CR_READY),
        .CR_VALID(CR_VALID),
        .CD_READY(CD_READY),
        .CD_VALID(CD_VALID)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10-time unit clock period
    end

    // Reset task
    task reset;
        begin
            rst_n = 0;
            repeat(10) @(posedge clk); // Hold reset for 2 clock cycles
            rst_n = 1;
            @(posedge clk);
        end
    endtask

    // Signal instantiation task
    task initialize_signals;
        begin
            read_req = 0;
            write_req = 0;
            invalid_req = 0;
            B_okay = 0;
            R_okay = 0;
            invalid = 0;
            snoop_miss = 0;
            response = 0;
            response_data = 0;
            AW_READY = 1;
            W_READY = 1;
            B_VALID = 0;
            AR_READY = 1;
            R_VALID = 0;
            AC_VALID = 0;
            CR_READY = 1;
            CD_READY = 1;
        end
    endtask

    // Task to drive write request
    task drive_write_request;
        begin
            write_req = 1;
            AW_READY = 1;
            @(posedge clk);
            write_req = 0;
            // @(posedge clk);
            while(!AW_VALID) @(posedge clk);
            AW_READY = 0;

            W_READY = 1;
            @(posedge clk);
            while(!W_VALID) @(posedge clk);
            W_READY = 0;

            B_VALID = 1;
            B_okay = 1;
            @(posedge clk);
            while(!B_READY) @(posedge clk);
            B_VALID = 0;

            while(!ace_ready) @(posedge clk);

        end
    endtask

    // Task to drive read request
    task drive_read_request;
        begin
            read_req = 1;
            // @(posedge clk);

            // SUppose a condition when Response in not OKAY
            repeat(5) begin
                AR_READY = 1;
                @(posedge clk);
                read_req = 0;
                while(!AR_VALID) @(posedge clk);
                AR_READY = 0;

                R_VALID = 1;
                R_okay = 0;
                @(posedge clk);
                while(!R_READY) @(posedge clk);
                R_VALID = 0;
            end
            AR_READY = 1;
            @(posedge clk);
            while(!AR_VALID) @(posedge clk);
            AR_READY = 0;

            R_VALID = 1;
            R_okay = 1;
            @(posedge clk);
            while(!R_READY) @(posedge clk);
            R_VALID = 0;
            

            while(!ace_ready) @(posedge clk);
        end
    endtask

    // Task to drive invalid request
    task drive_invalid_request;
        begin
            invalid_req = 1;
            AR_READY = 1;
            @(posedge clk);
            invalid_req = 0;
            while(!AR_VALID) @(posedge clk);
            AR_READY = 0;

            R_VALID = 1;
            R_okay = 1;
            @(posedge clk);
            while(!R_READY) @(posedge clk);
            R_VALID = 0;
            
            while(!ace_ready) @(posedge clk);
        end
    endtask

    // Task to drive snoop miss
    task drive_snoop_miss;
        begin
            AC_VALID = 1;
            @(posedge clk);
            while(!AC_READY) @(posedge clk);
            AC_VALID = 0;
            snoop_miss = 1;
            CR_READY = 1;
            @(posedge clk);
            snoop_miss = 0;
            while(!CR_VALID) @(posedge clk);
            CR_READY = 0;
            while(!AC_READY) @(posedge clk);
        end
    endtask

    // Task to drive response
    task drive_response;
        begin
            AC_VALID = 1;
            @(posedge clk);
            while(!AC_READY) @(posedge clk);
            AC_VALID = 0;
            response = 1;
            CR_READY = 0;
            @(posedge clk);
            response = 0;
            while(!CR_VALID) @(posedge clk);
            repeat(5) @(posedge clk);
            CR_READY = 1;
            @(posedge clk);
            CR_READY = 0;
            while(!AC_READY) @(posedge clk);
        end
    endtask

    // Monitor task
    task monitor_controller_side;
        forever begin
            while(!(read_req || write_req || invalid_req)) @(posedge clk);
            $display("ACE CONTROLLER ACTIVATED");
            @(posedge clk);
            while(!ace_ready) @(posedge clk);
            $display("REQUEST SUCCESS");
        end       
    endtask

    task monitor_interconnect_side;
        forever begin
            @(posedge clk);
            while(!AC_READY) @(posedge clk);
            $display("SNOOP INITIATED");
            @(posedge clk);
            while(!AC_READY) @(posedge clk);
            $display("SNOOP COMPLETED");
        end
    endtask

    task call_request;
        begin
            logic [1:0] local_var;
            repeat(10) begin
                local_var = $random;
                case(local_var) 
                    2'b00: drive_read_request();
                    2'b01: drive_invalid_request();
                    2'b10: drive_write_request();
                    default: drive_read_request();
                endcase
            end
        end
    endtask

    // Testbench execution
    initial begin
        // Initialize inputs
        initialize_signals();
        // Apply reset
        reset();

        // call_request will call read, write and invalid requests randomly
        call_request();

        // Test case for incoming snoop request 
        // -- with snoop miss
        drive_snoop_miss();
        // -- with snoop hit
        drive_response();

        

        // join_any
        // fork
        //     monitor_controller_side();
        // join_any

        // Finish simulation
        @(posedge clk);
        $finish;
    end

    initial begin
        $dumpfile("ace_controller.vcd");
        $dumpvars(0);
    end

endmodule