`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Huang Yifan (hyf15@mail.ustc.edu.cn)
// 
// Design Name: RV32I Core
// Module Name: Hazard Module
// Tool Versions: Vivado 2017.4.1
// Description: Hazard Module is used to control flush, bubble and bypass
// 
//////////////////////////////////////////////////////////////////////////////////

//  功能说明
    //  识别流水线中的数据冲突，控制数据转发，和flush、bubble信号
// 输入
    // rst               CPU的rst信号
    // reg1_srcD         ID阶段的源reg1地址
    // reg2_srcD         ID阶段的源reg2地址
    // reg1_srcE         EX阶段的源reg1地址
    // reg2_srcE         EX阶段的源reg2地址
    // reg_dstE          EX阶段的目的reg地址
    // reg_dstM          MEM阶段的目的reg地址
    // reg_dstW          WB阶段的目的reg地址
    // br                是否branch
    // jalr              是否jalr
    // jal               是否jal
    // src_reg_en        指令中的源reg1和源reg2地址是否有效
    // wb_select         写回寄存器的值的来源（Cache内容或者ALU计算结果）
    // reg_write_en_MEM  MEM阶段的寄存器写使能信号
    // reg_write_en_WB   WB阶段的寄存器写使能信号
    // alu_src1          ALU操作数1来源：0表示来自reg1，1表示来自PC
    // alu_src2          ALU操作数2来源：2’b00表示来自reg2，2'b01表示来自reg2地址，2'b10表示来自立即数
// 输出
    // flushF            IF阶段的flush信号
    // bubbleF           IF阶段的bubble信号
    // flushD            ID阶段的flush信号
    // bubbleD           ID阶段的bubble信号
    // flushE            EX阶段的flush信号
    // bubbleE           EX阶段的bubble信号
    // flushM            MEM阶段的flush信号
    // bubbleM           MEM阶段的bubble信号
    // flushW            WB阶段的flush信号
    // bubbleW           WB阶段的bubble信号
    // op1_sel           ALU的操作数1来源：2'b00表示来自ALU转发数据，2'b01表示来自write back data转发，2'b10表示来自PC，2'b11表示来自reg1
    // op2_sel           ALU的操作数2来源：2'b00表示来自ALU转发数据，2'b01表示来自write back data转发，2'b10表示来自reg2地址，2'b11表示来自reg2或立即数
    // reg2_sel          reg2的来源
// 实验要求
    // 补全模块


module HarzardUnit(
    input wire clk,rst, miss,
    input wire [4:0] reg1_srcD, reg2_srcD, reg1_srcE, reg2_srcE, reg_dstE, reg_dstM, reg_dstW,
    input wire br, jalr, jal, is_br_EX,
    input wire [1:0] src_reg_en,
    input wire wb_select,
    input wire reg_write_en_MEM,
    input wire reg_write_en_WB,
    input wire alu_src1,
    input wire [1:0] alu_src2,
    input wire BTB_fail,
    output reg flushF, bubbleF, flushD, bubbleD, flushE, bubbleE, flushM, bubbleM, flushW, bubbleW,
    output reg [1:0] op1_sel, op2_sel, reg2_sel
    );
    reg [31:0] br_cnt; //分支指令执行次数
    reg [31:0] fail_cnt; //预测错误次数
    wire [31:0] suc_cnt; //预测成功次数
    assign suc_cnt = br_cnt - fail_cnt;
    always @(posedge clk,posedge rst)
    begin
        if (rst)
        begin
            br_cnt <= 0;
            fail_cnt <= 0;
        end
        else
        begin
            if (is_br_EX) br_cnt<=br_cnt+1;
            if (BTB_fail) fail_cnt<=fail_cnt+1;
        end
    end
    // TODO: Complete this module
    always @(*)
    begin
        //处理lw和后面一条指令的数据相关，此时必须插入一个气泡并转发；
        //wb_select只有lw类指令信号才为1
        if (miss)//如果cache未命中，流水线暂停
        begin
            bubbleF <= 1;
            bubbleD <= 1;
            bubbleE <= 1;
            bubbleM <= 1;
            bubbleW <= 1;
        end
        else if (wb_select && (reg1_srcD == reg_dstE || reg2_srcD == reg_dstE))
        begin
            bubbleF <= 1;
            bubbleD <= 1;
            bubbleE <= 0;
            bubbleM <= 0;
            bubbleW <= 0;
        end
        else
        begin
            bubbleF <= 0;
            bubbleD <= 0;
            bubbleE <= 0;
            bubbleM <= 0;
            bubbleW <= 0;
        end
    end
    //----------------------flush-------------------
    always @(*)
    begin
        if (rst)
        begin
            flushF <= 1;
            flushD <= 1;
            flushE <= 1;
            flushM <= 1;
            flushW <= 1;
        end
        else if ((BTB_fail) | jalr)
        begin
            flushF <= 0;
            flushD <= 1;
            flushE <= 1;
            flushM <= 0;
            flushW <= 0;
        end
        else if (jal)
        begin
            flushF <= 0;
            flushD <= 1;
            flushE <= 0;
            flushM <= 0;
            flushW <= 0;
        end
        else if (wb_select && (reg1_srcD == reg_dstE || reg2_srcD == reg_dstE))
        begin
            flushF <= 0;
            flushD <= 0;
            flushE <= 1;
            flushM <= 0;
            flushW <= 0;
        end
        else
        begin
            flushF <= 0;
            flushD <= 0;
            flushE <= 0;
            flushM <= 0;
            flushW <= 0;
        end
    end

    //--------------forward------------------
    always @(*)
    begin
        //转发MEM到EX更优先，因为MEM级结果相比WB级更新
        //转发必须满足1.前一条指令目的寄存器与后一条指令源寄存器相同
        //           2.前一条指令写了目的寄存器
        //           3.后一条指令使用了源寄存器的值
        //           4.不是0寄存器
        //操作数1的转发处理
        if (alu_src1 == 2'b00 && reg1_srcE == reg_dstM && reg_write_en_MEM &&
                src_reg_en[1] && reg1_srcE != 5'b0)
            op1_sel <= 2'b00;//MEM to EX
        else if (alu_src1 == 2'b00 && reg1_srcE == reg_dstW && reg_write_en_WB &&
                    src_reg_en[1] && reg1_srcE != 5'b0)
            op1_sel <= 2'b01;//WB to EX
        else if (alu_src1)//来自PC
            op1_sel <= 2'b10;
        else 
            op1_sel <= 2'b11;

        //操作数2的转发处理
        if (alu_src2 == 2'b00 && reg2_srcE == reg_dstM && reg_write_en_MEM &&
                src_reg_en[0] && reg2_srcE != 5'b0)
            op2_sel <= 2'b00;//MEM to EX
        else if (alu_src2 == 2'b00 && reg2_srcE == reg_dstW && reg_write_en_WB &&
                    src_reg_en[0] && reg2_srcE != 5'b0)
            op2_sel <= 2'b01;//WB to EX
        else if (alu_src2 == 2'b01)//来自reg2地址（rs2直接当立即数用，仅用于SLLI、SRLI、SRAI）
            op2_sel <= 2'b10;
        else 
            op2_sel <= 2'b11;

        if (reg2_srcE == reg_dstM && reg_write_en_MEM &&
                src_reg_en[0] && reg2_srcE != 5'b0)
            reg2_sel <= 2'b00;//MEM to EX
        else if (reg2_srcE == reg_dstW && reg_write_en_WB &&
                    src_reg_en[0] && reg2_srcE != 5'b0)
            reg2_sel <= 2'b01;//WB to EX
        else reg2_sel <= 2'b10;
    end
endmodule
