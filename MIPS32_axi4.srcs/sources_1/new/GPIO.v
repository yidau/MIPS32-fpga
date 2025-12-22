`timescale 1ns / 1ps
module GPIO (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] gpio_addr,     // MMIO 地址
    input  wire [31:0] gpio_wdata,    // 写数据
    input  wire        gpio_wen,      // 写使能
    input  wire        gpio_ren,      // 读使能
    output reg  [31:0] gpio_rdata,    // 读数据
    inout  wire [7:0]  gpio_pins // 8 个 GPIO 引脚
);
reg [7:0] dir_reg;   // 方向寄存器
reg [7:0] out_reg;   // 输出寄存器
// GPIO 引脚驱动
genvar i;
generate
    for (i=0; i<8; i=i+1) begin : gpio_loop
        assign gpio_pins[i] = dir_reg[i] ? out_reg[i] : 1'bz;
    end
endgenerate
// 读写逻辑
always @(posedge clk or posedge rst) begin
    if (rst) begin
        dir_reg <= 8'b0;
        out_reg <= 8'b0;
    end else if (gpio_wen) begin
        case (gpio_addr[3:0])
            4'h0: dir_reg <= gpio_wdata[7:0];   // 写方向
            4'h4: out_reg <= gpio_wdata[7:0];   // 写输出
        endcase
    end
end
always @(*) begin
    case (gpio_addr[3:0])
        4'h0: gpio_rdata = {24'b0, dir_reg};
        4'h4: gpio_rdata = {24'b0, out_reg};
        4'h8: gpio_rdata = {24'b0, gpio_pins}; // 读输入
        default: gpio_rdata = 32'b0;
    endcase
end

endmodule