`timescale 1ns / 1ps

module EXE#(
    parameter KSEG0         = 3'b100            ,
    parameter KSEG1         = 3'b101            ,
    parameter ASID_WIDTH    = 8                 ,
    parameter IN_WIDTH      = 104               ,
    parameter OUT_WIDTH     = 104
)(
    input   wire                    clk,
    input   wire                    reset,

    input wire  [IN_WIDTH-1:0]      input_bus,//IF段为PC
    output reg  [OUT_WIDTH-1:0]     output_bus,//IF段为指令
    input wire                      stall,//系统的阻塞信号
    input wire                      flush,//由于分支预测被清除的信号

    //cpu port
    output wire                     alu_exc

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
wire [31:0] data_rs;
wire [31:0] data_rt;
wire [ASID_WIDTH-1:0] asid;
assign {op,rs,rt,rd,sharmt,func,data_rs,data_rt,asid} = input_bus_reg;
assign [15:0] immediate={rd,sharmt,func};
//ALU_R
wire [31:0]alu_r_res;
wire alu_r_en = (op==6'b000000)&&
                (func==6'b100000||func==6'b100001||func==6'b100010||func==6'b100011||
                 func==6'b100100||func==6'b100101||func==6'b100110||func==6'b100111||
                 func==6'b101010||func==6'b101011||func==6'b000000||func==6'b000010||
                 func==6'b000011||func==6'b000100||func==6'b000110||func==6'b000111);

ALU_R ALU_R_inst(
    .data_rs(data_rs),
    .data_rt(data_rt),   
    .sharmt (sharmt),
    .func   (func),
    .data_rd(alu_r_res),
    .alu_exc(alu_exc)//算数溢出异常
);
//ALU_I
wire [31:0]alu_i_res;
wire alu_i_en = (op==6'b001000)||(op==6'b001001)||(op==6'b001100)||(op==6'b001101)||
                (op==6'b001110)||(op==6'b001111)||(op==6'b001010)||(op==6'b001011)||
                (op[5]==1'b1);//计算内存地址

ALU_I aLU_I_inst(
    .op       (op),
    .data_rs  (data_rs),
    .immediate(immediate),
    .data_rt  (alu_i_res)
);
wire alu_sys_pass=(op==6'b010000);
wire [31:0] exe_res=(alu_r_en)?alu_r_res:
                    (alu_i_en)?alu_i_res:
                    (alu_sys_pass)?data_rs://系统需要的参数从data_rs传输
                    32'b0;
always @(*) begin
    output_bus={op,rs,rt,rd,sharmt,func,exe_res,data_rt,asid};
end


endmodule
/*
如果阻塞，保存上一流水的内容，不发送下一流水
阻塞结束，读取上一流水内容，发送下一流水
一个周期能完成，阻塞一周期后读取上一流水，阻塞一周期发送
第二个周期能完成，直接读取上一流水，直接发送
超过了第二个周期，相当于阻塞

*/