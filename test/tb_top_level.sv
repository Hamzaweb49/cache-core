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

    int pass_count = 0;
    int fail_count = 0;

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

    task initialize_memory;
        integer i;
        begin
            for (i = 0; i < 8; i = i + 1) begin
                main_mem[i] = 32'hDEEDFEED;  // Assign 0 to each memory entry
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
        // AC_ADDR = 32'h00000000;
        // AC_SNOOP = 4'b000;
        // R_DATA = 32'h00000000;
        // R_RESP = 4'b0000;
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
            for (i=0; i < 100; i++) begin
                @(posedge clk);
                if($urandom % 9) begin
                    cpu_request = 2'b11; // IDLE
                    // driver_cpu();
                end else begin
                    driver_cpu();
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
        logic [2:0] local_var;
        begin
            local_var = $urandom;
            case(local_var) 
                3'b000: cpu_addr = 32'h0000_0000;
                3'b001: cpu_addr = 32'h0000_0008; // different index
                3'b010: cpu_addr = 32'h0000_000C; // different index
                3'b011: cpu_addr = 32'h0000_001C;
                3'b100: cpu_addr = 32'h0000_0018;
                3'b101: cpu_addr = 32'h0100_0018;
                3'b110: cpu_addr = 32'h0100_000C;
                default: cpu_addr = 32'h0000_0000;
            endcase
        end
    endtask
    task wdata_select;
        logic [1:0] local_var;
        begin
            local_var = $urandom;
            case(local_var)
                2'b00: cpu_wdata = 32'hDEADBEEF;
                2'b01: cpu_wdata = 32'hABCDABCD;
                2'b10: cpu_wdata = 32'hFEEDBEEF;
                default: cpu_wdata = 32'hDEADBEEF;
            endcase
        end
    endtask
    task call_cpu_request;
        logic local_var;
        begin
            local_var = $urandom;
            case(local_var)
                1'b0: cpu_request = 2'b00; // Read request
                1'b1: cpu_request = 2'b01; // Write request
                // 2'b11: cpu_request = 2'b11; // IDLE
                default: cpu_request = 2'b00;
            endcase
        end
    endtask

    // INTERCONNECT
    task dummy_interconnect;
        forever begin
            // @(posedge clk);
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
                            RDATA = main_mem[AC_ADDR_main_mem[4:2]]; 
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
                            RDATA = main_mem[AC_ADDR_main_mem[4:2]];
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
                // #1;
            // else if(AC_READY) begin
            //     // #1;
            //     // drive_snoop();
            //     if(!AR_VALID && !AW_VALID) begin
            //         AC_VALID = 1;
            //         AC_ADDR  = 32'h0000_0000;
            //         @(posedge clk);
            //         while(!AC_READY) @(posedge clk);
            //         AC_VALID = 0;
            //         CR_READY = 1;
            //         @(posedge clk);
            //         while(!CR_VALID) @(posedge clk);
            //         CR_READY = 0;
            //         if(!(CR_RESP == 5'b00000)) begin
            //             CD_READY = 1;
            //             @(posedge clk);
            //             while(!CD_VALID) @(posedge clk);
            //             CD_READY = 0;
            //         end 
            //     end
            // end
        end
    endtask
    task dummy_cache(input logic [31:0]AC_ADDR_dummy1_i);
        // Declare a static variable to check if initialization has been done
        static logic cache_initialized = 0;
        logic [2:0] index_ac;
        logic invalid_ac;
        // logic [26:0] tag_ac;
    
        begin
            typedef struct packed {
                logic [31:0] data;
                logic [26:0] tag;
                logic        valid_bit;
                logic [2:0]  state;
            } dummy_cache_line;
    
            dummy_cache_line cache_1 [7:0];  // Array of 8 cache lines
    
            // Initialize cache lines only once
            // if (!cache_initialized) begin
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
                // end
                // cache_initialized = 1;  // Set the flag to indicate initialization is done
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

    
    initial begin
        integer i;
        // Initialize inputs 
        initialize();
        // Initialize main memory
        initialize_memory();
        // Apply reset
        reset();
         // Display initial values of main_mem
        $display("Initial values of main_mem:");
        for (i = 0; i < 8; i++) begin
            $display("main_mem[%0d] = %h", i, main_mem[i]); // Display in hex format
        end

        fork
            dummy_interconnect();
            dummy_cpu();
        join_any

        @(posedge clk);

        $display("Final values of main_mem:");
        for (i = 0; i < 8; i++) begin
            $display("main_mem[%0d] = %h", i, main_mem[i]); // Display in hex format
        end

        $finish;
    end


endmodule