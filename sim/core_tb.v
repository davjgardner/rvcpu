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
      if (cnt == 1000) begin
         $finish;
      end
   end

   wire mem_read_valid;
   wire mem_write_valid;
   wire  mem_ready = 1'b0;

   wire [1:0] mem_width;

   wire [31:0] mem_addr;

   wire [31:0] mem_read_data = 32'h0;
   wire [31:0] mem_write_data;

   memctl mem(.clk(clk),
              .rst(rst),
              .mem_addr(mem_addr),
              .mem_read_valid(mem_read_valid),
              .mem_write_valid(mem_write_valid),
              .mem_write_data(mem_write_data),
              .mem_width(mem_width),
              .mem_ready(mem_ready));

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
