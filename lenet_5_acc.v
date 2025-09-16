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

module lenet_5_acc(
    input clk,
    input rst_n,
    
    output down_scale_valid,
    output [7:0] down_scale_data
    );
    
    //wire down_scale_valid;
    //wire [7:0] down_scale_data;
    
    wire p_vsync;
    wire p_hsync;
    wire [7:0] p_data;
    wire [3:0] image_num;
    
    wire down_scale_con_valid;
    
    wire [7:0]  down_scale_con_line_0, down_scale_con_line_1, down_scale_con_line_2,
                down_scale_con_line_3, down_scale_con_line_4, down_scale_con_line_5,
                down_scale_con_line_6, down_scale_con_line_7, down_scale_con_line_8,
                down_scale_con_line_9, down_scale_con_line_10, down_scale_con_line_11,
                down_scale_con_line_12, down_scale_con_line_13, down_scale_con_line_14;
                
    //**** test zone ****
    reg start;
    reg [9:0] stop_cnt;
    reg [7:0] delay;
    
    always@(posedge clk)begin
        if(!rst_n)begin
            start <= 0;
            stop_cnt <= 0;
        end else begin
            if(down_scale_valid & stop_cnt == 1023)begin
                start <= 0;
                stop_cnt <= 0;
            end else if(delay ==0) begin
                start <= 1;
                if(down_scale_valid)stop_cnt <= stop_cnt + 1;
            end
        end
    end
    
    always@(posedge clk)begin
        if(!rst_n)begin
            delay <= 0;
        end else begin
            if(delay == 100)begin
                delay <= 0;
            end else if(delay != 0 & delay !=100)begin
                delay <= delay + 1;
            end else if(down_scale_valid & stop_cnt == 1023)begin
                delay <= 1;
            end
        end
    end
    
    //**** test zone end ****
    
    pseudo_sensor pseudo_sensor (
		    .clk(clk), // 100 MHz input clock
		    .rstn(rst_n), // Active-low asynchronous reset
		    .start(start),
		    .p_vsync(p_vsync), // Vertical sync pulse
		    .p_hsync(p_hsync), // Horizontal sync pulse
		    .p_data(p_data),
		    .image_num(image_num)
		    );
    
    down_scale_controller down_scale_controller(
    .clk(clk), // 100 MHz input clock
    .rst_n(rst_n), // Active-low asynchronous reset
    .p_vsync(p_vsync), // Vertical sync pulse
    .p_hsync(p_hsync), // Horizontal sync pulse
    .p_data(p_data),
    .down_scale_con_valid(down_scale_con_valid),
    .down_scale_con_line_0(down_scale_con_line_0), .down_scale_con_line_1(down_scale_con_line_1), .down_scale_con_line_2(down_scale_con_line_2),
    .down_scale_con_line_3(down_scale_con_line_3), .down_scale_con_line_4(down_scale_con_line_4), .down_scale_con_line_5(down_scale_con_line_5),
    .down_scale_con_line_6(down_scale_con_line_6), .down_scale_con_line_7(down_scale_con_line_7), .down_scale_con_line_8(down_scale_con_line_8),
    .down_scale_con_line_9(down_scale_con_line_9), .down_scale_con_line_10(down_scale_con_line_10), .down_scale_con_line_11(down_scale_con_line_11),
    .down_scale_con_line_12(down_scale_con_line_12), .down_scale_con_line_13(down_scale_con_line_13), .down_scale_con_line_14(down_scale_con_line_14)
    );
    
    down_scale_PU down_scale_PU(
    .clk(clk), // 100 MHz input clock
    .rst_n(rst_n), // Active-low asynchronous reset
    .down_scale_con_valid(down_scale_con_valid),
    .down_scale_con_line_0(down_scale_con_line_0), .down_scale_con_line_1(down_scale_con_line_1), .down_scale_con_line_2(down_scale_con_line_2),
    .down_scale_con_line_3(down_scale_con_line_3), .down_scale_con_line_4(down_scale_con_line_4), .down_scale_con_line_5(down_scale_con_line_5),
    .down_scale_con_line_6(down_scale_con_line_6), .down_scale_con_line_7(down_scale_con_line_7), .down_scale_con_line_8(down_scale_con_line_8),
    .down_scale_con_line_9(down_scale_con_line_9), .down_scale_con_line_10(down_scale_con_line_10), .down_scale_con_line_11(down_scale_con_line_11),
    .down_scale_con_line_12(down_scale_con_line_12), .down_scale_con_line_13(down_scale_con_line_13), .down_scale_con_line_14(down_scale_con_line_14),
    .down_scale_valid(down_scale_valid),
    .down_scale_data(down_scale_data)
    );
    
    
endmodule