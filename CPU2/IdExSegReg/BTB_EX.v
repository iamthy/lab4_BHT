module BTB_EX(
    input wire clk, bubbleE, flushE,
    input wire BTB_jmp_ID,
    input wire [31:0] BTB_NPC_Pred_ID,
    input wire BTB_find_ID,
    output reg BTB_jmp_EX,
    output reg [31:0] BTB_NPC_Pred_EX,
    output reg BTB_find_EX
    );

    initial 
    begin
        BTB_jmp_EX = 0;
        BTB_NPC_Pred_EX = 0;
        BTB_find_EX = 0;
    end
    
    always@(posedge clk)
        if (!bubbleE) 
        begin
            if (flushE)
            begin
                BTB_jmp_EX <= 0;
                BTB_NPC_Pred_EX <= 0;
                BTB_find_EX <= 0;
            end
            else
            begin
                BTB_jmp_EX <= BTB_jmp_ID;
                BTB_NPC_Pred_EX <= BTB_NPC_Pred_ID;
                BTB_find_EX <= BTB_find_ID;
            end
        end
    
endmodule