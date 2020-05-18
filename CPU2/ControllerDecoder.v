`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Huang Yifan (hyf15@mail.ustc.edu.cn)
// 
// Design Name: RV32I Core
// Module Name: Controller Decoder
// Tool Versions: Vivado 2017.4.1
// Description: Controller Decoder Module
// 
//////////////////////////////////////////////////////////////////////////////////

//  功能说明
    //  对指令进行译码，将其翻译成控制信号，传输给各个部件
// 输入
    // Inst              待译码指令
// 输出
    // jal               jal跳转指令
    // jalr              jalr跳转指令
    // op2_src           ALU的第二个操作数来源。为1时，op2选择imm，为0时，op2选择reg2
    // ALU_func          ALU执行的运算类型
    // br_type           branch的判断条件，可以是不进行branch
    // load_npc          写回寄存器的值的来源（PC或者ALU计算结果）, load_npc == 1时选择PC
    // wb_select         写回寄存器的值的来源（Cache内容或者ALU计算结果），wb_select == 1时选择cache内容
    // load_type         load类型
    // src_reg_en        指令中src reg的地址是否有效，src_reg_en[1] == 1表示reg1被使用到了，src_reg_en[0]==1表示reg2被使用到了
    // reg_write_en      通用寄存器写使能，reg_write_en == 1表示需要写回reg
    // cache_write_en    按字节写入data cache
    // imm_type          指令中立即数类型
    // alu_src1          alu操作数1来源，alu_src1 == 0表示来自reg1，alu_src1 == 1表示来自PC
    // alu_src2          alu操作数2来源，alu_src2 == 2’b00表示来自reg2，alu_src2 == 2'b01表示来自reg2地址，alu_src2 == 2'b10表示来自立即数
    // cache_rd          读cache信号，用于LW类指令
// 实验要求
    // 补全模块


`include "Parameters.v"   
module ControllerDecoder(
    input wire [31:0] inst,
    output wire jal,//
    output wire jalr,//
    output wire op2_src,//
    output reg [3:0] ALU_func,///
    output reg [2:0] br_type,///
    output wire load_npc,//
    output wire wb_select,//
    output reg [2:0] load_type,//
    output reg [1:0] src_reg_en,//
    output reg reg_write_en,//
    output reg [3:0] cache_write_en,///
    output wire alu_src1,//
    output wire [1:0] alu_src2,
    output reg [2:0] imm_type,///
    output wire cache_rd
    );
    wire [6:0] func7 = inst[31:25];
    wire [3:0] func3 = inst[14:12];
    wire [6:0] Op = inst[6:0];
    // TODO: Complete this module
    assign jal = (Op == 7'b1101111);
    assign jalr = (Op == 7'b1100111);
    assign load_npc = (Op == 7'b1100111 || Op == 7'b1101111);
    //jal and jalr
    assign alu_src1 = (Op == 7'b0010111);
    //只有auipc指令从pc取第一个操作数，其他op1都来自寄存器
    assign alu_src2 = (Op == 7'b0110011 || Op == 7'b1100011) ? 2'b00 :
                        //ADD类(R类)和B类指令第二个运算数来自寄存器
                      (Op == 7'b0010011 && (func3 == 3'b001 || func3 == 3'b101)) ? 2'b01 :
                        //SLLI、SRLI、SRAI指令第二个操作数是rs2字段的立即数
                      2'b10;//其他的都来自立即数
    assign wb_select = (Op == 7'b0000011);
    //只有在执行lw类指令时才从cache中取数据写回reg，否则均为ALU的结果
    assign op2_src = (Op != 7'b0110011);
    //ALUop2来自立即数的指令有ADDI类、LUI、AUIPC、JALR、JAL、LW类、SW类、B类
    //只有R类不用立即数(add\sub等)
    always @(Op)
    begin
        reg_write_en <= (Op != 7'b0100011 && Op != 7'b1100011);
    end//只有Stype(SW\SH\SB)和Btype(BEQ等)不写寄存器
    assign cache_rd = (Op == 7'b0000011);//只有LW类指令要读cache
    always @(*)
    begin
        case (Op)
            //----------------------ALU指令----------------------
            7'b0110011://RTYPE，如ADD、SUB等
            begin
                //不便直接写出的控制信号都按指令讨论生成
                imm_type <= `RTYPE;//包括立即数类型
                br_type <= `NOBRANCH;//分支类型
                cache_write_en <= 4'b0000;//data cache写控制
                src_reg_en <= 2'b11;//rs1、rs2两个寄存器使用与否，用于转发判断
                load_type <= `LW;//取数据类型32、16、8bits
                case (func3)
                    3'b000://ADD&SUB
                    begin
                        ALU_func <= (func7 == 7'b0000000 ? `ADD : `SUB);
                    end
                    3'b001://SLL
                    begin
                        ALU_func <= `SLL;
                    end
                    3'b010://SLT
                    begin
                        ALU_func <= `SLT;
                    end
                    3'b011://SLTU
                    begin
                        ALU_func <= `SLTU;
                    end
                    3'b100://XOR
                    begin
                        ALU_func <= `XOR;
                    end
                    3'b101://SRL&SRA
                    begin
                        ALU_func <= (func7 == 7'b0000000 ? `SRL : `SRA);
                    end
                    3'b110://OR
                    begin
                        ALU_func <= `OR;
                    end
                    3'b111://AND
                    begin
                        ALU_func <= `AND;
                    end
                endcase
            end
            7'b0010011://ITYPE,如ADDI、SLTI等
            begin
                imm_type <= `ITYPE;
                br_type <= `NOBRANCH;
                cache_write_en <= 4'b0000;
                src_reg_en <= 2'b10;//只用到第一个寄存器的值，第二个来自立即数
                load_type <= `LW;
                case (func3)
                    3'b000://ADDI
                    begin
                        ALU_func <= `ADD;
                    end
                    3'b001://SLLI
                    begin
                        ALU_func <= `SLL;
                    end
                    3'b010://SLTI
                    begin
                        ALU_func <= `SLT;
                    end
                    3'b011://SLTIU
                    begin
                        ALU_func <= `SLTU;
                    end
                    3'b100://XORI
                    begin
                        ALU_func <= `XOR;
                    end
                    3'b101://SRLI & SRAI
                    begin
                        ALU_func <= (func7 == 7'b0000000 ? `SRL : `SRA);
                    end
                    3'b110://ORI
                    begin
                        ALU_func <= `OR;
                    end
                    3'b111://ANDI
                    begin
                        ALU_func <= `AND;
                    end
                endcase
            end
            7'b0110111://LUI
            begin
                imm_type <= `UTYPE;
                br_type <= `NOBRANCH;
                cache_write_en <= 4'b0000;
                src_reg_en <= 2'b00;//rs1&rs2寄存器值均不使用
                load_type <= `LW;
                ALU_func <= `LUI;
            end
            7'b0010111://AUIPC
            begin
                imm_type <= `UTYPE;
                br_type <= `NOBRANCH;
                cache_write_en <= 4'b0000;
                src_reg_en <= 2'b00;//rs1&rs2寄存器值均不使用
                load_type <= `LW;
                ALU_func <= `ADD;
            end
            //------------------分支跳转指令-------------------
            //------------------无条件跳转---------------------
            7'b1101111://JAL
            begin
                imm_type <= `JTYPE;
                br_type <= `NOBRANCH;
                cache_write_en <= 4'b0000;
                src_reg_en <= 2'b00;//rs1&rs2寄存器值均不使用
                load_type <= `LW;
                ALU_func <= `ADD;
            end
            7'b1100111://JALR
            begin
                imm_type <= `ITYPE;
                br_type <= `NOBRANCH;
                cache_write_en <= 4'b0000;
                src_reg_en <= 2'b10;//rs2寄存器值不使用
                load_type <= `LW;
                ALU_func <= `ADD;
            end
            //-------------------条件跳转----------------------
            7'b1100011:
            begin
                imm_type <= `BTYPE;
                cache_write_en <= 4'b0000;//不写cache
                src_reg_en <= 2'b11;//rs1,rs2寄存器值均使用
                load_type <= `NOREGWRITE;//不写回寄存器
                ALU_func <= `ADD;//PC+立即数得到跳转地址
                case (func3)
                    3'b000://BEQ
                    begin
                        br_type <= `BEQ;
                    end
                    3'b001://BNE
                    begin
                        br_type <= `BNE;
                    end
                    3'b100://BLT
                    begin
                        br_type <= `BLT;
                    end
                    3'b101://BGE
                    begin
                        br_type <= `BGE;
                    end
                    3'b110://BLTU
                    begin
                        br_type <= `BLTU;
                    end
                    3'b111://BGEU
                    begin
                        br_type <= `BGEU;
                    end
                    default:
                    begin
                        br_type <= `NOBRANCH;
                    end
                endcase
            end
            //----------------LOAD指令-------------------
            7'b0000011:
            begin
                imm_type <= `ITYPE;
                br_type <= `NOBRANCH;
                cache_write_en <= 4'b0000;
                src_reg_en <= 2'b10;//只使用rs1寄存器
                ALU_func <= `ADD;
                case (func3)
                    3'b000://LB
                    begin
                        load_type <= `LB;
                    end
                    3'b001://LH
                    begin
                        load_type <= `LH;
                    end
                    3'b010://LW
                    begin
                        load_type <= `LW;
                    end
                    3'b100://LBU
                    begin
                        load_type <= `LBU;
                    end
                    3'b101://LHU
                    begin
                        load_type <= `LHU;
                    end
                    default:
                    begin
                        load_type <= `NOREGWRITE;
                    end
                endcase
            end
            //------------STORE指令----------------
            7'b0100011:
            begin
                imm_type <= `STYPE;
                br_type <= `NOBRANCH;
                src_reg_en <= 2'b11;
                load_type <= `NOREGWRITE;
                ALU_func <= `ADD;
                case (func3)
                    3'b000://SB
                    begin
                        cache_write_en <= 4'b0001;
                    end
                    3'b001://SH
                    begin
                        cache_write_en <= 4'b0011;
                    end
                    3'b010://SW
                    begin
                        cache_write_en <= 4'b1111;
                    end
                    default:
                    begin
                        cache_write_en <= 4'b0000;
                    end
                endcase
            end
            default:
            begin
                imm_type <= 0;
                br_type <= `NOBRANCH;
                cache_write_en <= 4'b0000;
                src_reg_en <= 2'b00;
                load_type <= `NOREGWRITE;
                ALU_func <= `ADD;
            end
        endcase
    end
endmodule
