`timescale 1ns / 1ps
module IF#(
    parameter KSEG0         = 3'b100            ,
    parameter KSEG1         = 3'b101            ,
    parameter ASID_WIDTH    = 8                 ,
    parameter IN_WIDTH      = 32                ,
    parameter OUT_WIDTH     = 40
)(
    input   wire                    clk             ,
    input   wire                    reset           ,

    input wire  [IN_WIDTH-1:0]      input_bus       ,//IF段为PC
    output reg  [OUT_WIDTH-1:0]     output_bus      ,//IF段为指令
    input wire                      stall           ,//系统的阻塞信号
    input wire                      flush           ,//由于分支预测被清除的信号

    //TLB port
    output  wire                    tlb_valid_if    ,//if段需要tlb转换时拉高
    output  wire [31:0]             vaddr_if        ,//if段虚拟地址
    output  wire [ASID_WIDTH-1:0]   asid_if         ,//if段进程地址
    input   wire [31:0]             paddr_if        ,//if段物理地址输出
    input   wire                    hit_if          ,//if段命中时拉高
    input   wire                    miss_if         ,//if段未命中时拉高
    input   wire                    tlb_invalid_if  ,//if段触发tlb_invalid
    //I-CACHE port
    output  wire                    cache_valid     ,
    output  wire [11:0]             offset          ,
    input   wire                    cache_ack       ,
    input   wire [19:0]             tag             ,
    input   wire [31:0]             data            ,
    //bios port
    output  reg                     bios_en         ,
    output  reg  [5:0]              bios_addr       ,
    input   wire [31:0]             bios_data       ,
    //CPU port
    input   wire [ASID_WIDTH-1:0]   asid
);
assign tlb_valid_if=0;
assign vaddr_if=0;
assign asid_if =0;
assign cache_valid=0;
assign offset     =0;
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
wire [IN_WIDTH-1:0] pc=input_bus;
always @(*) begin
    output_bus=0;
    bios_en=0;
    if(input_bus[31:29]==KSEG1) begin
        bios_en=1;
        bios_addr=pc[5:0];
    end
    if(input_bus_reg[31:29]==KSEG1) 
        output_bus={bios_data,asid};
end


endmodule
/*
如果阻塞，保存上一流水的内容，不发送下一流水
阻塞结束，读取上一流水内容，发送下一流水
一个周期能完成，阻塞一周期后读取上一流水，阻塞一周期发送
第二个周期能完成，直接读取上一流水，直接发送
超过了第二个周期，相当于阻塞

*/