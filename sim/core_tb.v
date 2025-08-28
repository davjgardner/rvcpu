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

   wire mem_read_valid;
   wire mem_write_valid;
   reg  mem_ready = 1'b0;

   // Not sure how to pull these over - maybe can access with corei.MEM_B, etc?
   // Memory widths for mem_width signal
   //localparam MEM_B = 2'd0;
   //localparam MEM_H = 2'd1;
   //localparam MEM_W = 2'd2;

   wire [1:0] mem_width;

   wire [31:0] mem_addr;

   reg [31:0] mem_read_data = 32'h0;
   wire [31:0] mem_write_data;

   core corei(
              .clk(clk),
              .rst(rst),
              .mem_read_valid(mem_read_valid),
              .mem_write_valid(mem_write_valid),
              .mem_addr(mem_addr),
              .mem_width(mem_width),
              .mem_read_data(mem_read_data),
              .mem_write_data(mem_write_data),
              .mem_ready(mem_ready),
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

   reg [31:0] progmem [0:8];
   // Combinatoric access to memory currently pointed to as convenience
   wire [31:0] mem_rd_sel = progmem[mem_addr >> 2];


   // memory operations
   always @(posedge clk) begin
      // DEFAULT ASSIGNMENT
      mem_ready <= 1'b0;

      if (mem_read_valid) begin
         // TODO handle misalignment
         mem_read_data <= (mem_width == corei.MEM_B? {24'b0, mem_rd_sel[7:0]}:
                           mem_width == corei.MEM_H? {16'b0, mem_rd_sel[15:0]}:
                           mem_rd_sel);
         mem_ready <= 1'b1;
      end
      if (mem_write_valid) begin
         // TODO handle data widths
         progmem[mem_addr >> 2] <= mem_write_data;
         mem_ready <= 1'b1;

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
      progmem[0] <= 32'h000000b3; // 00: add  x1, x0, x0
      progmem[1] <= 32'h00100113; // 04: addi x2, x0, 1
      progmem[2] <= 32'h00a00213; // 08: addi x4, x0, 10
      progmem[3] <= 32'h002081b3; // 0c: add  x3, x1, x2
      progmem[4] <= 32'h002000b3; // 10: add  x1, x0, x2
      progmem[5] <= 32'h00300133; // 14: add  x2, x0, x3
      progmem[6] <= 32'hfff20213; // 18: addi x4, x4, -1
      progmem[7] <= 32'hfe0218e3; // 1c: bne  x4, x0, -16
      progmem[8] <= 32'h003000b3; // 20: add  x1, x0, x3

      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      rst <= 1'b0;

      wait (mem_addr == 32'h20);
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
