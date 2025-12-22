`timescale 1ns / 1ps

module ID#(
    parameter KSEG0         = 3'b100            ,
    parameter KSEG1         = 3'b101            ,
    parameter ASID_WIDTH    = 8                 ,
    parameter IN_WIDTH      = 40                ,
    parameter OUT_WIDTH     = 104
)(
    input   wire                    clk         ,
    input   wire                    reset       ,

    input wire  [IN_WIDTH-1:0]      input_bus   ,//IF段为PC
    output reg  [OUT_WIDTH-1:0]     output_bus  ,//IF段为指令
    input wire                      stall       ,//系统的阻塞信号
    input wire                      flush       ,//由于分支预测被清除的信号
    //REG_FILE port
    input  wire [4:0]               reg_ra1     ,//读地址1
    input  wire [4:0]               reg_ra2     ,//读地址2
    output wire [31:0]              reg_rd1     ,//读数据1
    output wire [31:0]              reg_rd2      ,//读数据2   
    //cpu port
    output wire [2:0]               br_en       ,
    //CP0 port
    output  wire [4:0]              CP0_raddr       ,//读地址
    input wire [31:0]               CP0_rdata           //读数据
);

reg [IN_WIDTH-1:0] input_bus_reg;
always @(posedge clk or posedge reset) begin
    if (reset)
        input_bus_reg<=0;
    else if(stall)
        input_bus_reg<=input_bus_reg;
    else if(flush)
        input_bus_reg<=0;
    else  
        input_bus_reg<=input_bus;
end
wire [5:0] op;
wire [4:0] rs;
wire [4:0] rt;
wire [4:0] rd;
wire [4:0] sharmt;
wire [5:0] func;
wire [ASID_WIDTH-1:0] asid;
assign {op,rs,rt,rd,sharmt,func,asid} = input_bus_reg;
assign reg_rd1=rs;
assign reg_rd2=rt;
assign CP0_raddr = rt;

assign br_en = (op==6'b000000 && func==6'b001000) ? 3'b001 : // jr
                 (op==6'b000100) ? 3'b010 : // beq
                 (op==6'b000101) ? 3'b011 : // bne
                 (op==6'b000010) ? 3'b100 : // j
                 (op==6'b000011) ? 3'b101 : // jal
                 3'b000; // 默认不跳转
always @(*) begin
    output_bus={op,rs,rt,rd,sharmt,func,reg_rd1,reg_rd2,asid};
end


endmodule
/*
如果阻塞，保存上一流水的内容，不发送下一流水
阻塞结束，读取上一流水内容，发送下一流水
一个周期能完成，阻塞一周期后读取上一流水，阻塞一周期发送
第二个周期能完成，直接读取上一流水，直接发送
超过了第二个周期，相当于阻塞

*/