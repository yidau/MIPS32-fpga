`timescale 1ns / 1ps
module CP0(
    input  wire                     clk             ,
    input  wire                     reset           ,   
    // MFC MTC          
    input  wire [4:0]               CP0_raddr           ,//读地址
    output wire [31:0]              CP0_rdata           ,//读数据
    input  wire                     CP0_wen             ,//写使能
    input  wire [4:0]               CP0_waddr           ,//写地址
    input  wire [31:0]              CP0_wdata           ,//写数据  
    // TLB_INST
    input  wire                     tlbr_en         ,//tlbr指令使能
    input  wire                     tlbp_en         ,//tlbp指令使能
    input  wire [31:0]              input_entryhi   ,//CP0寄存器输入 
    input  wire [31:0]              input_entrylo0  ,//CP0寄存器输入 
    input  wire [31:0]              input_entrylo1  ,//CP0寄存器输入 
    input  wire [31:0]              input_pagemask  ,//CP0寄存器输入 
    input  wire [31:0]              input_index     ,//CP0寄存器输入     
    output wire [31:0]              output_entryhi  ,//CP0寄存器输出 
    output wire [31:0]              output_entrylo0 ,//CP0寄存器输出 
    output wire [31:0]              output_entrylo1 ,//CP0寄存器输出 
    output wire [31:0]              output_pagemask ,//CP0寄存器输出 
    output wire [31:0]              output_index     //CP0寄存器输出    
);

//mfc mtc

reg [31:0] regs[31:0];
assign CP0_rdata = regs[CP0_raddr];
integer i;
always @(posedge clk or posedge reset) begin
    if (reset) begin
        
        for (i = 0; i < 32; i = i + 1)
            regs[i] <= 32'b0;
    end else if (CP0_wen==1'b0) begin
        regs[CP0_waddr] <= CP0_wdata;
    end else if (tlbr_en==1'b1)begin
        regs[10]<=input_entryhi  ; 
        regs[2] <=input_entrylo0 ; 
        regs[3] <=input_entrylo1 ; 
        regs[5] <=input_pagemask ;          
    end else if (tlbp_en==1'b1)begin
        regs[0]  <=input_index   ; 
    end else begin
        regs[1] <=regs[1]+32'b1  ;
    end    
end
//tlb_inst
assign output_entryhi  = regs[10];
assign output_entrylo0 = regs[2] ;
assign output_entrylo1 = regs[3] ;
assign output_pagemask = regs[5] ;
assign output_index    = regs[0] ;
endmodule