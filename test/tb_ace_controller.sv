
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
    logic read_resp_en;
    logic ac_enable;

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

    // Expected outputs for monitoring
    logic expected_ace_ready;
    logic expected_make_unique;
    logic expected_write_clean;
    logic expected_read_shared;
    logic expected_ac_enable;
    logic expected_read_resp_en;

    logic expected_AC_READY;
    logic expected_AR_VALID;
    logic expected_AW_VALID;
    logic expected_B_READY;
    logic expected_W_VALID;
    logic expected_CD_VALID;
    logic expected_CR_VALID;
    logic expected_R_READY;

    integer pass_count = 0;
    integer fail_count = 0;
    integer pass_count_int = 0;
    integer fail_count_int = 0;

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
        // .miss_en(miss_en),
        .ac_enable(ac_enable),
        .read_resp_en(read_resp_en),
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

            B_VALID = 1'b1;
            B_okay = 1'b1;
            @(posedge clk);
            while(!B_READY) @(posedge clk);
            B_VALID = 0;
            B_okay = 1'b0;

            while(!ace_ready) @(posedge clk);

        end
    endtask

    // Task to drive read request
    task drive_read_request;
        begin
            read_req = 1;
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
                R_okay = 0;
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
            R_okay = 0;
            

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
            R_okay = 0;
            
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

    task monitor_datapath_controller;
        forever begin
            @(posedge clk); // Wait for a clock cycle
            while(!(make_unique_o || read_shared_o || write_clean_o || read_resp_en || ac_enable || ace_ready)) @(posedge clk);
    
            // Compare actual outputs with expected values
            if ((make_unique_o === expected_make_unique) &&
                (write_clean_o === expected_write_clean) &&
                (read_shared_o === expected_read_shared) &&
                (read_resp_en === expected_read_resp_en) &&
                (ace_ready === expected_ace_ready) &&
                (ac_enable === expected_ac_enable)) begin
                $display("PASS: Datapath side outputs are correct at time %0t", $time);
                pass_count++;
            end else begin
                $display("FAIL: Datapath side outputs mismatch at time %0t", $time);
                $display("Expected: make_unique_o=%0b, write_clean_o=%0b, read_shared_o=%0b, read_resp_en=%0b, ac_enable=%0b", 
                     expected_make_unique, expected_write_clean, expected_read_shared, expected_read_resp_en, expected_ac_enable);
                $display("Actual  : make_unique_o=%0b, write_clean_o=%0b, read_shared_o=%0b, read_resp_en=%0b, ac_enable=%0b", 
                     make_unique_o, write_clean_o, read_shared_o, read_resp_en, ac_enable);
                fail_count++;
            end
        end
    endtask
    

    task call_request;
        begin
            logic [2:0] local_var;
            repeat(10) begin
                local_var = $urandom;
                case(local_var) 
                    3'b000: drive_read_request();
                    3'b001: drive_invalid_request();
                    3'b010: drive_write_request();
                    3'b011: drive_snoop_miss();
                    3'b100: drive_response();
                    3'b101: drive_invalid_request();
                    default: drive_write_request();
                endcase
            end
        end
    endtask

    task initialize_expected;
        forever begin
            #1;
            @(posedge clk);
            expected_ace_ready    = 1'b0;
            expected_make_unique  = 1'b0;
            expected_write_clean  = 1'b0;
            expected_read_shared  = 1'b0;
            expected_read_resp_en = 1'b0;
            expected_ac_enable    = 1'b0;
            if (write_req) begin
                expected_write_clean  = 1'b1;
            end else if (read_req) begin
                expected_read_shared  = 1'b1;
            end else if(invalid_req) begin
                expected_make_unique  = 1'b1;
            end else if(AC_VALID) begin
                expected_ac_enable    = 1'b1;
            end else if(R_okay) begin
                expected_read_resp_en = 1'b1;
                expected_ace_ready    = 1'b1;
            end else if(B_okay) begin
                expected_ace_ready    = 1'b1;
            end
        end
    endtask

    initial begin
        fork
            monitor_datapath_controller();
            // monitor_interconnect_side();
            initialize_expected();
            // initialize_expected_interconnect();
        join_none
    end

    // Testbench execution
    initial begin
        initialize_signals();
        reset();

        call_request();
        // Final results
        $display("Total Passes: %0d", pass_count);
        $display("Total Fails: %0d", fail_count);
        // $display("Total Passes: %0d", pass_count_int);
        // $display("Total Fails: %0d", fail_count_int);
        
        // Finish simulation
        @(posedge clk);
        $finish;
    end

    initial begin
        $dumpfile("ace_controller.vcd");
        $dumpvars(0);
    end

endmodule