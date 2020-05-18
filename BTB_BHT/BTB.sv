module BTB #(
    parameter  TAG_ADDR_LEN  = 8  // tag长度
)(
    input  wire clk, rst,
    input  wire [31:0] PC_IF,       // IF段得到的PC
    
    //这一组输入为EX段的分支跳转情况
    input  wire is_br_EX,           // EX段的指令是否为br指令
    input  wire br_EX,              // EX阶段的br信号
    input  wire [31:0] PC_EX,       // EX阶段的PC
    input  wire [31:0] br_target,   // EX段的真实跳转地址 

    //这一组输入为两个周期前对当前EX段的分支预测情况
    input  wire find_EX,            // EX段的指令是否在BTB中命中
    input  wire [31:0] NPC_Pred_EX, // EX段预测跳转的NPC
    input  wire jmp_EX,              // EX段预测是否跳转

    output wire find,                // 是否有对应的条目
    output wire [31:0] NPC_Pred,     // 预测跳转的NPC
    output wire jmp,                 // 预测是否跳转
    output wire fail                 // 当前处在EX段的分支指令是否预测失败
);
localparam UNUSED_ADDR_LEN = 32 - TAG_ADDR_LEN - 2;       // 计算未使用的地址的长度
localparam BTB_SIZE = 1 << TAG_ADDR_LEN; // BTB的大小

reg [31:0] Br_PC [BTB_SIZE-1:0];   // 分支指令的地址
reg [31:0] Pred_PC [BTB_SIZE-1:0]; // 分支预测的跳转地址
reg State [BTB_SIZE-1:0];          // 预测分支是否跳转,1跳转,0不跳转
wire BHT_jmp;                      // BHT作出的预测

wire [TAG_ADDR_LEN-1:0] tag_addr,EX_tag_addr;
assign tag_addr = PC_IF[TAG_ADDR_LEN+1:2];    
assign EX_tag_addr = PC_EX[TAG_ADDR_LEN+1:2];
// 使用直接相联的方式，取除了最低两位以外最低的TAG_ADDR位作为tag直接到对应下标的条目中取
assign find = (PC_IF == Br_PC[tag_addr]); 
//根据tag_addr找到的对应条目指令地址与当前的PC_IF相同就说明存在，否则不存在
assign jmp = find & State[tag_addr] & BHT_jmp;   // 有对应条目并且BTB&BHT均预测跳转才输出跳转信号
assign NPC_Pred = jmp ? Pred_PC[tag_addr] : PC_IF+4;   
// 给出预测跳转目标地址,预测跳转就返回预测的地址，否则返回PC+4
assign fail = (!find_EX && br_EX) || //预测失败的情况有：BTB表没有找到但是EX段跳转了
                (find_EX && 
                    (jmp_EX && !br_EX)|| //找到了，而且预测跳转但是根本不是br指令,或者是分支指令但是不跳转
                    (!jmp_EX && br_EX) //或者预测不跳转但是实际跳转了
                );

always @(posedge clk,posedge rst)
begin
    if (rst)
    begin
        for (integer i = 0; i < BTB_SIZE ; i++)
        begin
            Br_PC[i] <= 0;
            Pred_PC[i] <= 0;
            State[i] <= 0;
        end
    end
    else
    begin
        if (!find_EX) //EX段的指令当时没有在BTB中命中
        begin
            if (br_EX)// EX段的指令未在BTB中命中并且发生了跳转，此时更新BTB表项
            begin
                Br_PC[EX_tag_addr] <= PC_EX;
                Pred_PC[EX_tag_addr] <= br_target;
                State[EX_tag_addr] <= 1;
            end
            else
            begin
                Br_PC[EX_tag_addr] <= Br_PC[EX_tag_addr];
                Pred_PC[EX_tag_addr] <= Pred_PC[EX_tag_addr];
                State[EX_tag_addr] <= State[EX_tag_addr];
            end
        end
        else //EX段的指令在BTB中命中
        begin
            Br_PC[EX_tag_addr] <= Br_PC[EX_tag_addr];//BTB中的PC值不变
            if (jmp_EX)//BTB的预测是命中
            begin
                if (!is_br_EX)//但是其实根本不是分支指令
                begin
                    Pred_PC[EX_tag_addr] <= PC_EX+4;
                    State[EX_tag_addr] <= 0;
                end
                else
                begin
                    if (!br_EX)//是分支指令但是不跳转
                    begin
                        Pred_PC[EX_tag_addr] <= Pred_PC[EX_tag_addr];
                        State[EX_tag_addr] <= 0;
                    end
                    else//是分支指令且跳转，猜测正确
                    begin
                        Pred_PC[EX_tag_addr] <= Pred_PC[EX_tag_addr];
                        State[EX_tag_addr] <= 1;
                    end
                end
            end
            else//BTB的预测是不命中
            begin
                if (!is_br_EX || (is_br_EX && !br_EX))//EX段指令不是分支指令，或者是分支指令但不跳转，那么预测正确
                begin
                    Pred_PC[EX_tag_addr] <= Pred_PC[EX_tag_addr];
                    State[EX_tag_addr] <= 0;
                end
                else
                begin//否则是分支指令且跳转，预测错误，要更新BTB
                    Pred_PC[EX_tag_addr] <= br_target;
                    State[EX_tag_addr] <= 1;
                end
            end
        end
    end
end

BHT BHT1(
    .clk(clk),
    .rst(rst),
    .PC_IF(PC_IF),
    .is_br_EX(is_br_EX),
    .br_EX(br_EX),
    .PC_EX(PC_EX),
    .jmp(BHT_jmp)
);
endmodule
