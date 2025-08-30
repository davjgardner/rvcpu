"""Makes a `rom.v` file with initialized read-only memory"""

import argparse
import struct
from pathlib import Path

fmt = """
module {name}(input wire         clk,
           input wire         rst,
           input wire [31:0]  mem_addr,
           input wire         mem_read_valid,
           input wire [1:0]   mem_width,
           output reg [31:0]  mem_read_data = 32'b0,
           output reg         mem_ready = 1'b0);

   wire [31:0] rom [0:{size}];

   // Memory widths for mem_width signal
   localparam MEM_B = 2'd0;
   localparam MEM_H = 2'd1;
   localparam MEM_W = 2'd2;

   wire [29:0] word_idx = mem_addr[31:2];
   wire        halfword_idx = mem_addr[1];
   wire [1:0]  byte_idx = mem_addr[1:0];

   {data}

   always @(posedge clk) begin
      mem_ready <= 1'b0;
      if (rst) begin
         // do nothing
      end
      else begin
         if (mem_read_valid) begin
            mem_read_data <= (mem_width == MEM_B?
                              (byte_idx == 2'd0? {{24'b0, rom[word_idx][7:0]}}:
                               byte_idx == 2'd1? {{24'b0, rom[word_idx][15:8]}}:
                               byte_idx == 2'd2? {{24'b0, rom[word_idx][23:16]}}:
                               {{24'b0, rom[word_idx][31:24]}}):
                              mem_width == MEM_H?
                              (halfword_idx? {{16'b0, rom[word_idx][31:16]}}:
                               {{16'b0, rom[word_idx][15:0]}}):
                              rom[word_idx]);
            mem_ready <= 1'b1;
         end // if (mem_read_valid)
      end // if (!rst)
   end // always @(posedge clk)


endmodule // {name}
"""

def mkrom(name, data):
    data_words = []
    for i in range(len(data)//4):
        word = struct.unpack('<I', data[i*4 : i*4+4])[0]
        data_words.append(word)
    if len(data) % 4 != 0:
        byte_left = len(data) % 4
        last_bytes = data[-bytes_left:]
        # prepend with nulls
        last_word = b'\x00' * (4 - bytes_left) + last_bytes
        data_words.append(struct.unpack('<I', last_word)[0])
    datastr = '\n   '.join([f"assign rom[{i}] = 32'h{v:08x};" for (i, v) in enumerate(data_words)])
    size = len(data_words)
    return fmt.format(name=name, data=datastr, size=size-1)

def main():
    parser = argparse.ArgumentParser()

    parser.add_argument('bin_file', type=Path, help='Input ROM binary')
    parser.add_argument('output_file', type=Path, help='Output verilog file')
    parser.add_argument('--name', type=str, default='rom', help='Module name to use')

    args = parser.parse_args()
    with args.bin_file.open('rb') as infile:
        data = infile.read()
    verilog_str = mkrom(args.name, data)
    with args.output_file.open('w') as outfile:
        outfile.write(verilog_str)



if __name__ == '__main__':
    main()
