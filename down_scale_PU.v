`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/22 13:35:24
// Design Name: 
// Module Name: down_scale_PU
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


module down_scale_PU(
    input clk, // 100 MHz input clock
    input rst_n, // Active-low asynchronous reset
    input down_scale_con_valid,
    input [7:0]    down_scale_con_line_0, down_scale_con_line_1, down_scale_con_line_2,
                    down_scale_con_line_3, down_scale_con_line_4, down_scale_con_line_5,
                    down_scale_con_line_6, down_scale_con_line_7, down_scale_con_line_8,
                    down_scale_con_line_9, down_scale_con_line_10, down_scale_con_line_11,
                    down_scale_con_line_12, down_scale_con_line_13, down_scale_con_line_14,
    output reg down_scale_valid,
    output reg [7:0] down_scale_data
    );
    
    reg [11:0] buf0_down_scale_data_0, buf0_down_scale_data_1, buf0_down_scale_data_2, buf0_down_scale_data_3, buf0_down_scale_data_4;
    reg buf0_down_scale_valid;
    
    reg [13:0] buf1_down_scale_data_0, buf1_down_scale_data_1;
    reg buf_1_down_scale_valid;
    
    reg [4:0] sum_cnt;
    reg sum_valid;
    reg [16:0] sum_down_scale_data;
    reg [31:0] total_down_scale_data;
    
    //pipe 0
    always@(posedge clk)begin
        if(!rst_n)begin
            buf0_down_scale_valid <= 0;
            buf0_down_scale_data_0 <= 0;
            buf0_down_scale_data_1 <= 0;
            buf0_down_scale_data_2 <= 0;
            buf0_down_scale_data_3 <= 0;
            buf0_down_scale_data_4 <= 0;
        end else begin
            if(down_scale_con_valid)begin
                buf0_down_scale_valid <= 1;
                buf0_down_scale_data_0 <= down_scale_con_line_0 + down_scale_con_line_1 + down_scale_con_line_2;
                buf0_down_scale_data_1 <= down_scale_con_line_3 + down_scale_con_line_4 + down_scale_con_line_5;
                buf0_down_scale_data_2 <= down_scale_con_line_6 + down_scale_con_line_7 + down_scale_con_line_8;
                buf0_down_scale_data_3 <= down_scale_con_line_9 + down_scale_con_line_10 + down_scale_con_line_11;
                buf0_down_scale_data_4 <= down_scale_con_line_12 + down_scale_con_line_13 + down_scale_con_line_14;
            end else begin
                buf0_down_scale_valid <= 0;
            end
        end
    end
    
    //pipe 1
    always@(posedge clk)begin
        if(!rst_n)begin
            buf1_down_scale_data_0 <= 0;
            buf1_down_scale_data_1 <= 0;
        end else begin
            if(buf0_down_scale_valid)begin
                buf_1_down_scale_valid <= 1;
                buf1_down_scale_data_0 <= buf0_down_scale_data_0 + buf0_down_scale_data_1;
                buf1_down_scale_data_1 <= buf0_down_scale_data_2 + buf0_down_scale_data_3 + buf0_down_scale_data_4;
            end else begin
                buf_1_down_scale_valid <= 0;
            end
        end
    end
    
    //pipe 2
    always@(posedge clk)begin
        if(!rst_n)begin
            sum_cnt <= 0;
            sum_valid <= 0;
            sum_down_scale_data <= 0;
            total_down_scale_data <= 0;
        end else begin
            if(buf_1_down_scale_valid & sum_cnt == 19)begin
                sum_cnt <= 0;
                sum_down_scale_data <= 0;
                total_down_scale_data <= sum_down_scale_data + buf1_down_scale_data_0 + buf1_down_scale_data_1;
                sum_valid <= 1;
            end else if(buf_1_down_scale_valid)begin
                sum_cnt <= sum_cnt+1;
                sum_down_scale_data <= sum_down_scale_data + buf1_down_scale_data_0 + buf1_down_scale_data_1;
                sum_valid <= 0;
            end else begin
                sum_valid <= 0;
            end
        end
    end
    
    //pipe 3
    always@(posedge clk)begin
        if(!rst_n)begin
            down_scale_valid <= 0;
            down_scale_data <= 0;
        end else begin
            if(sum_valid)begin
                down_scale_valid <= 1;
                down_scale_data <= (total_down_scale_data * 218) >>16;
            end else begin
                down_scale_valid <= 0;
            end
        end
    end
    
    
endmodule
