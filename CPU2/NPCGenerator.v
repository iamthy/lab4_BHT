`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Huang Yifan (hyf15@mail.ustc.edu.cn)
// 
// Design Name: RV32I Core
// Module Name: NPC Generator
// Tool Versions: Vivado 2017.4.1
// Description: RV32I Next PC Generator
// 
//////////////////////////////////////////////////////////////////////////////////


//  功能说明
    //  根据跳转信号，决定执行的下一条指令地址
    //  debug端口用于simulation时批量写入数据，可以忽略
// 输入
    // PC                指令地址（PC + 4, 而非PC）
    // jal_target        jal跳转地址
    // jalr_target       jalr跳转地址
    // br_target         br跳转地址
    // NPC_Pred          预测的跳转地址
    // jal               jal == 1时，有jal跳转
    // jalr              jalr == 1时，有jalr跳转
    // br                br == 1时，有br跳转
    // fail              fail == 1时，预测失败需要重新进行跳转
// 输出
    // NPC               下一条执行的指令地址
// 实验要求  
    // 实现NPC_Generator

module NPC_Generator(
    input wire [31:0] PC_EX, jal_target, jalr_target, br_target, NPC_Pred,
    input wire jal, jalr, br, BTB_fail,
    output reg [31:0] NPC
    );
    always @(*)
    begin
        if (br&BTB_fail)//跳转但是预测不跳转
        begin
            NPC <= br_target;
        end
        else if (BTB_fail)//不跳转但是预测跳转
        begin
            NPC <= PC_EX+4;
        end
        else if (jalr)
        begin
            NPC <= jalr_target;
        end
        else if (jal)
        begin
            NPC <= jal_target;
        end
        else
        begin
            NPC <= NPC_Pred;
        end
    end
    // TODO: Complete this module

endmodule