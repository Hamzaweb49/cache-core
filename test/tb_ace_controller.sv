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
            #200;
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
        int local_count;
        begin
            write_req = 1;
            local_count = 0;
            while(!B_okay) begin
                local_count++;
                AW_READY = 1;
                @(posedge clk);
                write_req = 0;
                while(!AW_VALID) @(posedge clk);
                AW_READY = 0;

                W_READY = 1;
                @(posedge clk);
                while(!W_VALID) @(posedge clk);
                W_READY = 0;

                B_VALID = 1;
                if((local_count == 10) && (!B_okay)) begin
                    B_okay = 1;
                end else begin
                    B_okay = $urandom % 2;
                end

                @(posedge clk);
                while(!B_READY) @(posedge clk);
                B_VALID = 0;
            end
            B_okay = 0;

            while(!ace_ready) @(posedge clk);

        end
    endtask

    // Task to drive read request
    task drive_read_request;
        int local_count;
        begin
            read_req = 1;
            local_count = 0;
            // SUppose a condition when Response in not OKAY
            while(!R_okay) begin
                local_count++;
                AR_READY = 1;
                @(posedge clk);
                read_req = 0;
                while(!AR_VALID) @(posedge clk);
                AR_READY = 0;

                R_VALID = 1;
                if((local_count == 10) && (!R_okay)) begin
                    R_okay = 1;
                end else begin
                    R_okay = $urandom % 2;
                end
                @(posedge clk);
                while(!R_READY) @(posedge clk);
                R_VALID = 0;
            end
            R_okay = 0;
            
            while(!ace_ready) @(posedge clk);
        end
    endtask

    // Task to drive invalid request
    task drive_invalid_request;
        begin
            invalid_req = 1;
            AR_READY = $urandom % 2;
            if(!AR_READY) begin
                @(posedge clk);
                invalid_req = 0;
                repeat(5) @(posedge clk);
                AR_READY = 1;
                @(posedge clk);
                while(!AR_VALID) @(posedge clk);
                AR_READY = 0;
            end else begin
                @(posedge clk);
                invalid_req = 0;
                while(!AR_VALID) @(posedge clk);
                AR_READY = 0;
            end
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
            repeat($urandom % 10) @(posedge clk);
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
            if ((make_unique_o !== expected_make_unique) ||
                (write_clean_o !== expected_write_clean) ||
                (read_shared_o !== expected_read_shared) ||
                (read_resp_en !== expected_read_resp_en) ||
                (ace_ready !== expected_ace_ready) ||
                (ac_enable !== expected_ac_enable)) begin
                $display("FAIL: Datapath side outputs mismatch at time %0t", $time);
                $display("Expected: make_unique_o=%0b, write_clean_o=%0b, read_shared_o=%0b, read_resp_en=%0b, ac_enable=%0b, ace_ready=%0b", 
                         expected_make_unique, expected_write_clean, expected_read_shared, expected_read_resp_en, expected_ac_enable, expected_ace_ready);
                $display("Actual  : make_unique_o=%0b, write_clean_o=%0b, read_shared_o=%0b, read_resp_en=%0b, ac_enable=%0b, ace_ready=%0b", 
                         make_unique_o, write_clean_o, read_shared_o, read_resp_en, ac_enable, ace_ready);
                fail_count++;
            end else begin
                $display("PASS: Datapath side outputs are correct at time %0t", $time);
                pass_count++;
            end
        end
    endtask

    task initialize_expected_controller_datapath;
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
                if(AR_READY) begin
                    expected_ace_ready = 1'b1;
                end else begin
                    @(posedge clk);
                    expected_make_unique  = 1'b0;
                    while(!AR_READY) @(posedge clk);
                    @(posedge clk);
                    expected_ace_ready = 1'b1;
                end
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

    task monitor_interconnect_side;
        forever begin
            @(posedge clk);
            while(!rst_n || !(AW_VALID || W_VALID || B_READY || AR_VALID || R_READY || AC_READY || CD_VALID || CR_VALID)) @(posedge clk);
            
            // Compare only when expected value is not 'x'
            if ((expected_AR_VALID !== 1'bx && AR_VALID != expected_AR_VALID) ||
            (expected_AW_VALID !== 1'bx && AW_VALID != expected_AW_VALID) ||
            (expected_W_VALID  !== 1'bx && W_VALID  != expected_W_VALID)  ||
            (expected_B_READY  !== 1'bx && B_READY  != expected_B_READY)  ||
            (expected_R_READY  !== 1'bx && R_READY  != expected_R_READY)  ||
            (expected_AC_READY !== 1'bx && AC_READY != expected_AC_READY) ||
            (expected_CR_VALID !== 1'bx && CR_VALID != expected_CR_VALID) ||
            (expected_CD_VALID !== 1'bx && CD_VALID != expected_CD_VALID)) begin
            $display("FAIL: Interconnect side outputs mismatch at time %0t", $time);
            // Display expected values
            $display("Expected: AR_VALID=%0b, AW_VALID=%0b, W_VALID=%0b, B_READY=%0b, R_READY=%0b, AC_READY=%0b, CR_VALID=%0b, CD_VALID=%0b", 
                expected_AR_VALID, expected_AW_VALID, expected_W_VALID, expected_B_READY, expected_R_READY, expected_AC_READY, expected_CR_VALID, expected_CD_VALID);
            // Display actual values
            $display("Actual  : AR_VALID=%0b, AW_VALID=%0b, W_VALID=%0b, B_READY=%0b, R_READY=%0b, AC_READY=%0b, CR_VALID=%0b, CD_VALID=%0b", 
                AR_VALID, AW_VALID, W_VALID, B_READY, R_READY, AC_READY, CR_VALID, CD_VALID);
            fail_count_int++;
        end else begin
            $display("PASS: Interconnect side outputs are correct at time %0t", $time);
            pass_count_int++;
        end

        end
    endtask

    task initialize_expected_interconnect;
        static logic was_write_req, was_read_req, was_invalid_req, was_AC_VALID, was_snoop_miss;

        forever begin
            @(posedge clk);
            // Update flags to track the state of conditions for the next cycle
            was_write_req   = write_req;
            was_read_req    = read_req;
            was_invalid_req = invalid_req;
            was_AC_VALID    = AC_VALID;
            was_snoop_miss  = snoop_miss;
               
            // Reset expected values for the new cycle
            expected_AW_VALID = #1 1'bx;
            expected_AR_VALID = #1 1'bx;
            expected_W_VALID  = #1 1'bx;
            expected_B_READY  = #1 1'bx;
            expected_R_READY  = #1 1'bx;
            expected_AC_READY = #1 1'bx;
            expected_CR_VALID = #1 1'bx;
            expected_CD_VALID = #1 1'bx;
        
            // Conditions for write requests
            if (write_req) begin
                expected_AW_VALID = #1 1;                    
            end else if (was_write_req && AW_READY) begin
                expected_AW_VALID = #1 1;
            end else if (was_write_req && W_READY) begin
                expected_W_VALID = #1 1;
            end else if (was_write_req && B_VALID) begin
                expected_B_READY = #1 1;
            end
        
            // Conditions for read requests
            if (read_req || invalid_req) begin
                expected_AR_VALID = #1 1;
            end else if (was_read_req && AR_READY) begin
                expected_AR_VALID = #1 1;
                expected_R_READY = #1 1;
            end else if (was_read_req && R_VALID) begin
                expected_R_READY = #1 1;
            end
        
            // Conditions for AC_VALID
            if (AC_VALID) begin
                expected_AC_READY = #1 1;
            end else if (was_AC_VALID && (snoop_miss || invalid_req)) begin
                if (response) begin
                    expected_CR_VALID = #1 1;
                end else if (response_data) begin
                    expected_CR_VALID = #1 1;
                    expected_CD_VALID = #1 1;
                end
            end else if (was_AC_VALID && CR_READY && CD_READY) begin
                expected_CD_VALID = #1 1;
                expected_CR_VALID = #1 1;
            end else if (was_AC_VALID && CR_READY) begin
                expected_CR_VALID = #1 1;
            end

        end
    endtask
    
    task call_request;
        begin
            logic [2:0] local_var;
            repeat(100000) begin
                local_var = $urandom;
                case(local_var) 
                    3'b000: drive_read_request();
                    3'b001: drive_invalid_request();
                    3'b010: drive_write_request();
                    3'b011: drive_snoop_miss();
                    3'b100: drive_response();
                    default: drive_write_request();
                endcase
            end
        end
    endtask

    initial begin
        fork
            monitor_datapath_controller();
            initialize_expected_controller_datapath();
            monitor_interconnect_side();
            initialize_expected_interconnect();
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
        
        $display("Total Passes interconnect side: %0d", pass_count_int);
        $display("Total Fails interconnect side: %0d", fail_count_int);
        // Finish simulation
        @(posedge clk);
        $finish;
    end

    initial begin
        $dumpfile("ace_controller.vcd");
        $dumpvars(0);
    end

endmodule