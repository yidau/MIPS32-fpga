`timescale 1ns/1ps
module TLB#(
    parameter KSEG0         = 3'b100            ,
    parameter KSEG1         = 3'b101            ,

    parameter CACHE_NUM     = 64                ,
    parameter VPN_WIDTH     = 19                ,
    parameter ASID_WIDTH    = 8                 ,
    parameter INDEX_WIDTH   = $clog2(CACHE_NUM) ,
    parameter OFFSET_FORCE  = 32'h00000FFF  
)(
    input  wire                     clk             ,
    input  wire                     reset           ,
    // --- IF port (取指) ---   
    input  wire                     tlb_valid_if    ,//if段需要tlb转换时拉高
    input  wire [31:0]              vaddr_if        ,//if段虚拟地址
    input  wire [ASID_WIDTH-1:0]    asid_if         ,//if段进程地址
    output reg  [31:0]              paddr_if        ,//if段物理地址输出
    output reg                      hit_if          ,//if段命中时拉高
    output reg                      miss_if         ,//if段未命中时拉高
    output reg                      tlb_invalid_if  ,//if段触发tlb_invalid

    // --- MEM port (访存) ---
    input  wire                     tlb_valid_mem   ,//mem段需要tlb转换时拉高
    input  wire [31:0]              vaddr_mem       ,//mem段虚拟地址
    input  wire [ASID_WIDTH-1:0]    asid_mem        ,//mem段进程地址
    output reg  [31:0]              paddr_mem       ,//mem段物理地址输出
    output reg                      hit_mem         ,//mem段命中时拉高
    output reg                      miss_mem        ,//mem段未命中时拉高
    output reg                      tlb_invalid_mem ,//mem段触发tlb_invalid
    // ---CP0 port ---
    
    input  wire [2:0]               tlb_inst_en     ,//100:tlbwr 101:tlbwi 110:tlbr 111:tlbp
    input  wire [31:0]              input_entryhi   ,//CP0寄存器输入
    input  wire [31:0]              input_entrylo0  ,//CP0寄存器输入
    input  wire [31:0]              input_entrylo1  ,//CP0寄存器输入
    input  wire [31:0]              input_pagemask  ,//CP0寄存器输入
    input  wire [INDEX_WIDTH-1:0]   input_index     ,//CP0寄存器输入
    output wire [31:0]              output_entryhi  ,//CP0寄存器输出
    output wire [31:0]              output_entrylo0 ,//CP0寄存器输出
    output wire [31:0]              output_entrylo1 ,//CP0寄存器输出
    output wire [31:0]              output_pagemask ,//CP0寄存器输出
    output wire [INDEX_WIDTH-1:0]   output_index    ,//CP0寄存器输出
    output wire                     output_is_probed //probe成功信号
);
always @(*) begin
    if(tlb_valid_if==1'b1&&vaddr_if[31:29]==KSEG1) begin
        paddr_if=vaddr_if;
        hit_if=1'b1;
        miss_if=1'b0;
        tlb_invalid_if=1'b0;
    end
end

endmodule