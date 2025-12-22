`timescale 1ns / 1ps

module MEM#(
    parameter KSEG0         = 3'b100            ,
    parameter KSEG1         = 3'b101            ,
    parameter ASID_WIDTH    = 8                 ,
    parameter IN_WIDTH      = 104               ,
    parameter OUT_WIDTH     = 72
)(
    input   wire                    clk             ,
    input   wire                    reset           ,
    input wire  [IN_WIDTH-1:0]      input_bus       ,//IF段为PC
    output reg  [OUT_WIDTH-1:0]     output_bus      ,//IF段为指令
    input wire                      stall           ,//系统的阻塞信号
    input wire                      flush           ,//由于分支预测被清除的信号
    //TLB port
    output  wire                    tlb_valid_mem   ,//mem段需要tlb转换时拉高
    output  wire [31:0]             vaddr_mem       ,//mem段虚拟地址
    output  wire [ASID_WIDTH-1:0]   asid_mem        ,//mem段进程地址
    input   wire [31:0]             paddr_mem       ,//mem段物理地址输出
    input   wire                    hit_mem         ,//mem段命中时拉高
    input   wire                    miss_mem        ,//mem段未命中时拉高
    input   wire                    tlb_invalid_mem ,//mem段触发tlb_invalid
    //I-CACHE port
    output  wire                    cache_valid     ,
    output  wire [11:0]             offset          ,
    input   wire                    cache_ack       ,
    input   wire [19:0]             tag             ,
    input   wire [31:0]             data            ,
    //IO port
    output  reg [31:0]              gpio_addr       ,     // MMIO 地址
    output  reg [31:0]              gpio_wdata      ,    // 写数据
    output  reg                     gpio_wen        ,      // 写使能
    output  reg                     gpio_ren            // 读使能
);
assign tlb_valid_mem =0;
assign vaddr_mem     =0;
assign asid_mem      =0; 
assign cache_valid   =0;
assign offset        =0;

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
wire [15:0] immediate;
wire [31:0] mem_address_reg;
wire [ASID_WIDTH-1:0] asid;
assign {op,rs,rt,immediate,mem_address_reg,data_rt,asid} = input_bus_reg;
wire [31:0] mem_address=input_bus[39:8];
always @(*) begin
    output_bus=0;
    gpio_addr=0;
    gpio_wdata=0;
    gpio_wen=0;
    gpio_ren=0;
    if(mem_address[31:29]==KSEG1 && op==6'b101011) begin
       gpio_wen=1;
       gpio_addr=mem_address;
       gpio_wdata=data_rt;
    end
    if(input_bus_reg[31:29]==KSEG1) 
        output_bus={op,rs,rt,immediate,data,asid};
end
endmodule