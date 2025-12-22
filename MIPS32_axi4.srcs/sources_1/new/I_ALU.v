`timescale 1ns / 1ps
module ALU_I(
    input  wire [5:0]  op           ,
    input  wire [31:0] data_rs      ,
    input  wire [15:0] immediate    ,
    output wire [31:0] data_rt      
);
wire [31:0] Immediate = {16'b0,immediate};
wire [31:0] Immediate_signed = {{16{immediate[15]}}, immediate};
assign data_rt =(op==6'b001000||op[5]==1'b1)?data_rs+Immediate_signed                :
                (op==6'b001001)?data_rs+Immediate                       :
                (op==6'b001100)?data_rs&Immediate                       :
                (op==6'b001101)?data_rs|Immediate                       :
                (op==6'b001110)?data_rs^Immediate                       :
                (op==6'b001111)?{immediate,16'b0}                       :
                (op==6'b001010)?(data_rs<Immediate_signed?32'b1:32'b0)  :
                (op==6'b001011)?(data_rs<Immediate?32'b1:32'b0)         :
                (op==6'b000000)?(
                    (func==6'b100000)?(data_rs+data_rt)://add
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
                ):
                32'b0;

endmodule
