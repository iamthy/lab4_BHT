`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB
// Engineer: Huang Yifan (hyf15@mail.ustc.edu.cn)
// 
// Design Name: RV32I Core
// Module Name: Write-back Data seg reg
// Tool Versions: Vivado 2017.4.1
// Description: Write-back data seg reg for MEM\WB
// 
//////////////////////////////////////////////////////////////////////////////////


//  功能说明
    // MEM\WB的写回寄存器内容
    // 为了数据同步，Data Extension和Data Cache集成在其中
// 输入
    // clk               时钟信号
    // wb_select         选择写回寄存器的数据：如果为0，写回ALU计算结果，如果为1，写回Memory读取的内容
    // load_type         load指令类型
    // write_en          Data Cache写使能
    // debug_write_en    Data Cache debug写使能
    // addr              Data Cache的写地址，也是ALU的计算结果
    // debug_addr        Data Cache的debug写地址
    // in_data           Data Cache的写入数据
    // debug_in_data     Data Cache的debug写入数据
    // bubbleW           WB阶段的bubble信号
    // flushW            WB阶段的flush信号
// 输出
    // debug_out_data    Data Cache的debug读出数据
    // data_WB           传给下一流水段的写回寄存器内容
// 实验要求  
    // 无需修改

module WB_Data_WB(
    input wire clk, rst, bubbleW, flushW,
    input wire wb_select,
    input wire [2:0] load_type,
    input  [3:0] write_en, debug_write_en,
    input  [31:0] addr,
    input  [31:0] debug_addr,
    input  [31:0] in_data, debug_in_data,
    input wire rd_req,
    output wire [31:0] debug_out_data,
    output wire [31:0] data_WB,
    output wire miss
    );

    wire [31:0] data_raw;
    wire [31:0] data_WB_raw;



    cache DataCache1(
        .clk(clk),
        .rst(rst),
        .miss(miss),
        .addr(addr),
        .rd_req(rd_req),
        .rd_data(data_raw),
        .wr_req(|write_en),
        .wr_data(in_data)
    );

    reg [31:0] miss_count,hit_count;//未命中/命中计数
    reg [31:0] last_addr;//上次访问的地址，用来确定是否是一次新的cache访问
    wire cache_rw= (|write_en) | rd_req;//是否访问cache

    always @(posedge clk,posedge rst)
    begin
        if (rst)
        begin
            last_addr <= 0;
        end
        else if (cache_rw)
            last_addr <= addr;
    end

    always @(posedge clk,posedge rst)
    begin
        if (rst)
        begin
            miss_count <= 0;
            hit_count <= 0;
        end
        else
        begin
            if (cache_rw & (addr !=last_addr))//是一次新的cache访问
            begin
                if (miss)//根据是否命中计数
                    miss_count <= miss_count+1;
                else hit_count <= hit_count+1;
            end
        end
    end




    // Add flush and bubble support
    // if chip not enabled, output output last read result
    // else if chip clear, output 0
    // else output values from cache

    reg bubble_ff = 1'b0;
    reg flush_ff = 1'b0;
    reg wb_select_old = 0;
    reg [31:0] data_WB_old = 32'b0;
    reg [31:0] addr_old;
    reg [2:0] load_type_old;

    DataExtend DataExtend1(
        .data(data_raw),
        .addr(addr_old[1:0]),
        .load_type(load_type_old),
        .dealt_data(data_WB_raw)
    );

    always@(posedge clk)
    begin
        bubble_ff <= bubbleW;
        flush_ff <= flushW;
        data_WB_old <= data_WB;
        addr_old <= addr;
        wb_select_old <= wb_select;
        load_type_old <= load_type;
    end

    assign data_WB = bubble_ff ? data_WB_old :
                                 (flush_ff ? 32'b0 : 
                                             (wb_select_old ? data_WB_raw :
                                                          addr_old));






    
endmodule