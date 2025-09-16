`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/19 14:34:58
// Design Name: 
// Module Name: down_scale_controller
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


module down_scale_controller(
    input clk, // 100 MHz input clock
    input rst_n, // Active-low asynchronous reset
    input p_vsync, // Vertical sync pulse
    input p_hsync, // Horizontal sync pulse
    input [7:0] p_data,
    output reg down_scale_con_valid,
    output reg [7:0]    down_scale_con_line_0, down_scale_con_line_1, down_scale_con_line_2,
                         down_scale_con_line_3, down_scale_con_line_4, down_scale_con_line_5,
                         down_scale_con_line_6, down_scale_con_line_7, down_scale_con_line_8,
                         down_scale_con_line_9, down_scale_con_line_10, down_scale_con_line_11,
                         down_scale_con_line_12, down_scale_con_line_13, down_scale_con_line_14
    );
    localparam idle = 4'd6;
    
    integer x;
    
    reg [4:0] r_c_state;
    reg [4:0] r_n_state;
    
    reg [3:0] w_c_state;
    reg [3:0] w_n_state;
    
    reg [17:0] we;
    reg [7:0] din[0:17];
    
    reg [17:0] valid;
    wire [7:0] dout[0:17];
    
    reg [17:0] buf_ready;
    wire [17:0] ready;
    
    wire data_hs = p_vsync & p_hsync;
    
    reg [9:0] r_cnt;
    wire next_bram = r_cnt == 639 & data_hs;
    
    
    always@(posedge clk)begin
        if(!rst_n)begin
            buf_ready <= 0;
        end else begin
            buf_ready <= ready;
        end
    end
    
    //read count
    always@(posedge clk)begin
        if(!rst_n)begin
            r_cnt <= 0;
        end else begin
            if(next_bram)begin
                r_cnt <= 0;
            end else if(data_hs)begin
                r_cnt <= r_cnt + 1;
            end 
        end
    end
    
    //read state
    always@(posedge clk)begin
        if(!rst_n)begin
            r_c_state <= 0;
        end else begin
            r_c_state <= r_n_state;
        end
    end
    
    always@(*)begin
        r_n_state = r_c_state;
        case(r_c_state)
            0:begin
                if(next_bram) r_n_state = 1;
            end
            1:begin
                if(next_bram) r_n_state = 2;
            end
            2:begin
                if(next_bram) r_n_state = 3;
            end
            3:begin
                if(next_bram) r_n_state = 4;
            end
            4:begin
                if(next_bram) r_n_state = 5;
            end
            5:begin
                if(next_bram) r_n_state = 6;
            end
            6:begin
                if(next_bram) r_n_state = 7;
            end
            7:begin
                if(next_bram) r_n_state = 8;
            end
            8:begin
                if(next_bram) r_n_state = 9;
            end
            9:begin
                if(next_bram) r_n_state = 10;
            end
            10:begin
                if(next_bram) r_n_state = 11;
            end
            11:begin
                if(next_bram) r_n_state = 12;
            end
            12:begin
                if(next_bram) r_n_state = 13;
            end
            13:begin
                if(next_bram) r_n_state = 14;
            end
            14:begin
                if(next_bram) r_n_state = 15;
            end
            15:begin
                if(next_bram) r_n_state = 16;
            end
            16:begin
                if(next_bram) r_n_state = 17;
            end
            17:begin
                if(next_bram) r_n_state = 0;
            end
        endcase
    end
    
    always@(*)begin
        we = 0;
        for(x=0; x<18; x=x+1)begin
            din[x] = 0;
        end
        case(r_c_state)
            0:begin
                we[0] = data_hs;
                din[0] = p_data;
            end
            1:begin
                we[1] = data_hs;
                din[1] = p_data;
            end
            2:begin
                we[2] = data_hs;
                din[2] = p_data;
            end
            3:begin
                we[3] = data_hs;
                din[3] = p_data;
            end
            4:begin
                we[4] = data_hs;
                din[4] = p_data;
            end
            5:begin
                we[5] = data_hs;
                din[5] = p_data;
            end
            6:begin
                we[6] = data_hs;
                din[6] = p_data;
            end
            7:begin
                we[7] = data_hs;
                din[7] = p_data;
            end
            8:begin
                we[8] = data_hs;
                din[8] = p_data;
            end
            9:begin
                we[9] = data_hs;
                din[9] = p_data;
            end
            10:begin
                we[10] = data_hs;
                din[10] = p_data;
            end
            11:begin
                we[11] = data_hs;
                din[11] = p_data;
            end
            12:begin
                we[12] = data_hs;
                din[12] = p_data;
            end
            13:begin
                we[13] = data_hs;
                din[13] = p_data;
            end
            14:begin
                we[14] = data_hs;
                din[14] = p_data;
            end
            15:begin
                we[15] = data_hs;
                din[15] = p_data;
            end
            16:begin
                we[16] = data_hs;
                din[16] = p_data;
            end
            17:begin
                we[17] = data_hs;
                din[17] = p_data;
            end
        endcase
    end
    
    //write state
    always@(posedge clk)begin
        if(!rst_n)begin
            w_c_state <=idle;
        end else begin
            w_c_state <= w_n_state;
        end
    end
    
    always@(*)begin
        w_n_state = w_c_state;
        case(w_c_state)
            idle:begin
                if(ready[2]&ready[14]) w_n_state = 0;
            end
            0:begin
                if(ready[17]&ready[11]) w_n_state = 1;
            end
            1:begin
                if(ready[14]&ready[8]) w_n_state = 2;
            end
            2:begin
                if(ready[11]&ready[5]) w_n_state = 3;
            end
            3:begin
                if(ready[8]&ready[2]) w_n_state = 4;
            end
            4:begin
                if(ready[5]&ready[17]) w_n_state = 5;
            end
            5:begin
                if(ready[2]&ready[14]) w_n_state = 0;
            end
        endcase
    end
    
    
    always@(posedge clk)begin
        if(!rst_n)begin
            down_scale_con_valid <= 0;
            down_scale_con_line_0 <= 0; down_scale_con_line_1 <= 0; down_scale_con_line_2 <= 0;
            down_scale_con_line_3 <= 0; down_scale_con_line_4 <= 0; down_scale_con_line_5 <= 0;
            down_scale_con_line_6 <= 0; down_scale_con_line_7 <= 0; down_scale_con_line_8 <= 0;
            down_scale_con_line_9 <= 0; down_scale_con_line_10 <= 0; down_scale_con_line_11 <= 0;
            down_scale_con_line_12 <= 0; down_scale_con_line_13 <= 0; down_scale_con_line_14 <= 0;
        end else begin
            case(w_c_state)
                0:begin
                    if(ready[14])begin
                        down_scale_con_valid <= 1;
                        down_scale_con_line_0 <= dout[0]; down_scale_con_line_1 <= dout[1]; down_scale_con_line_2 <= dout[2];
                        down_scale_con_line_3 <= dout[3]; down_scale_con_line_4 <= dout[4]; down_scale_con_line_5 <= dout[5];
                        down_scale_con_line_6 <= dout[6]; down_scale_con_line_7 <= dout[7]; down_scale_con_line_8 <= dout[8];
                        down_scale_con_line_9 <= dout[9]; down_scale_con_line_10 <= dout[10]; down_scale_con_line_11 <= dout[11];
                        down_scale_con_line_12 <= dout[12]; down_scale_con_line_13 <= dout[13]; down_scale_con_line_14 <= dout[14];
                    end else begin
                        down_scale_con_valid <= 0;
                    end
                end
                1:begin
                    if(ready[11])begin
                        down_scale_con_valid <= 1;
                        down_scale_con_line_0 <= dout[15]; down_scale_con_line_1 <= dout[16]; down_scale_con_line_2 <= dout[17];
                        down_scale_con_line_3 <= dout[0]; down_scale_con_line_4 <= dout[1]; down_scale_con_line_5 <= dout[2];
                        down_scale_con_line_6 <= dout[3]; down_scale_con_line_7 <= dout[4]; down_scale_con_line_8 <= dout[5];
                        down_scale_con_line_9 <= dout[6]; down_scale_con_line_10 <= dout[7]; down_scale_con_line_11 <= dout[8];
                        down_scale_con_line_12 <= dout[9]; down_scale_con_line_13 <= dout[10]; down_scale_con_line_14 <= dout[11];
                    end else begin
                        down_scale_con_valid <= 0;
                    end
                end
                2:begin
                    if(ready[8])begin
                        down_scale_con_valid <= 1;
                        down_scale_con_line_0 <= dout[12]; down_scale_con_line_1 <= dout[13]; down_scale_con_line_2 <= dout[14];
                        down_scale_con_line_3 <= dout[15]; down_scale_con_line_4 <= dout[16]; down_scale_con_line_5 <= dout[17];
                        down_scale_con_line_6 <= dout[0]; down_scale_con_line_7 <= dout[1]; down_scale_con_line_8 <= dout[2];
                        down_scale_con_line_9 <= dout[3]; down_scale_con_line_10 <= dout[4]; down_scale_con_line_11 <= dout[5];
                        down_scale_con_line_12 <= dout[6]; down_scale_con_line_13 <= dout[7]; down_scale_con_line_14 <= dout[8];
                    end else begin
                        down_scale_con_valid <= 0;
                    end
                end
                3:begin
                    if(ready[5])begin
                        down_scale_con_valid <= 1;
                        down_scale_con_line_0 <= dout[9]; down_scale_con_line_1 <= dout[10]; down_scale_con_line_2 <= dout[11];
                        down_scale_con_line_3 <= dout[12]; down_scale_con_line_4 <= dout[13]; down_scale_con_line_5 <= dout[14];
                        down_scale_con_line_6 <= dout[15]; down_scale_con_line_7 <= dout[16]; down_scale_con_line_8 <= dout[17];
                        down_scale_con_line_9 <= dout[0]; down_scale_con_line_10 <= dout[1]; down_scale_con_line_11 <= dout[2];
                        down_scale_con_line_12 <= dout[3]; down_scale_con_line_13 <= dout[4]; down_scale_con_line_14 <= dout[5];
                    end else begin
                        down_scale_con_valid <= 0;
                    end
                end
                4:begin
                    if(ready[2])begin
                        down_scale_con_valid <= 1;
                        down_scale_con_line_0 <= dout[6]; down_scale_con_line_1 <= dout[7]; down_scale_con_line_2 <= dout[8];
                        down_scale_con_line_3 <= dout[9]; down_scale_con_line_4 <= dout[10]; down_scale_con_line_5 <= dout[11];
                        down_scale_con_line_6 <= dout[12]; down_scale_con_line_7 <= dout[13]; down_scale_con_line_8 <= dout[14];
                        down_scale_con_line_9 <= dout[15]; down_scale_con_line_10 <= dout[16]; down_scale_con_line_11 <= dout[17];
                        down_scale_con_line_12 <= dout[0]; down_scale_con_line_13 <= dout[1]; down_scale_con_line_14 <= dout[2];
                    end else begin
                        down_scale_con_valid <= 0;
                    end
                end
                5:begin
                    if(ready[17])begin
                        down_scale_con_valid <= 1;
                        down_scale_con_line_0 <= dout[3]; down_scale_con_line_1 <= dout[4]; down_scale_con_line_2 <= dout[5];
                        down_scale_con_line_3 <= dout[6]; down_scale_con_line_4 <= dout[7]; down_scale_con_line_5 <= dout[8];
                        down_scale_con_line_6 <= dout[9]; down_scale_con_line_7 <= dout[10]; down_scale_con_line_8 <= dout[11];
                        down_scale_con_line_9 <= dout[12]; down_scale_con_line_10 <= dout[13]; down_scale_con_line_11 <= dout[14];
                        down_scale_con_line_12 <= dout[15]; down_scale_con_line_13 <= dout[16]; down_scale_con_line_14 <= dout[17];
                    end else begin
                        down_scale_con_valid <= 0;
                    end
                end
            endcase
        end
    end
    
    always@(*)begin
        valid[0] = 0; valid[1] = 0; valid[2] = 0;
        valid[3] = 0; valid[4] = 0; valid[5] = 0;
        valid[6] = 0; valid[7] = 0; valid[8] = 0;
        valid[9] = 0; valid[10] = 0; valid[11] = 0;
        valid[12] = 0; valid[13] = 0; valid[14] = 0;
        valid[15] = 0; valid[16] = 0; valid[17] = 0;
        case(w_c_state)
            idle:begin
                if(ready[14])begin
                    valid[0] = 1; valid[1] = 1; valid[2] = 1;
                    valid[3] = 1; valid[4] = 1; valid[5] = 1;
                    valid[6] = 1; valid[7] = 1; valid[8] = 1;
                    valid[9] = 1; valid[10] = 1; valid[11] = 1;
                    valid[12] = 1; valid[13] = 1; valid[14] = 1;
                end
            end
            0:begin
                if(ready[14])begin
                    valid[0] = 1; valid[1] = 1; valid[2] = 1;
                    valid[3] = 1; valid[4] = 1; valid[5] = 1;
                    valid[6] = 1; valid[7] = 1; valid[8] = 1;
                    valid[9] = 1; valid[10] = 1; valid[11] = 1;
                    valid[12] = 1; valid[13] = 1; valid[14] = 1;
                end else if((~ready[14]) & ready[11])begin
                    valid[15] = 1; valid[16] = 1; valid[17] = 1;
                    valid[0] = 1; valid[1] = 1; valid[2] = 1;
                    valid[3] = 1; valid[4] = 1; valid[5] = 1;
                    valid[6] = 1; valid[7] = 1; valid[8] = 1;
                    valid[9] = 1; valid[10] = 1; valid[11] = 1;
                end
            end
            1:begin
                if(ready[11])begin
                    valid[15] = 1; valid[16] = 1; valid[17] = 1;
                    valid[0] = 1; valid[1] = 1; valid[2] = 1;
                    valid[3] = 1; valid[4] = 1; valid[5] = 1;
                    valid[6] = 1; valid[7] = 1; valid[8] = 1;
                    valid[9] = 1; valid[10] = 1; valid[11] = 1;
                end else if((~ready[11]) & ready[8])begin
                    valid[12] = 1; valid[13] = 1; valid[14] = 1;
                    valid[15] = 1; valid[16] = 1; valid[17] = 1;
                    valid[0] = 1; valid[1] = 1; valid[2] = 1;
                    valid[3] = 1; valid[4] = 1; valid[5] = 1;
                    valid[6] = 1; valid[7] = 1; valid[8] = 1;
                end
            end
            2:begin
                if(ready[8])begin
                    valid[12] = 1; valid[13] = 1; valid[14] = 1;
                    valid[15] = 1; valid[16] = 1; valid[17] = 1;
                    valid[0] = 1; valid[1] = 1; valid[2] = 1;
                    valid[3] = 1; valid[4] = 1; valid[5] = 1;
                    valid[6] = 1; valid[7] = 1; valid[8] = 1;
                end else if((~ready[8]) & ready[5])begin
                    valid[9] = 1; valid[10] = 1; valid[11] = 1;
                    valid[12] = 1; valid[13] = 1; valid[14] = 1;
                    valid[15] = 1; valid[16] = 1; valid[17] = 1;
                    valid[0] = 1; valid[1] = 1; valid[2] = 1;
                    valid[3] = 1; valid[4] = 1; valid[5] = 1;
                end
            end
            3:begin
                if(ready[5])begin
                    valid[9] = 1; valid[10] = 1; valid[11] = 1;
                    valid[12] = 1; valid[13] = 1; valid[14] = 1;
                    valid[15] = 1; valid[16] = 1; valid[17] = 1;
                    valid[0] = 1; valid[1] = 1; valid[2] = 1;
                    valid[3] = 1; valid[4] = 1; valid[5] = 1;
                end else if((~ready[5]) & ready[2])begin
                    valid[6] = 1; valid[7] = 1; valid[8] = 1;
                    valid[9] = 1; valid[10] = 1; valid[11] = 1;
                    valid[12] = 1; valid[13] = 1; valid[14] = 1;
                    valid[15] = 1; valid[16] = 1; valid[17] = 1;
                    valid[0] = 1; valid[1] = 1; valid[2] = 1;
                end
            end
            4:begin
                if(ready[2])begin
                    valid[6] = 1; valid[7] = 1; valid[8] = 1;
                    valid[9] = 1; valid[10] = 1; valid[11] = 1;
                    valid[12] = 1; valid[13] = 1; valid[14] = 1;
                    valid[15] = 1; valid[16] = 1; valid[17] = 1;
                    valid[0] = 1; valid[1] = 1; valid[2] = 1;
                end else if((~ready[2]) & ready[17])begin
                    valid[3] = 1; valid[4] = 1; valid[5] = 1;
                    valid[6] = 1; valid[7] = 1; valid[8] = 1;
                    valid[9] = 1; valid[10] = 1; valid[11] = 1;
                    valid[12] = 1; valid[13] = 1; valid[14] = 1;
                    valid[15] = 1; valid[16] = 1; valid[17] = 1;
                end
            end
            5:begin
                if(ready[17])begin
                    valid[3] = 1; valid[4] = 1; valid[5] = 1;
                    valid[6] = 1; valid[7] = 1; valid[8] = 1;
                    valid[9] = 1; valid[10] = 1; valid[11] = 1;
                    valid[12] = 1; valid[13] = 1; valid[14] = 1;
                    valid[15] = 1; valid[16] = 1; valid[17] = 1;
                end else if((~ready[17]) & ready[14])begin
                    valid[0] = 1; valid[1] = 1; valid[2] = 1;
                    valid[3] = 1; valid[4] = 1; valid[5] = 1;
                    valid[6] = 1; valid[7] = 1; valid[8] = 1;
                    valid[9] = 1; valid[10] = 1; valid[11] = 1;
                    valid[12] = 1; valid[13] = 1; valid[14] = 1;
                end
            end
        endcase
    end
    
    genvar i;
    generate
        for(i=0; i<18; i=i+1)begin
            down_scale_bram_controller#(
                .WIDTH(8),
                .Depth(640)
            )down_scale_bram_controller(
                .clk(clk),
                .rst_n(rst_n),
                .we(we[i]),
                .din(din[i]),
                .valid(valid[i]),
                .dout(dout[i]),
                .ready(ready[i])
            );
        end
    endgenerate
endmodule
