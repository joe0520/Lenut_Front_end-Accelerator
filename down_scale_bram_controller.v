`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/19 13:47:26
// Design Name: 
// Module Name: bram_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module down_scale_bram_controller#(
parameter WIDTH = 8,
parameter Depth = 640
)(
    input clk,
    input rst_n,
    input we,
    input[WIDTH-1:0] din,
    input valid,
    output [WIDTH-1:0] dout,
    output reg ready
    );
    
    reg [clogb2(Depth-1)-1:0] r_cnt, w_cnt;
    reg [clogb2(Depth-1)-1:0] addr;
    wire ce;
    
    always@(posedge clk)begin
        if(!rst_n)begin
            r_cnt <= 0;
            w_cnt <= 0;
            ready <= 0;
        end else begin
            if(valid & ready & w_cnt == Depth)begin
                ready <= 0;
            end else if(we & r_cnt == Depth-1)begin
                ready <= 1;
            end
            
            if(valid & ready & w_cnt == Depth)begin
                r_cnt <= 0;
            end else if(we & ~ready)begin
                r_cnt <= r_cnt + 1;
            end
            
            if(valid & ready & w_cnt == Depth)begin
                w_cnt <= 0;
            end else if(valid & ready)begin
                w_cnt <= w_cnt + 1;
            end
        end
    end
    
    always@(*)begin
        if(ready)begin
            addr = w_cnt;
        end else begin
            addr = r_cnt;
        end
    end
    
    assign ce = ready | we;
    
    bram #(
    .DWIDTH(8),
    .DDepth(680)
    )bram(
        .clk(clk),
        .addr(addr),
        .ce(ce),
        .we(we),
        .dout(dout),
        .din(din)
    );
    
function integer clogb2;
    input integer answer;
      for (clogb2=0; answer>0; clogb2=clogb2+1)
        answer = answer >> 1;
endfunction
    
endmodule
