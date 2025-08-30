module memctl(input wire         clk,
              input wire         rst,
              input wire [31:0]  mem_addr,
              input wire         mem_read_valid,
              input wire         mem_write_valid,
              input wire [31:0]  mem_write_data,
              input wire [1:0]   mem_width,
              output wire [31:0] mem_read_data,
              output wire        mem_ready);


   // Memory widths for mem_width signal
   localparam MEM_B = 2'd0;
   localparam MEM_H = 2'd1;
   localparam MEM_W = 2'd2;

   localparam RAM_SIZE = 32'h1000;
   localparam RAM_BASE = 32'h1000;
   localparam ROM_BASE = 32'h0;
   localparam ROM_MAX = 32'hfff;

   wire       target_rom = mem_addr < ROM_MAX;
   wire       target_ram = mem_addr > RAM_BASE && mem_addr < RAM_BASE + RAM_SIZE;

   wire [31:0] decoded_addr = (target_ram? mem_addr - RAM_BASE:
                               target_rom? mem_addr:
                               32'b0);

   wire       rom_ready;
   wire [31:0] rom_read_data;

   rom progmem(.clk(clk),
               .rst(rst),
               .mem_addr(mem_addr),
               .mem_read_valid(target_rom && mem_read_valid),
               .mem_width(mem_width),
               .mem_read_data(rom_read_data),
               .mem_ready(rom_ready));

   wire [31:0] ram_read_data;
   wire        ram_ready;

   wire        ram_read_valid = target_ram && mem_read_valid;
   wire        ram_write_valid = target_ram && mem_write_valid;

   ram #(.SIZE(RAM_SIZE)) datamem (.clk(clk),
                                 .rst(rst),
                                 .mem_addr(decoded_addr),
                                 .mem_read_valid(ram_read_valid),
                                 .mem_write_valid(ram_write_valid),
                                 .mem_write_data(mem_write_data),
                                 .mem_width(mem_width),
                                 .mem_read_data(ram_read_data),
                                 .mem_ready(ram_ready));

   assign mem_ready = (target_rom & rom_ready) | (target_ram & ram_ready);

   assign mem_read_data = (target_rom? rom_read_data:
                           target_ram? ram_read_data:
                           32'b0);



endmodule // memctl
