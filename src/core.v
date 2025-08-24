module core(
            input wire        clk,
            input wire        rst,
            input wire [31:0] fetch_data,
            input wire [31:0] mem_read_data,
            output wire [31:0] fetch_addr,
            output reg        fetch_valid = 1'b0,
            output reg [31:0] mem_addr = 32'h0,
            output reg        mem_read_valid,
            output reg        mem_write_valid,
            output reg [31:0] mem_write_data = 32'h0,
            output reg instruction_retired = 1'b0
);

   // how do we begin?
   // start with an input register for instruction, deal with fetches later when we have memory
   // maybe we can be a little smarter to begin with:
   // - have inputs/outputs for memory reads/writes

   // I don't think I'm going to try to make it pipelined, to begin with

   // x0-x31 registers
   // note that x0 is always 0, technically could make this size 31
   // - for now rely on the fact that at rst all regs are 0, and x0 is never written
   // other special registers:
   // - x1 = ra = return addr
   // - x2 = sp
   reg [31:0] regfile [0:31];
   reg [31:0] pc = 32'h0;
   assign fetch_addr = pc;

   // 4 stages (FSM states?):
   // 1. fetch
   //   - set fetch_addr to $pc
   // 2. decode
   //   - should be purely combinatorial, I think
   // 3. execute
   // 4. writeback

   localparam STATE_FETCH = 0;
   localparam STATE_MEM = 1;
   localparam STATE_EXECUTE = 2;
   localparam STATE_WRITEBACK = 3;

   reg [1:0]  state = STATE_FETCH;

   // because it's nicer to look at
   wire [31:0] instr = fetch_data;
   // instruction decoding
   wire [6:0]  opcode = instr[6:0]; // all types
   wire [4:0]  rd = instr[11:7]; // types R, I, U, J
   wire [2:0]  funct3 = instr[14:12]; // types R, I, S, B
   wire [4:0]  rs1 = instr[19:15]; // types R, I, S, B
   wire [4:0]  rs2 = instr[24:20]; // types R, S, B
   wire [6:0]  funct7 = instr[31:25]; // type R

   wire        is_r_type = opcode == 7'b0110011;
   wire        is_i_type = opcode == 7'b0010011 || opcode == 7'b0000011 || opcode == 7'b1100111 || opcode == 7'b1110011;
   wire        is_s_type = opcode == 7'b0100011;
   wire        is_b_type = opcode == 7'b1100011;
   wire        is_u_type = opcode == 7'b0110111 || opcode == 7'b0010111;
   wire        is_j_type = opcode == 7'b1101111;

   wire        is_load   = opcode == 7'b0000011;

   wire        rd_valid = is_r_type || is_i_type || is_u_type || is_j_type;
   wire        is_mem = is_load || is_s_type;


   // R type has no immediate
   // immediate must be sign-extended
   wire [31:0] imm = (is_i_type? {{20{instr[31]}}, instr[31:20]}:
                      is_s_type? {{20{instr[31]}}, instr[31:25], instr[11:7]}:
                      is_b_type? {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}:
                      is_u_type? {instr[31:12], 12'b0}:
                      is_j_type? {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21]}:
                      32'b0);

   wire        is_add   = is_r_type && funct3 == 3'h0 && funct7 == 7'h00;
   wire        is_sub   = is_r_type && funct3 == 3'h0 && funct7 == 7'h20;
   wire        is_xor   = is_r_type && funct3 == 3'h4 && funct7 == 7'h00;
   wire        is_or    = is_r_type && funct3 == 3'h6 && funct7 == 7'h00;
   wire        is_and   = is_r_type && funct3 == 3'h7 && funct7 == 7'h00;
   wire        is_sll   = is_r_type && funct3 == 3'h1 && funct7 == 7'h00;
   wire        is_srl   = is_r_type && funct3 == 3'h5 && funct7 == 7'h00;
   wire        is_sra   = is_r_type && funct3 == 3'h5 && funct7 == 7'h20;
   wire        is_slt   = is_r_type && funct3 == 3'h2 && funct7 == 7'h00;
   wire        is_sltu  = is_r_type && funct3 == 3'h3 && funct7 == 7'h00;

   // There are multiple categories of I-type instructions, so be explicit with the opcode
   wire        is_addi  = opcode == 7'b0010011 && funct3 == 3'h0;
   wire        is_xori  = opcode == 7'b0010011 && funct3 == 3'h4;
   wire        is_ori   = opcode == 7'b0010011 && funct3 == 3'h6;
   wire        is_andi  = opcode == 7'b0010011 && funct3 == 3'h7;
   wire        is_slli  = opcode == 7'b0010011 && funct3 == 3'h1 && imm[11:5] == 7'h00; // imm[11:5] is funct7
   wire        is_srli  = opcode == 7'b0010011 && funct3 == 3'h5 && imm[11:5] == 7'h00;
   wire        is_srai  = opcode == 7'b0010011 && funct3 == 3'h5 && imm[11:5] == 7'h20;
   wire        is_slti  = opcode == 7'b0010011 && funct3 == 3'h2;
   wire        is_sltiu = opcode == 7'b0010011 && funct3 == 3'h3;

   wire        is_lb    = is_load && funct3 == 3'h0;
   wire        is_lh    = is_load && funct3 == 3'h1;
   wire        is_lw    = is_load && funct3 == 3'h2;
   wire        is_lbu   = is_load && funct3 == 3'h4;
   wire        is_lhu   = is_load && funct3 == 3'h5;

   wire        is_sb    = is_s_type && funct3 == 3'h0;
   wire        is_sh    = is_s_type && funct3 == 3'h1;
   wire        is_sw    = is_s_type && funct3 == 3'h2;

   wire        is_beq   = is_b_type && funct3 == 3'h0;
   wire        is_bne   = is_b_type && funct3 == 3'h1;
   wire        is_blt   = is_b_type && funct3 == 3'h4;
   wire        is_bge   = is_b_type && funct3 == 3'h5;
   wire        is_bltu  = is_b_type && funct3 == 3'h6;
   wire        is_bgeu  = is_b_type && funct3 == 3'h7;

   wire        is_jal   = is_j_type;
   wire        is_jalr  = opcode == 7'b1100111 && funct3 == 3'h0;

   wire        is_lui   = opcode == 7'b0110111;
   wire        is_auipc = opcode == 7'b0010111;

   integer     i;

   // TODO not implemented:
   // - ecall, ebreak
   // - any extensions

   reg [31:0]  result = 32'h0;
   reg         branch_taken = 1'b0;

   always @(posedge clk) begin
      // DEFAULT ASSIGNMENTS
      fetch_valid <= 1'b0;
      mem_read_valid <= 1'b0;
      mem_write_valid <= 1'b0;
      branch_taken <= 1'b0;
      instruction_retired <= 1'b0;

      if (rst) begin
         pc <= 32'h0;
         state <= STATE_FETCH;
         for (i = 0; i < 32; i = i+1) begin
            regfile[i] <= 32'h0;
         end
         fetch_valid <= 1'b1;

      end
      else begin
         case (state)
           STATE_FETCH: begin
              // TODO may need to wait for a "ready" here in the future
              state <= STATE_EXECUTE;

           end
           STATE_EXECUTE: begin
              // start with arithmetic
              result <= (is_add? regfile[rs1] + regfile[rs2]:
                         is_sub? regfile[rs1] - regfile[rs2]:
                         is_xor? regfile[rs1] ^ regfile[rs2]:
                         is_or?  regfile[rs1] | regfile[rs2]:
                         is_and? regfile[rs1] & regfile[rs2]:
                         is_sll? regfile[rs1] << regfile[rs2]:
                         is_srl? regfile[rs1] >> regfile[rs2]:
                         is_sra? regfile[rs1] >>> regfile[rs2]:
                         is_slt? regfile[rs1] < regfile[rs2]:
                         is_sltu? regfile[rs1] < regfile[rs2]: // TODO

                         is_addi? regfile[rs1] + imm:
                         is_xori? regfile[rs1] ^ imm:
                         is_ori?  regfile[rs1] | imm:
                         is_andi? regfile[rs1] & imm:
                         is_slli? regfile[rs1] << imm:
                         is_srli? regfile[rs1] >> imm:
                         is_srai? regfile[rs1] >>> imm:
                         is_slti? regfile[rs1] < imm:
                         is_sltiu? regfile[rs1] < imm: // TODO
                         is_jal? pc + 4:
                         is_jalr? pc + 4:
                         32'd0);

              branch_taken <= (is_beq?  regfile[rs1] == regfile[rs2]:
                               is_bne?  regfile[rs1] != regfile[rs2]:
                               is_blt?  regfile[rs1] <  regfile[rs2]:
                               is_bge?  regfile[rs1] >= regfile[rs2]:
                               is_bltu? regfile[rs1] <  regfile[rs2]: // TODO
                               is_bgeu? regfile[rs1] >= regfile[rs2]: // TODO
                               1'b0);
              // deal with jal* separately

              if (is_load) begin
                 mem_addr <= regfile[rs1] + imm;
                 state <= STATE_MEM;
                 // TODO
              end


              state <= STATE_WRITEBACK;
           end
           STATE_MEM: begin
              // maybe we need to initiate memory stuff here?

           end
           STATE_WRITEBACK: begin
              // x0 never gets written back
              if (rd_valid && rd != 0) begin
                 regfile[rd] <= result;
              end

              pc <= (branch_taken? pc + imm:
                     is_jal? pc + imm:
                     is_jalr? regfile[rs1] + imm: // if rd == rs1 this will still get the old rs1
                     pc + 32'd4);
              // Set fetch valid here so data will be ready in the next state
              fetch_valid <= 1'b1;
              state = STATE_FETCH;
              instruction_retired <= 1'b1;
           end

         endcase // case (state)
      end

   end


endmodule // core
