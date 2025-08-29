module ram
  #(parameter SIZE = 32'h1000)

   (input wire        clk,
    input wire        rst,
    input wire [31:0] mem_addr,
    input wire        mem_read_valid,
    input wire        mem_write_valid,
    input wire [31:0] mem_write_data,
    input wire [1:0]  mem_width,
    output reg [31:0] mem_read_data,
    output reg        mem_ready);


   // Memory widths for mem_width signal
   localparam MEM_B = 2'd0;
   localparam MEM_H = 2'd1;
   localparam MEM_W = 2'd2;

   reg [31:0] mem [0:SIZE-1];

   wire [31:0] mem_read_word = mem[mem_addr >> 2];

   integer    i;

   always @(posedge clk) begin
      // DEFAULT ASSIGNMENT
      mem_ready <= 1'b0;

      if (rst) begin
         for (i = 0; i < SIZE; i = i+1) begin
            mem[i] <= 32'b0;
         end
         mem_read_data <= 32'b0;
         mem_ready <= 1'b0;
      end
      else begin
         if (mem_read_valid) begin
            case (mem_width)
              MEM_W: begin
                 mem_read_data <= mem[mem_addr >> 2];
              end
              MEM_H: begin
                 mem_read_data <= (mem_addr[1]? {16'b0, mem_read_word[31:16]}:
                                   {16'b0, mem_read_word[15:0]});
              end
              MEM_B: begin
                 mem_read_data <= (mem_addr[1:0] == 2'd0? {24'b0, mem_read_word[7:0]}:
                                   mem_addr[1:0] == 2'd1? {24'b0, mem_read_word[15:8]}:
                                   mem_addr[1:0] == 2'd1? {24'b0, mem_read_word[23:16]}:
                                   {24'b0, mem_read_word[31:24]});
              end
            endcase // case (mem_width)
            mem_ready <= 1'b1;
         end // if (mem_read_valid)
         if (mem_write_valid) begin
            case (mem_width)
              MEM_W: begin
                 mem[mem_addr >> 2] <= mem_write_data;
              end
              MEM_H: begin
                 mem[mem_addr >> 2] <= (mem_addr[1]? {mem_write_data[15:0],
                                                      mem_read_word[15:0]}:
                                        {mem_read_word[31:16], mem_write_data[15:0]});
              end
              MEM_B: begin
                 mem[mem_addr >> 2] <= (mem_addr[1:0] == 2'd0? {mem_read_word[31:8],
                                                                mem_write_data[7:0]}:
                                        mem_addr[1:0] == 2'd1? {mem_read_word[31:16],
                                                                mem_write_data[7:0],
                                                                mem_read_word[7:0]}:
                                        mem_addr[1:0] == 2'd2? {mem_read_word[31:24],
                                                                mem_write_data[7:0],
                                                                mem_read_word[15:0]}:
                                        {mem_write_data[7:0], mem_read_word[23:0]});
              end // case: MEM_B
            endcase // case (mem_width)
         end // if (mem_write_valid)
      end // else: !if(rst)
   end // always @ (posedge clk)


endmodule // memctl
