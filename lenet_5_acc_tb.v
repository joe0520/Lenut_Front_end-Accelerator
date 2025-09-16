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

module lenet_5_acc_tb;
    
    reg clk = 0;
    reg rst_n;
    wire down_scale_valid;
    wire [7:0] down_scale_data;
    
    lenet_5_acc lenet_5_acc(
        .clk(clk),
        .rst_n(rst_n),    
        .down_scale_valid(down_scale_valid),
        .down_scale_data(down_scale_data)
    );
    
    always #5 clk= ~clk;
    
    initial begin
        rst_n = 0;
        #10
        rst_n = 1;
    end
    
endmodule