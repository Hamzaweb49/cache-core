module tb_cache_datapath;
    
    // Parameters
    parameter WIDTH_A = 32;
    parameter WIDTH_D = 32;
    parameter WIDTH_STATE = 3;

    // Testbench signals
    logic clk;
    logic rst_n;

    // Inputs to cache_datapath
    logic [WIDTH_A-1:0] cpu_addr;
    logic [WIDTH_D-1:0] cpu_wdata;
    logic write_from_interconnect;
    logic write_from_cpu;
    logic [WIDTH_STATE-1:0] new_state;
    logic mux_en;
    logic make_unique;
    logic read_shared;
    logic write_clean;
    logic ac_enable;
    logic read_resp_en;
    logic [3:0] AC_SNOOP;
    logic [2:0] AC_PROT;
    logic [WIDTH_A-1:0] AC_ADDR;
    logic [1:0] BRESP;
    logic B_ID;
    logic R_ID;
    logic R_LAST;
    logic [3:0] RRESP;
    logic [WIDTH_D-1:0] RDATA;

    // Outputs from cache_datapath
    logic [WIDTH_D-1:0]cpu_rdata;
    logic cache_hit;
    logic cache_miss;
    logic [WIDTH_STATE-1:0] line_state;
    logic invalid;
    logic snoop_miss;
    logic response;
    logic response_data;
    logic B_okay;
    logic R_okay;
    logic [4:0] CR_RESP;
    logic CD_LAST;
    logic [WIDTH_D-1:0] CD_DATA;
    logic [WIDTH_A-1:0] AR_ADDR;
    logic AR_ID;
    logic [2:0] AR_SIZE;
    logic [1:0] AR_BURST;
    logic [7:0] AR_LEN;
    logic [2:0] AR_PROT;
    logic [3:0] AR_CACHE;
    logic [1:0] AR_BAR;
    logic [1:0] AR_DOMAIN;
    logic [3:0] AR_SNOOP;
    logic [WIDTH_A-1:0] AW_ADDR;
    logic AW_ID;
    logic [2:0] AW_SIZE;
    logic [1:0] AW_BURST;
    logic [7:0] AW_LEN;
    logic [2:0] AW_PROT;
    logic [3:0] AW_CACHE;
    logic [1:0] AW_BAR;
    logic [1:0] AW_DOMAIN;
    logic [2:0] AW_SNOOP;
    logic W_STRB;
    logic W_LAST;
    logic [WIDTH_D-1:0] W_DATA;

    // Instantiate the cache_datapath module
    cache_datapath #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_D(WIDTH_D),
        .WIDTH_STATE(WIDTH_STATE)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_rdata(cpu_rdata),
        .write_from_interconnect(write_from_interconnect),
        .write_from_cpu(write_from_cpu),
        .new_state(new_state),
        .mux_en(mux_en),
        .cache_hit(cache_hit),
        .cache_miss(cache_miss),
        .line_state(line_state),
        .make_unique(make_unique),
        .read_shared(read_shared),
        .write_clean(write_clean),
        .ac_enable(ac_enable),
        .read_resp_en(read_resp_en),
        .invalid(invalid),
        .snoop_miss(snoop_miss),
        .response(response),
        .response_data(response_data),
        .B_okay(B_okay),
        .R_okay(R_okay),
        .AC_ADDR(AC_ADDR),
        .AC_SNOOP(AC_SNOOP),
        .AC_PROT(AC_PROT),
        .RDATA(RDATA),
        .BRESP(BRESP),
        .B_ID(B_ID),
        .R_ID(R_ID),
        .R_LAST(R_LAST),
        .RRESP(RRESP),
        .CR_RESP(CR_RESP),
        .CD_LAST(CD_LAST),
        .CD_DATA(CD_DATA),
        .AR_ADDR(AR_ADDR),
        .AR_ID(AR_ID),
        .AR_SIZE(AR_SIZE),
        .AR_BURST(AR_BURST),
        .AR_LEN(AR_LEN),
        .AR_PROT(AR_PROT),
        .AR_CACHE(AR_CACHE),
        .AR_BAR(AR_BAR),
        .AR_DOMAIN(AR_DOMAIN),
        .AR_SNOOP(AR_SNOOP),
        .AW_ADDR(AW_ADDR),
        .AW_ID(AW_ID),
        .AW_SIZE(AW_SIZE),
        .AW_BURST(AW_BURST),
        .AW_LEN(AW_LEN),
        .AW_PROT(AW_PROT),
        .AW_CACHE(AW_CACHE),
        .AW_BAR(AW_BAR),
        .AW_DOMAIN(AW_DOMAIN),
        .AW_SNOOP(AW_SNOOP),
        .W_STRB(W_STRB),
        .W_LAST(W_LAST),
        .W_DATA(W_DATA)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset and initialization tasks
    task reset;
        begin
            rst_n = 0;
            #20; // Hold reset for 20 time units
            rst_n = 1;
        end
    endtask

    task initialize_inputs;
        begin
            cpu_addr = 0;
            cpu_wdata = 0;
            write_from_interconnect = 0;
            write_from_cpu = 0;
            new_state = 0;
            mux_en = 0;
            make_unique = 0;
            read_shared = 0;
            write_clean = 0;
            ac_enable = 0;
            read_resp_en = 0;
            AC_SNOOP = 0;
            AC_PROT = 0;
            AC_ADDR = 0;
            BRESP = 0;
            B_ID = 0;
            R_ID = 0;
            R_LAST = 0;
            // RRESP = 4'b0000;
            RDATA = 32'h00000000;
        end
    endtask

    task drive_cpu;
        begin
            @(posedge clk);
            // cpu_addr = 32'h0100000C;
            cpu_addr = 32'h00000010;
            cpu_wdata = 32'hDEADBEEF;
        end
    endtask

    task drive_cache_controller;
        begin
            // Case assuming write request from cpu
            @(posedge clk);
            write_from_cpu = 0;
            write_from_interconnect = 0;
            if(cache_miss) begin
                drive_ace_controller_read();
                write_from_interconnect = 1;
                drive_interconnect_read();
                @(posedge clk); 
                write_from_cpu = 1;
            end else if(cache_hit) begin
                if(line_state == 3'b100) begin
                    drive_ace_controller_invalid();
                    // repeat(5) @(posedge clk);
                    write_from_interconnect = 1;
                    drive_interconnect_read();
                    @(posedge clk); 
                    write_from_cpu = 1;
                end else begin
                    write_from_cpu = 1;
                end
            end
            new_state = 3'b000; // Unique Clean
            mux_en = 1;
            @(posedge clk);
            mux_en = 0;            
        end
    endtask

    task drive_interconnect_read;
        begin
            RDATA = 32'hFEEDDEAD; // Data read from the interconnect
            RRESP = 4'b1000; // is_shared, not dirty and okay response
        end
    endtask
    task drive_ace_controller_invalid;
        begin
            // Apply make_unique signal from ace controller
            make_unique = 0;
            read_resp_en = 0;
            @(posedge clk);
            make_unique = 1;
            repeat(5) @(posedge clk);
            read_resp_en = 1;
        end
    endtask
    task drive_ace_controller_read;
        begin
            // Apply read_shared signal from ace controller
            read_shared = 0;
            read_resp_en = 0;
            @(posedge clk);
            read_shared = 1;
            repeat(5) @(posedge clk);
            read_resp_en = 1;
        end
    endtask

    task drive_interconnect_snoop;
        begin
            @(posedge clk);
            AC_ADDR = 32'h01000010;
            AC_SNOOP = 4'b0001; // Read Shared snoop
            drive_ace_controller_snoop();
        end
    endtask
    task drive_ace_controller_snoop();
        begin
            ac_enable = 0;
            @(posedge clk);
            ac_enable = 1;
            @(posedge clk);
            ac_enable = 0;
            repeat(5) @(posedge clk);
        end
    endtask

    // Testbench initial block
    initial begin
        // Reset and initialize inputs
        reset();
        initialize_inputs();

        drive_cpu();
        drive_cache_controller();

        repeat(10) @(posedge clk);

        drive_interconnect_snoop();

        // Finish simulation
        #10;
        $finish;
    end
    initial begin
        $dumpfile("Datapath.vcd");
        $dumpvars(0);
    end
    
endmodule
