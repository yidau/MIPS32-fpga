`timescale 1ns / 1ps
module REG_FILE(
    input  wire         clk     ,
    input  wire         reset   ,    
    input  wire [4:0]   reg_ra1     ,//读地址1
    input  wire [4:0]   reg_ra2     ,//读地址2
    output wire [31:0]  reg_rd1     ,//读数据1
    output wire [31:0]  reg_rd2     ,//读数据2  
    input  wire         reg_we      ,//写使能
    input  wire [4:0]   reg_wa      ,//写地址
    input wire [31:0]   reg_wd      //写数据  

);
reg [31:0] regs[31:0];
assign reg_rd1 = (reg_ra1==0)?32'b0:regs[reg_ra1];
assign reg_rd2 = (reg_ra2==0)?32'b0:regs[reg_ra2];
integer i;
always @(posedge clk or posedge reset) begin
        if (reset) begin 
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end else if (reg_we && (reg_wa != 0)) begin
            regs[reg_wa] <= reg_wd;
        end
    end
endmodule

