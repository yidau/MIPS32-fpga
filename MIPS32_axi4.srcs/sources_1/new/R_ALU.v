`timescale 1ns / 1ps
/*
纯组合逻辑,非乘除ALU
*/
module ALU_R(
input  wire [31:0]  data_rs     ,
input  wire [31:0]  data_rt     ,   
input  wire [4:0]   sharmt      ,
input  wire [5:0]   func        ,
output wire [31:0]  data_rd     ,
output wire         alu_exc     //算数溢出异常
);
assign data_rd= (func==6'b100000)?(data_rs+data_rt)://add
                (func==6'b100001)?(data_rs+data_rt)://addu
                (func==6'b100010)?(data_rs-data_rt)://sub
                (func==6'b100011)?(data_rs-data_rt)://subu
                (func==6'b100100)?(data_rs&data_rt)://and
                (func==6'b100101)?(data_rs|data_rt)://or
                (func==6'b100110)?(data_rs^data_rt)://xor
                (func==6'b100111)?(~(data_rs|data_rt))://nor
                (func==6'b101010)?($signed(data_rs)<$signed(data_rt)?32'b1:32'b0)://slt
                (func==6'b101011)?(data_rs<data_rt?32'b1:32'b0)://sltu
                (func==6'b000000)?(data_rt<<sharmt)://sll
                (func==6'b000010)?(data_rt>>sharmt)://srl
                (func==6'b000011)?($signed(data_rt)>>>sharmt)://sra
                (func==6'b000100)?(data_rt<<data_rs)://sllv
                (func==6'b000110)?(data_rt>>data_rs)://srlv
                (func==6'b000111)?($signed(data_rt)>>>data_rs)://srav
                32'b0;
assign alu_exc= (func==6'b100000) ? 
                ((~data_rs[31] & ~data_rt[31] & data_rd[31])| 
                (data_rs[31] & data_rt[31] & ~data_rd[31])):
                (func==6'b100010) ? 
                ((~data_rs[31] & data_rt[31] & data_rd[31])| 
                (data_rs[31] & ~data_rt[31] & ~data_rd[31])):
                1'b0;
endmodule

