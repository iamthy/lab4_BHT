module BHT #(
    parameter  TAG_ADDR_LEN  = 8  // tag长度
)(
    input  wire clk, rst,
    input  wire [31:0] PC_IF,   // IF段得到的PC

    input  wire is_br_EX,       // EX段的指令是否为br指令
    input  wire br_EX,          // EX阶段的br信号
    input  wire [31:0] PC_EX,   // EX阶段的PC
    output wire jmp             // BHT作出的是否跳转预测
);
localparam BHT_SIZE = 1 << TAG_ADDR_LEN; // BHT的大小

wire [TAG_ADDR_LEN-1:0] tag_addr,EX_tag_addr;
assign tag_addr = PC_IF[TAG_ADDR_LEN+1:2];    
assign EX_tag_addr = PC_EX[TAG_ADDR_LEN+1:2];
// 使用直接相联的方式，取除了最低两位以外最低的TAG_ADDR位作为tag直接到对应下标的条目中取
// BHT不再记录PC的值

reg [1:0] State [BHT_SIZE-1:0];          // 预测分支是否跳转,1x跳转,0x不跳转
assign jmp=State[tag_addr] == 2'b10 || State[tag_addr] == 2'b11;

always @(posedge clk,posedge rst)
begin
    if (rst)
    begin
        for (integer i = 0; i < BHT_SIZE ; i++)
        begin
            State[i] <= 2'b01;
        end
    end
    else
    begin
        if (is_br_EX)//EX段只有是分支指令才更新状态机
        begin
            case(State[EX_tag_addr])//更新状态机
                2'b00:State[EX_tag_addr] = br_EX ? 2'b01 : 2'b00;
                2'b01:State[EX_tag_addr] = br_EX ? 2'b11 : 2'b00;
                2'b10:State[EX_tag_addr] = br_EX ? 2'b11 : 2'b00;
                2'b11:State[EX_tag_addr] = br_EX ? 2'b11 : 2'b10;
            endcase
        end
    end
end
endmodule