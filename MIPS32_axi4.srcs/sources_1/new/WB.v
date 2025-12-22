`timescale 1ns / 1ps

module WB#(
    parameter KSEG0         = 3'b100            ,
    parameter KSEG1         = 3'b101            ,
    parameter ASID_WIDTH = 8,
    parameter IN_WIDTH = 72
)(
    input   wire                    clk,
    input   wire                    reset,

    input wire  [IN_WIDTH-1:0] input_bus,//IF段为PC
    input wire  stall,//系统的阻塞信号
    input wire  flush,//由于分支预测被清除的信号
    //REG_FILE port
    output  wire         reg_we      ,//写使能
    output  wire [4:0]    reg_wa      ,//写地址
    output  wire [31:0]   reg_wd     ,//写数据  

    //CP0 port
    output  wire                     wen             ,//写使能
    output  wire [4:0]               waddr           ,//写地址
    output  wire [31:0]              wdata           //写数据 
);


wire [5:0] op;
wire [4:0] rs;
wire [4:0] rt;
wire [4:0] rd;
wire [4:0] sharmt;
wire [5:0] func;
wire [31:0] data;
wire [ASID_WIDTH-1:0] asid;
assign {op,rs,rt,rd,sharmt,func,data,asid} = input_bus;

assign reg_we=(op==6'b000000)||
                (op==6'b001000)||(op==6'b001001)||(op==6'b001100)||(op==6'b001101)||
                (op==6'b001110)||(op==6'b001111)||(op==6'b001010)||(op==6'b001011);
assign reg_wa=(op==6'b000000)?rd:
                rt;
assign wdata=data;

assign wen=(op==6'b010000);
assign waddr=rt;
assign wdata=data;


endmodule
/*
如果阻塞，保存上一流水的内容，不发送下一流水
阻塞结束，读取上一流水内容，发送下一流水
一个周期能完成，阻塞一周期后读取上一流水，阻塞一周期发送
第二个周期能完成，直接读取上一流水，直接发送
超过了第二个周期，相当于阻塞

*/