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

module bram #(
parameter DWIDTH = 64,
parameter DDepth = 2048
)(
    input clk,
    input [clogb2(DDepth-1)-1:0] addr,
    input ce,
    input we,
    output reg[DWIDTH-1:0] dout,
    input[DWIDTH-1:0] din
);

(* ram_style = "block" *)reg [DWIDTH-1:0] ram[0:DDepth-1];

always @(posedge clk)begin 
    if (ce) begin
        if (we) 
            ram[addr] <= din;
		else
        	dout <= ram[addr];
    end
end

function integer clogb2;
    input integer answer;
      for (clogb2=0; answer>0; clogb2=clogb2+1)
        answer = answer >> 1;
endfunction

endmodule