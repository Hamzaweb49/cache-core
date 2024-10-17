module tb_top_level;

    // Parameters
    parameter WIDTH_A = 32;
    parameter WIDTH_D = 32;
    parameter WIDTH_STATE = 3;
    
    // Clock and reset
    logic clk;
    logic rst_n;
    
    // CPU --> Cache
    logic [1:0] cpu_request;
    logic [WIDTH_A-1:0] cpu_addr;
    logic [WIDTH_D-1:0] cpu_wdata;
    
    // Cache --> CPU
    logic [WIDTH_D-1:0] cpu_rdata;
    logic cache_ready;
    logic cache_complete;
    
    // Interconnect --> Cache
    logic AW_READY;
    logic AW_VALID;
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
    
    logic W_READY;
    logic W_VALID;
    logic W_ID;
    logic W_LAST;
    logic [WIDTH_D-1:0] W_DATA;
    
    logic B_VALID;
    logic [1:0] BRESP;
    logic B_READY;
    
    logic AR_READY;
    logic AR_VALID;
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
    
    logic R_ID;
    logic R_LAST;
    logic R_VALID;
    logic [3:0] RRESP;
    logic [WIDTH_D-1:0] RDATA;
    logic R_READY;
    
    logic AC_VALID;
    logic [3:0] AC_SNOOP;
    logic [2:0] AC_PROT;
    logic [WIDTH_A-1:0] AC_ADDR;
    logic AC_READY;
    
    logic CR_READY;
    logic CR_VALID;
    logic [4:0] CR_RESP;
    
    logic CD_READY;
    logic CD_VALID;
    logic CD_LAST;
    logic [WIDTH_D-1:0] CD_DATA;

    logic [31:0] AC_ADDR_dummy1, AC_ADDR_main_mem;
    logic [4:0] AC_SNOOP_dummy1;
    logic CR_READY_dummy1, CD_VALID_dummy1, AC_VALID_dummy1, AC_READY_dummy1;
    logic [4:0] CR_RESP_dummy1;
    logic CR_VALID_dummy1, CD_READY_dummy1;
    logic [31:0] CD_DATA_dummy1;
    
    // Dummy main memory
    logic [31:0] main_mem[7:0];

    logic [31:0] ref_rdata;

    int pass_count = 0;
    int fail_count = 0;

     // Reference Cache Definition
    typedef struct packed {
        logic [31:0] data;
        logic [26:0] tag;
        logic valid_bit;
    } cache_line;

    cache_line ref_cache [7:0];  // Reference cache with 8 lines
    // Index and tag extracted from the address
    logic [2:0] ref_index;
    logic [26:0] ref_tag;

    // Instantiate the top-level module
    top_level #(
        .WIDTH_A(WIDTH_A),
        .WIDTH_D(WIDTH_D),
        .WIDTH_STATE(WIDTH_STATE)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .cpu_request(cpu_request),
        .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata),
        .cpu_rdata(cpu_rdata),
        .cache_ready(cache_ready),
        .cache_complete(cache_complete),
        .AW_READY(AW_READY),
        .AW_VALID(AW_VALID),
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
        .W_READY(W_READY),
        .W_VALID(W_VALID),
        .W_ID(W_ID),
        .W_LAST(W_LAST),
        .W_DATA(W_DATA),
        .B_VALID(B_VALID),
        .BRESP(BRESP),
        .B_READY(B_READY),
        .AR_READY(AR_READY),
        .AR_VALID(AR_VALID),
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
        .R_ID(R_ID),
        .R_LAST(R_LAST),
        .R_VALID(R_VALID),
        .RRESP(RRESP),
        .RDATA(RDATA),
        .R_READY(R_READY),
        .AC_VALID(AC_VALID),
        .AC_SNOOP(AC_SNOOP),
        .AC_PROT(AC_PROT),
        .AC_ADDR(AC_ADDR),
        .AC_READY(AC_READY),
        .CR_READY(CR_READY),
        .CR_VALID(CR_VALID),
        .CR_RESP(CR_RESP),
        .CD_READY(CD_READY),
        .CD_VALID(CD_VALID),
        .CD_LAST(CD_LAST),
        .CD_DATA(CD_DATA)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Initialize main memory with some values
    task initialize_memory;
        integer i;
        begin
            for (i = 0; i < 8; i = i + 1) begin
                main_mem[i] = 32'hDEEDFEED; 
            end
        end
    endtask
    
    // Testbench tasks
    task initialize;
    begin
        rst_n = 1;
        cpu_request = 2'b11;
        cpu_addr = 0;
        cpu_wdata = 0;
        
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
    
    task reset;
    begin
        @(posedge clk);
        rst_n = 0;
        #50
        rst_n = 1;
    end
    endtask
    
    initial begin
        $dumpfile("Top_level.vcd");
        $dumpvars(0);
    end

    // Dummy CPU
    task dummy_cpu;
        integer i;
        begin 
            // Perform it many times ----- CPU will be idle for some time and will drive write/read requests at other
            for (i=0; i < 5000000; i++) begin
                @(posedge clk);
                if($urandom % 9) begin
                    cpu_request = 2'b11; // IDLE
                end else begin
                    driver_cpu();        // Drive random cpu request 
                end
                while(!cache_ready) @(posedge clk);
            end
        end
    endtask
    // CPU SIDE DRIVER
    task driver_cpu;
        begin
            @(posedge clk);
            address_select();
            wdata_select();
            call_cpu_request();
            @(posedge clk);
            while(!cache_ready) @(posedge clk);
            cpu_request = 2'b11; 
            @(posedge clk)
            while(!cache_complete) @(posedge clk);
        end
    endtask
    task address_select;
        logic [3:0] local_var;
        begin
            local_var = $urandom;
            case(local_var) 
                // Random addresses from cpu
                4'b0000: cpu_addr = 32'h0000_0000;
                4'b0001: cpu_addr = 32'h0000_0008; // different index
                4'b0010: cpu_addr = 32'h0000_000C; // different index
                4'b0011: cpu_addr = 32'h0000_001C;
                4'b0100: cpu_addr = 32'h0000_0018; 
                4'b0101: cpu_addr = 32'h0100_0018;
                4'b0110: cpu_addr = 32'h0100_000C;
                4'b0111: cpu_addr = 32'h0100_0008;
                4'b1000: cpu_addr = 32'h0200_0010;
                4'b1001: cpu_addr = 32'h0200_0014;
                4'b1010: cpu_addr = 32'h0200_0020;
                4'b1011: cpu_addr = 32'h0200_0024;
                4'b1100: cpu_addr = 32'h0300_0000;
                4'b1101: cpu_addr = 32'h0300_0004;
                4'b1110: cpu_addr = 32'h0300_000C;
                4'b1111: cpu_addr = 32'h0300_0010;
                default: cpu_addr = 32'h0000_0000;
            endcase
        end
    endtask
    task wdata_select;
        logic [1:0] local_var;
        begin
            local_var = $urandom;
            case(local_var)
                // Random write data from cpu 
                2'b00: cpu_wdata = 32'hDEADBEEF;
                2'b01: cpu_wdata = 32'hABCDABCD;
                2'b10: cpu_wdata = 32'hFEEDBEEF;
                2'b11: cpu_wdata = 32'hBEEFDEAD;
                default: cpu_wdata = 32'hDEADBEEF;
            endcase
        end
    endtask
    task call_cpu_request;
        logic local_var;
        begin
            local_var = $urandom;
            case(local_var)
                // Random request from cpu
                1'b0: cpu_request = 2'b00; // Read request
                1'b1: cpu_request = 2'b01; // Write request
                default: cpu_request = 2'b00;
            endcase
        end
    endtask

    // INTERCONNECT
    task dummy_interconnect;
        forever begin
            #1;
            AR_READY = 1;
            AW_READY = 1;
            W_READY  = 1;
            B_VALID  = 0;
            R_VALID  = 0;
            AC_VALID = 0;
            CR_READY = 1;
            CD_READY = 1;

            @(posedge clk);
            while(!AR_VALID && !AW_VALID && !AC_READY) @(posedge clk);
            if(AR_VALID) begin
                AR_READY = 0;
                AC_ADDR_dummy1   = AR_ADDR;
                case({AR_BAR[0], AR_DOMAIN, AR_SNOOP}) 
                    7'b0_10_0001: AC_SNOOP_dummy1 = 4'b0001; // Read shared 
                    7'b0_10_1100: AC_SNOOP_dummy1 = 4'b0111; // Make unique
                endcase
                dummy_cache(AC_ADDR_dummy1);                
               
                if(AC_SNOOP_dummy1 == 4'b0111) begin
                    if(CR_RESP_dummy1 == 5'b00101) begin
                        main_mem[AC_ADDR_dummy1[4:2]] = CD_DATA_dummy1;
                        AR_READY = 1;
                        @(posedge clk);
                        while(!AR_VALID) @(posedge clk);
                        AR_READY = 0;
                    end 
                    else begin
                        AR_READY = 1;
                        @(posedge clk);
                        while(!AR_VALID) @(posedge clk);
                        AR_READY = 0;
                    end        
                end else if(AC_SNOOP_dummy1 == 4'b0001) begin
                    case(CR_RESP_dummy1)
                        5'b00000: begin
                            R_VALID = 1;
                            RDATA = main_mem[AR_ADDR[4:2]]; 
                            RRESP = 4'b0000;
                            @(posedge clk);
                            while(!R_READY) @(posedge clk);
                            R_VALID = 0;
                        end
                        5'b00001: begin
                            R_VALID = 1;
                            RDATA = CD_DATA_dummy1;
                            RRESP = 4'b0000;
                            @(posedge clk);
                            while(!R_READY) @(posedge clk);
                            R_VALID = 0;                       
                        end
                        5'b01001: begin
                            RDATA = CD_DATA_dummy1;
                            RRESP = 4'b1000;
                            R_VALID = 1;
                            @(posedge clk);
                            while(!R_READY) @(posedge clk);
                            R_VALID = 0;  
                        end
                        default: begin
                            RDATA = main_mem[AR_ADDR[4:2]];
                            RRESP = 4'b1100;
                            R_VALID = 1;
                            @(posedge clk);
                            while(!R_READY) @(posedge clk);
                            R_VALID = 0;  
                        end
                    endcase
                end
            end else if(AW_VALID) begin
                AC_ADDR_main_mem = AW_ADDR;
                AW_READY = 0;
                W_READY = 1;
                @(posedge clk);
                while(!W_VALID) @(posedge clk);
                main_mem[AW_ADDR[4:2]] = W_DATA;
                W_READY = 0;
                B_VALID = 1;
                BRESP   = 2'b00;
                @(posedge clk);
                while(!B_READY) @(posedge clk);
                B_VALID = 0;
            end
        end
    endtask

    // Assume a cache connected with the same interconnect as our DUT Cache
    task dummy_cache(input logic [31:0]AC_ADDR_dummy1_i);
        logic [2:0] index_ac;
        logic invalid_ac;
    
        begin
            typedef struct packed {
                logic [31:0] data;
                logic [26:0] tag;
                logic        valid_bit;
                logic [2:0]  state;
            } dummy_cache_line;
    
            dummy_cache_line cache_1 [7:0];  // Array of 8 cache lines
    
            // Initialize cache lines only once
            for (int i = 0; i < 8; i++) begin
                cache_1[i].data      = 32'hDEADBEF0 + i;  // Example: Unique data for each cache line
                cache_1[i].tag       = 27'h0000000 + i;   // Example: Unique tag for each cache line
                cache_1[i].valid_bit = 1'b1;              // Set all cache lines as valid

                // Set different states based on the index
                if (i == 0) begin
                    cache_1[i].state = 3'b011; // Shared dirty
                end else if (i == 2) begin
                    cache_1[i].state = 3'b010; // Shared clean
                end else begin
                    cache_1[i].state = 3'b100; // Invalid
                end
            end
            index_ac = AC_ADDR_dummy1_i[4:2];
            invalid_ac = (cache_1[index_ac].state == 3'b100) ? 1 : 0;

            @(posedge clk);
            case(AC_SNOOP_dummy1)
                4'b0001: begin
                    if(!invalid_ac) begin
                        CD_DATA_dummy1 = cache_1[index_ac].data;
                        if(!(cache_1[index_ac].state == 3'b100)) begin
                            CR_RESP_dummy1 = 5'b01001;
                        end else begin
                            CR_RESP_dummy1 = 5'b00001;
                        end
                    end else begin
                        CR_RESP_dummy1 = 5'b00000;
                    end
                end
                4'b0111: begin
                    if(!invalid_ac) begin
                        CD_DATA_dummy1 = cache_1[index_ac].data;
                        if(cache_1[index_ac].state == 3'b011) begin
                            CR_RESP_dummy1 = 5'b00101;
                        end else begin
                            CR_RESP_dummy1 = 5'b00001;
                        end    
                    end else begin
                        CR_RESP_dummy1 = 5'b00000;
                    end
                end
                default: begin
                    CR_RESP_dummy1 = 5'b11111;  // Invalid snoop request
                end
            endcase
        end
    endtask

    // Cache Initialization Task
    task initialize_cache();
        for (int i = 0; i < 8; i++) begin
            ref_cache[i].data      = 32'b0;
            ref_cache[i].tag       = 27'b0;
            ref_cache[i].valid_bit = 1'b0;  // Invalidate all lines initially
        end
        $display("Reference cache initialized to zero.");
    endtask

    // Reference cache
    task reference_cache;
        forever begin
            #1;
            // Extract index and tag from the address
            ref_index = cpu_addr[4:2];
            ref_tag = cpu_addr[31:5];
    
            // Handle write request
            if (cpu_request == 2'b01) begin
                ref_cache[ref_index].data      = cpu_wdata;
                ref_cache[ref_index].tag       = ref_tag;
                ref_cache[ref_index].valid_bit = 1'b1;  // Set valid bit
            end
    
            // Handle read request
            else if (cpu_request == 2'b00) begin
                while(!cache_complete) begin
                    #1;
                    if(R_READY && R_VALID) begin
                        ref_cache[ref_index].data = RDATA;
                    end
                end
                ref_rdata = ref_cache[ref_index].data;
            end

        end
    endtask

    // Monitor the read data from the cache
    task monitor_cache;
        // Forever monitor for read requests
        logic [31:0] monitor_addr;
        forever begin
            // Wait for a read request
            #1;
            if (cpu_request == 2'b00) begin  // 2'b00 for read request
                monitor_addr = cpu_addr;
                // Check if the cache is ready to provide data
                @(posedge clk);
                while (!cache_complete) @(posedge clk);

                // Compare the DUT cache read data with the reference cache data
                if (cpu_rdata !== ref_rdata) begin
                    $display("Mismatch on read: DUT read %h, expected %h at address %h at time: %0d", cpu_rdata, ref_rdata, monitor_addr, $time);
                    fail_count++;
                end else begin
                    $display("Read correct: DUT read %h matches expected %h at address %h at time: %0d", cpu_rdata, ref_rdata, monitor_addr, $time);
                    pass_count++;
                end 
            end
        end
    endtask
    
    initial begin
        integer i;
        // Initialize inputs 
        initialize();
        
        // Initialize main memory
        initialize_memory();
        
        // Initialize reference model
        initialize_cache();

        // Apply reset
        reset();
        
        // Display initial values of main_mem
        $display("Initial values of main_mem:");
        for (i = 0; i < 8; i++) begin
            $display("main_mem[%0d] = %h", i, main_mem[i]); // Display in hex format
        end

        fork
            reference_cache();
            monitor_cache();
        join_none

        fork
            dummy_interconnect();
            dummy_cpu();
        join_any

        @(posedge clk);
        // Display pass and fail counts
        $display("\nSimulation Summary:");
        $display("Total Pass Count: %0d", pass_count);
        $display("Total Fail Count: %0d", fail_count);

        // Final values in main memory
        $display("Final values of main_mem:");
        for (i = 0; i < 8; i++) begin
            $display("main_mem[%0d] = %h", i, main_mem[i]); // Display in hex format
        end

        $finish;
    end


endmodule