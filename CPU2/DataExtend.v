`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Huang Yifan (hyf15@mail.ustc.edu.cn)
// 
// Design Name: RV32I Core
// Module Name: Data Extend
// Tool Versions: Vivado 2017.4.1
// Description: Data Extension module
// 
//////////////////////////////////////////////////////////////////////////////////

//  功能说明
    //  将Cache中Load的数据扩展成32位
// 输入
    // data              cache读出的数据
    // addr              字节地址
    // load_type         load的类型
    // ALU_func          运算类型
// 输出
    // dealt_data        扩展完的数据
// 实验要求
    // 补全模块


`include "Parameters.v"

module DataExtend(
    input wire [31:0] data,
    input wire [1:0] addr,
    input wire [2:0] load_type,
    output reg [31:0] dealt_data
    );
    always @(data,addr,load_type)
    begin
        case (load_type)
            //取有符号数并扩展
            `LB:
            begin
                case (addr)//根据取的数的位置取对应的8位有符号扩展到32位
                    2'b00: dealt_data <= {{25{data[7]}}, data[6:0]};
                    2'b01: dealt_data <= {{25{data[15]}}, data[14:8]};
                    2'b10: dealt_data <= {{25{data[23]}}, data[22:16]};
                    2'b11: dealt_data <= {{25{data[31]}}, data[30:24]};
                endcase
            end
            `LH:
            begin
                case (addr)
                    2'b00: dealt_data <= {{25{data[15]}}, data[14:0]};
                    2'b10: dealt_data <= {{25{data[31]}}, data[30:16]};
                    default: dealt_data <= 32'b0;//不处理非对齐访问，一律返回0
                endcase
            end
            `LW:
            begin
                dealt_data <= (addr == 2'b00 ? data : 31'b0);
            end
            //取无符号数并扩展
            `LBU:
            begin
                case (addr)
                    2'b00: dealt_data <= {{24'b0}, data[7:0]};
                    2'b01: dealt_data <= {{24'b0}, data[15:8]};
                    2'b10: dealt_data <= {{24'b0}, data[23:16]};
                    2'b11: dealt_data <= {{24'b0}, data[31:24]};
                endcase
            end
            `LHU:
            begin
                case (addr)
                    2'b00: dealt_data <= {{16'b0}, data[15:0]};
                    2'b10: dealt_data <= {{16'b0}, data[31:16]};
                    default: dealt_data <= 32'b0;
                endcase
            end
            default dealt_data <= 32'b0;//未定义的load指令格式
        endcase
    end
    // TODO: Complete this module

endmodule