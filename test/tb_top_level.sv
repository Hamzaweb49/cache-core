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
    
    // Testbench tasks
    task initialize;
    begin
        rst_n = 1;
        cpu_request = 2'b10;
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
    
    task drive_cpu_write(input logic [31:0]cpu_addr_i, input logic [31:0]cpu_wdata_i);
    begin
        @(posedge clk);
        cpu_request = 2'b01; // Example write request
        cpu_addr = cpu_addr_i;
        cpu_wdata = cpu_wdata_i;
        @(posedge clk);
        while(!cache_ready) @(posedge clk);
        cpu_request = 2'b10;
        while(!cache_complete) @(posedge clk);
    end
    endtask
    task Read_from_interconnect;
        forever begin
            AR_READY = 1;
            @(posedge clk);
            while(!AR_VALID) @(posedge clk);
            AR_READY = 0;

            give_rdata_from_interconnect();
            R_VALID = 1;
            @(posedge clk);
            while(!R_READY) @(posedge clk);
            R_VALID = 0;
        end
    endtask
    task Write_to_interconnect;
        forever begin
            AW_READY = 1;
            @(posedge clk);
            while(!AW_VALID) @(posedge clk);
            AW_READY = 0;

            // give_rdata_from_interconnect();
            W_READY = 1;
            @(posedge clk);
            while(!W_VALID) @(posedge clk);
            W_READY = 0;

            B_VALID = 1;
            BRESP  = 2'b00; 
            @(posedge clk);
            while(!B_READY) @(posedge clk);
            B_VALID = 0;
        end
    endtask
    task give_rdata_from_interconnect;
        logic [1:0] local_var;
        begin
            @(posedge clk);
            local_var = $urandom;
            case(local_var) 
                2'b00: begin
                    RDATA = 32'hAAAAAAAA;
                    RRESP = 4'b1100;
                end
                2'b01: begin
                    RDATA = 32'hBBBBBBBB;
                    RRESP = 4'b1000;
                end
                2'b10: begin
                    RDATA = 32'hCCCCCCCC;
                    RRESP = 4'b0000;
                end
                2'b11: begin
                    RDATA = 32'hDDDDDDDD;
                    RRESP = 4'b0000;
                end
                default: begin
                    RDATA = 32'hABCDABCD;
                    RRESP = 4'b0000;
                end
            endcase
        end
    endtask
    
    task drive_cpu_read(input logic [31:0] cpu_addr_i);
        begin
            @(posedge clk);
            cpu_request = 2'b00; // Example read request
            cpu_addr = cpu_addr_i;
            @(posedge clk);
            while(!cache_ready) @(posedge clk);
            cpu_request = 2'b10;
            while(!cache_complete) @(posedge clk);
        end
    endtask

    task drive_interconnect_snoop(input logic [31:0]AC_ADDR_i, input logic [3:0]AC_SNOOP_i);
        begin
            @(posedge clk);
            AC_ADDR = AC_ADDR_i;
            AC_SNOOP = AC_SNOOP_i;
            AC_VALID = 1;
            @(posedge clk);
            while(!AC_READY) @(posedge clk);
            AC_VALID = 0;
            //  -----//
            // AC_ADDR = AC_ADDR_i + 1;
            // AC_SNOOP = 4'b0000;
            // -----//
            @(posedge clk);
            while(!AC_READY) @(posedge clk);
        end
    endtask
    task Response_to_snoop;
        forever begin
            CR_READY = 0;
            @(posedge clk);
            while(!CR_VALID) @(posedge clk);
            CR_READY = 1;
            @(posedge clk);
            CR_READY = 0;
        end
    endtask
    task Data_to_snoop;
        forever begin
            CD_READY = 1;
            @(posedge clk);
            while(!CD_VALID) @(posedge clk);
            CD_READY = 0;
        end
    endtask

    // Monitor task for CPU side
    task monitor_cpu_side;
        logic [31:0] write_data;
        forever begin
            @(posedge clk);
            // while(!(cpu_request == 2'b00) || !(cpu_request == 2'b01)) @(posedge clk);
            while((cpu_request != 2'b00) && (cpu_request != 2'b01)) @(posedge clk);
            if (cpu_request == 2'b01) begin // Write request
                $display("CPU Write: Addr = %h, Data = %h", cpu_addr, cpu_wdata);
                write_data = cpu_wdata;
                while(!cache_complete) @(posedge clk);
                @(posedge clk);
                if(cpu_rdata == write_data) begin
                    $display("CPU write SUCCESS:  rdata: %h, wdata: %h", cpu_rdata, write_data);
                end else begin
                    $display("CPU write Fail: rdata: %h, wdata: %h", cpu_rdata, write_data);
                end
            end
            else if (cpu_request == 2'b00) begin // Read request
                $display("CPU Read: Addr = %h", cpu_addr);
                while(!cache_complete) @(posedge clk);
                $display("CPU read SUCCESS");
                $display("cpu_rdata: %h", cpu_rdata);
            end
        end
    endtask

    initial begin
        fork
            Read_from_interconnect();
            Write_to_interconnect();
        join_none
    end
    initial begin
        fork
            Response_to_snoop();
            Data_to_snoop();
            monitor_cpu_side();
        join_none
    end

    initial begin
        initialize();
        reset();
        
       // Example sequence
        // Read from the Cache
        drive_cpu_read(32'h00000018);
        repeat(10) @(posedge clk);
        // Write to the same Cache address
        drive_cpu_write(32'h00000000, 32'hDEADBEEF);

        // Write to another Cache address
        drive_cpu_write(32'h00000010, 32'hFEEDBEEF);
        // Write to same index but different tag --> WRITE MISS
        drive_cpu_write(32'h01000010, 32'hDEADDEED);

        drive_cpu_read(32'h01000010);

        repeat($urandom % 10) @(posedge clk);
        
        drive_interconnect_snoop(32'h00000018, 4'b0001);
        
        // End simulation
        #100;
        $finish;
    end
    initial begin
        $dumpfile("Top_level.vcd");
        $dumpvars(0);
    end
endmodule
    