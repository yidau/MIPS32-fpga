`timescale 1ns / 1ps

module CPU_TOP#(
    parameter CACHE_NUM     = 64                ,
    parameter ASID_WIDTH    = 8                 ,
    parameter INDEX_WIDTH   = $clog2(CACHE_NUM) 
)(
    input wire clk,
    input wire reset,
    inout wire[7:0] gpio_pins
);
reg [31:0]pc;
wire [39:0] if_id_bus;
wire [103:0] id_exe_bus;
wire [103:0] exe_mem_bus;
wire [71:0] mem_wb_bus;
wire [31:0] gpio_addr;
wire [31:0] gpio_wdata;
wire        gpio_wen;
wire        gpio_ren;  
wire [31:0] gpio_rdata;
wire                     tlb_valid_if    ;
wire [31:0]              vaddr_if        ;
wire [ASID_WIDTH-1:0]    asid_if         ;
wire [31:0]              paddr_if        ;
wire                     hit_if          ;
wire                     miss_if         ;
wire                     tlb_invalid_if  ;
wire                     tlb_valid_mem   ;
wire [31:0]              vaddr_mem       ;
wire [ASID_WIDTH-1:0]    asid_mem        ;
wire [31:0]              paddr_mem       ;
wire                     hit_mem         ;
wire                     miss_mem        ;
wire                     tlb_invalid_mem ;
wire [2:0]               tlb_inst_en     ;
wire [31:0]              input_entryhi   ;
wire [31:0]              input_entrylo0  ;
wire [31:0]              input_entrylo1  ;
wire [31:0]              input_pagemask  ;
wire [INDEX_WIDTH-1:0]   input_index     ;
wire [31:0]              output_entryhi  ;
wire [31:0]              output_entrylo0 ;
wire [31:0]              output_entrylo1 ;
wire [31:0]              output_pagemask ;
wire [INDEX_WIDTH-1:0]   output_index    ;
wire                     output_is_probed;
wire [4:0]   reg_ra1;
wire [4:0]   reg_ra2;
wire [31:0]  reg_rd1;
wire [31:0]  reg_rd2;
wire         reg_we ;
wire [4:0]   reg_wa ;
wire [31:0]  reg_wd ;

wire [4:0]               CP0_raddr       ;
wire [31:0]              CP0_rdata       ;
wire                     CP0_wen         ;
wire [4:0]               CP0_waddr       ;
wire [31:0]              CP0_wdata       ;
wire                     tlbr_en         ;
wire                     tlbp_en         ;

GPIO GPIO_inst(
.clk        (clk),
.rst        (reset),
.gpio_addr  (gpio_addr ),     // MMIO 地址
.gpio_wdata (gpio_wdata),    // 写数据
.gpio_wen   (gpio_wen  ),      // 写使能
.gpio_ren   (gpio_ren  ),      // 读使能
.gpio_rdata (gpio_rdata),    // 读数据
.gpio_pins  (gpio_pins)// 8 个 GPIO 引脚
);


IF#(
.KSEG0     (3'b100)            ,
.KSEG1     (3'b101)            ,
.ASID_WIDTH(8     )            ,
.IN_WIDTH  (32    )            ,
.OUT_WIDTH (40)
)IF_inst(
.clk             (clk),
.reset           (reset),
.input_bus       (pc),//IF段为PC
.output_bus      (if_id_bus),//IF段为指令
.stall           (1'b0),//系统的阻塞信号
.flush           (1'b0),//由于分支预测被清除的信号.
.tlb_valid_if    (tlb_valid_if  ),//if段需要tlb转换时拉高
.vaddr_if        (vaddr_if      ),//if段虚拟地址
.asid_if         (asid_if       ),//if段进程地址
.paddr_if        (paddr_if      ),//if段物理地址输出
.hit_if          (hit_if        ),//if段命中时拉高
.miss_if         (miss_if       ),//if段未命中时拉高
.tlb_invalid_if  (tlb_invalid_if),//if段触发tlb_invalid
.cache_valid     (),
.offset          (),
.cache_ack       (),
.tag             (),
.data            (),
.bios_en         (),//bram实现bios
.bios_addr       (),
.bios_data       (),
.asid            ()
);

ID#(
.KSEG0     (3'b100)            ,
.KSEG1     (3'b101)            ,
.ASID_WIDTH(8     )            ,
.IN_WIDTH  (40    )            ,
.OUT_WIDTH (104)
)ID_inst(
.clk         (clk),
.reset       (reset),
.input_bus   (if_id_bus),//
.output_bus  (id_exe_bus),//
.stall       (1'b0),//系统的阻塞信号
.flush       (1'b0),//由于分支预测被清除的信号
.reg_ra1     (reg_ra1),//读地址1
.reg_ra2     (reg_ra2),//读地址2
.reg_rd1     (reg_rd1),//读数据1
.reg_rd2     (reg_rd2 ),//读数据2   
.br_en       (),
.CP0_raddr       (CP0_raddr ),//读地址
.CP0_rdata       (CP0_rdata ) //读数据
);

EXE#(
.KSEG0     (3'b100)            ,
.KSEG1     (3'b101)            ,
.ASID_WIDTH(8     )            ,
.IN_WIDTH  (104   )            ,
.OUT_WIDTH (104)
)EXE_inst(
.clk        (clk),
.reset      (reset),
.input_bus  (id_exe_bus),//IF段为PC
.output_bus (exe_mem_bus),//IF段为指令
.stall      (1'b0),//系统的阻塞信号
.flush      (1'b0),//由于分支预测被清除的信号
.alu_exc    ()
);

MEM#(
.KSEG0     (3'b100)            ,
.KSEG1     (3'b101)            ,
.ASID_WIDTH(8     )            ,
.IN_WIDTH  (104   )            ,
.OUT_WIDTH (72)
)MEM_inst(
.clk             (clk),
.reset           (reset),
.input_bus       (exe_mem_bus),//IF段为PC
.output_bus      (mem_wb_bus),//IF段为指令
.stall           (1'b0),//系统的阻塞信号
.flush           (1'b0),//由于分支预测被清除的信号
.tlb_valid_mem   (tlb_valid_mem  ),//mem段需要tlb转换时拉高
.vaddr_mem       (vaddr_mem      ),//mem段虚拟地址
.asid_mem        (asid_mem       ),//mem段进程地址
.paddr_mem       (paddr_mem      ),//mem段物理地址输出
.hit_mem         (hit_mem        ),//mem段命中时拉高
.miss_mem        (miss_mem       ),//mem段未命中时拉高
.tlb_invalid_mem (tlb_invalid_mem),//mem段触发tlb_invalid
.cache_valid     (),
.offset          (),
.cache_ack       (),
.tag             (),
.data            (),
.gpio_addr       (gpio_addr ),     // MMIO 地址
.gpio_wdata      (gpio_wdata),    // 写数据
.gpio_wen        (gpio_wen  ),      // 写使能
.gpio_ren        (gpio_ren  )    // 读使能
);

WB#(
.KSEG0     (3'b100)            ,
.KSEG1     (3'b101)            ,
.ASID_WIDTH(8     )            ,
.IN_WIDTH  (72)
)WB_inst(
.clk         (clk),
.reset       (reset),
.input_bus   (mem_wb_bus),//IF段为PC
.stall       (1'b0),//系统的阻塞信号
.flush       (1'b0),//由于分支预测被清除的信号
.reg_we      (reg_we),//写使能
.reg_wa      (reg_wa),//写地址
.reg_wd      (reg_wd),//写数据  
.wen         (CP0_wen   ),//写使能
.waddr       (CP0_waddr ),//写地址
.wdata       (CP0_wdata )    //写数据 
);
TLB#(
.KSEG0       (3'b100           ) ,
.KSEG1       (3'b101           ) ,
.CACHE_NUM   (64               ) ,
.VPN_WIDTH   (19               ) ,
.ASID_WIDTH  (8                ) ,
.OFFSET_FORCE(32'h00000FFF  )
)TLB_inst(
.clk             (clk),
.reset           (reset),
.tlb_valid_if    (tlb_valid_if    ),//if段需要tlb转换时拉高
.vaddr_if        (vaddr_if        ),//if段虚拟地址
.asid_if         (asid_if         ),//if段进程地址
.paddr_if        (paddr_if        ),//if段物理地址输出
.hit_if          (hit_if          ),//if段命中时拉高
.miss_if         (miss_if         ),//if段未命中时拉高
.tlb_invalid_if  (tlb_invalid_if  ),//if段触发tlb_invalid
.tlb_valid_mem   (tlb_valid_mem   ),//mem段需要tlb转换时拉高
.vaddr_mem       (vaddr_mem       ),//mem段虚拟地址
.asid_mem        (asid_mem        ),//mem段进程地址
.paddr_mem       (paddr_mem       ),//mem段物理地址输出
.hit_mem         (hit_mem         ),//mem段命中时拉高
.miss_mem        (miss_mem        ),//mem段未命中时拉高
.tlb_invalid_mem (tlb_invalid_mem ),//mem段触发tlb_invalid
.tlb_inst_en     (tlb_inst_en     ),//100:tlbwr 101:tlbwi 110:tlbr 111:tlbp
.input_entryhi   (input_entryhi   ),//CP0寄存器输入
.input_entrylo0  (input_entrylo0  ),//CP0寄存器输入
.input_entrylo1  (input_entrylo1  ),//CP0寄存器输入
.input_pagemask  (input_pagemask  ),//CP0寄存器输入
.input_index     (input_index     ),//CP0寄存器输入
.output_entryhi  (output_entryhi  ),//CP0寄存器输出
.output_entrylo0 (output_entrylo0 ),//CP0寄存器输出
.output_entrylo1 (output_entrylo1 ),//CP0寄存器输出
.output_pagemask (output_pagemask ),//CP0寄存器输出
.output_index    (output_index    ),//CP0寄存器输出
.output_is_probed(output_is_probed) //probe成功信号
);

REG_FILE REG_FILE_inst(
.clk     (clk),
.reset   (reset),    
.reg_ra1 (reg_ra1),//读地址1
.reg_ra2 (reg_ra2),//读地址2
.reg_rd1 (reg_rd1),//读数据1
.reg_rd2 (reg_rd2),//读数据2  
.reg_we  (reg_we ),//写使能
.reg_wa  (reg_wa ),//写地址
.reg_wd  (reg_wd )//写数据  
);

CP0 CP0_inst(
.clk             (clk),
.reset           (reset),   
.CP0_raddr       (CP0_raddr),//读地址
.CP0_rdata       (CP0_rdata),//读数据
.CP0_wen         (CP0_wen  ),//写使能
.CP0_waddr       (CP0_waddr),//写地址
.CP0_wdata       (CP0_wdata),//写数据  
.tlbr_en         (tlbr_en         ),//tlbr指令使能
.tlbp_en         (tlbp_en         ),//tlbp指令使能
.input_entryhi   (input_entryhi   ),//CP0寄存器输入 
.input_entrylo0  (input_entrylo0  ),//CP0寄存器输入 
.input_entrylo1  (input_entrylo1  ),//CP0寄存器输入 
.input_pagemask  (input_pagemask  ),//CP0寄存器输入 
.input_index     (input_index     ),//CP0寄存器输入     
.output_entryhi  (output_entryhi  ),//CP0寄存器输出 
.output_entrylo0 (output_entrylo0 ),//CP0寄存器输出 
.output_entrylo1 (output_entrylo1 ),//CP0寄存器输出 
.output_pagemask (output_pagemask ),//CP0寄存器输出 
.output_index    (output_index    ) //CP0寄存器输出    
);
always @(posedge clk or posedge reset) begin
    if(reset)
        pc<=32'ha0000000;
    else    
        pc<=pc+4;
end
endmodule