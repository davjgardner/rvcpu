`timescale 1ns/1ps;


module core_tb();

   reg clk = 1'b0;
   reg rst = 1'b1;

   reg [31:0] cnt = 32'h0;
   wire       instruction_retired;

   always begin
      clk <= ~clk;
      #10; // IDK
   end

   always @(posedge clk) begin
      cnt <= cnt + 1;
   end;

   wire fetch_valid;
   wire mem_read_valid;
   wire mem_write_valid;

   wire [31:0] fetch_addr;
   wire [31:0] mem_addr;

   reg [31:0] fetch_data = 32'h0;
   reg [31:0] mem_read_data = 32'h0;
   wire [31:0] mem_write_data;

   core corei(
              .clk(clk),
              .rst(rst),
              .fetch_data(fetch_data),
              .fetch_addr(fetch_addr),
              .fetch_valid(fetch_valid),
              .mem_read_valid(mem_read_valid),
              .mem_write_valid(mem_write_valid),
              .mem_read_data(mem_read_data),
              .mem_write_data(mem_write_data),
              .instruction_retired(instruction_retired)
              );

   /*
    // Fibonacci
    // Initialize x1 and x2
    add  x1, x0, x0
    addi x2, x0, 1
    // 10 iterations
    addi x4, x0, 10
loop:
    // temp = x1 + x2
    add  x3, x1, x2
    // x1 = x2
    add  x1, x0, x2
    // x2 = temp
    add  x2, x0, x3
    // x4--
    addi x4, x4, -1
    // branch if x4 not 0
    bne  x4, x0, loop
    // move result to ra
    add x1, x0, x3

    */

   wire [31:0] progmem [0:8];
   assign progmem[0] = 32'h000000b3; // 00
   assign progmem[1] = 32'h00100113; // 04
   assign progmem[2] = 32'h00a00213; // 08
   assign progmem[3] = 32'h002081b3; // 0c
   assign progmem[4] = 32'h002000b3; // 10
   assign progmem[5] = 32'h00300133; // 14
   assign progmem[6] = 32'hfff20213; // 18
   assign progmem[7] = 32'hfe0218e3; // 1c
   assign progmem[8] = 32'h003000b3; // 20

   // memory operations
   always @(posedge clk) begin
      if (fetch_valid) begin
         fetch_data <= progmem[fetch_addr >> 2];
      end
      if (mem_read_valid) begin
         // TODO retreive data at address mem_addr and place in mem_read_data
         mem_read_data <= 32'd0;
      end
      if (mem_write_valid) begin
         // TODO set data at address mem_addr to mem_write_data
      end
   end

   // instruction counter
   reg [31:0] instruction_counter = 32'd0;
   always @(posedge clk) begin
      if (instruction_retired) begin
         instruction_counter = instruction_counter + 1;
      end
   end

   initial begin
      rst <= 1'b1;
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      rst <= 1'b0;

      wait (fetch_addr == 32'h20);
      //wait (instruction_counter == 32'd20);

      @(posedge clk);
      @(posedge clk);
      $finish;

   end

   integer i;
   initial begin
      $dumpfile("core_tb.vcd");
      $dumpvars(0);
      for (i = 0; i < 32; i = i+1) begin
         $dumpvars(0, corei.regfile[i]);
      end

   end

endmodule // core_tb
