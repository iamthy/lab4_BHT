module IF_ID(
    input wire clk, bubbleD, flushD,
    input wire BTB_jmp_IF,
    input wire [31:0] BTB_NPC_Pred_IF,
    input wire BTB_find_IF,
    output reg BTB_jmp_ID,
    output reg [31:0] BTB_NPC_Pred_ID,
    output reg BTB_find_ID
    );

    initial 
    begin
        BTB_jmp_ID = 0;
        BTB_NPC_Pred_ID = 0;
        BTB_find_ID = 0;
    end
    
    always@(posedge clk)
        if (!bubbleD) 
        begin
            if (flushD)
            begin
                BTB_jmp_ID <= 0;
                BTB_NPC_Pred_ID <= 0;
                BTB_find_ID <= 0;
            end
            else
            begin
                BTB_jmp_ID <= BTB_jmp_IF;
                BTB_NPC_Pred_ID <= BTB_NPC_Pred_IF;
                BTB_find_ID <= BTB_find_IF;
            end
        end
    
endmodule