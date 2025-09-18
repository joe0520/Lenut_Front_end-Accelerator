`timescale 1ns / 1ps

module c1_maxpooling_unit (
    input           clk,
    input           rst_n,
    
    // Input from conv_5x5_pe (6 channels, 28x28)
    input           conv_valid,        // Convolution output valid
    input [31:0]    conv_ch0_out,      // Channel 0 output from conv
    input [31:0]    conv_ch1_out,      // Channel 1 output from conv
    input [31:0]    conv_ch2_out,      // Channel 2 output from conv
    input [31:0]    conv_ch3_out,      // Channel 3 output from conv
    input [31:0]    conv_ch4_out,      // Channel 4 output from conv
    input [31:0]    conv_ch5_out,      // Channel 5 output from conv
    
    // Output to S2 layer (6 channels, 14x14)
    output reg      mp_valid,          // Maxpooling output valid
    output reg [7:0] mp_ch0_out,       // Channel 0 maxpool output
    output reg [7:0] mp_ch1_out,       // Channel 1 maxpool output
    output reg [7:0] mp_ch2_out,       // Channel 2 maxpool output
    output reg [7:0] mp_ch3_out,       // Channel 3 maxpool output
    output reg [7:0] mp_ch4_out,       // Channel 4 maxpool output
    output reg [7:0] mp_ch5_out,       // Channel 5 maxpool output
    
    // Control signals
    output reg      ping_full,         // Ping buffer full (2 rows)
    output reg      pong_full,         // Pong buffer full (2 rows)
    output [2:0]    current_state       // Current FSM state
);

    // Parameters
    parameter HW_S = 4;  // Hardware stride for convolution output
    parameter CONV_WIDTH = 28;
    parameter POOL_WIDTH = 14;
    
    // FSM states
    localparam IDLE = 3'd0;
    localparam FILL_PING_ROW0 = 3'd1;
    localparam FILL_PING_ROW1 = 3'd2;
    localparam POOL_PING_FILL_PONG = 3'd3;
    localparam FILL_PONG_ROW0 = 3'd4;
    localparam FILL_PONG_ROW1 = 3'd5;
    localparam POOL_PONG_FILL_PING = 3'd6;
    
    reg [2:0] state, next_state;
    
    // Ping-Pong buffers: [channel][row][column]
    // Each buffer stores 2 rows x 28 columns
    reg [31:0] ping_buffer [0:5][0:1][0:27];  // 6 channels, 2 rows, 28 cols
    reg [31:0] pong_buffer [0:5][0:1][0:27];  // 6 channels, 2 rows, 28 cols
    
    // Position counters
    reg [4:0] col_cnt;      // Column counter (0-27)
    reg [4:0] row_cnt;      // Row counter within buffer (0-1)
    reg [4:0] total_row_cnt; // Total row counter (0-27)
    
    // Pooling control
    reg pool_ping_start, pool_pong_start;
    reg [3:0] pool_col_cnt;  // Pooling column counter (0-13)
    reg pool_done;
    
    // Pipeline registers for maxpooling
    reg [31:0] max_stage1 [0:5][0:1];  // First stage: max of 2x1
    reg [7:0]  max_result [0:5];       // Final result after quantization
    reg        max_valid_stage1, max_valid_stage2;
    
    integer i, j, k;
    
    // =====================================
    // FSM State Register
    // =====================================
    always @(posedge clk) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // =====================================
    // FSM Next State Logic
    // =====================================
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (conv_valid)
                    next_state = FILL_PING_ROW0;
            end
            
            FILL_PING_ROW0: begin
                if (conv_valid && col_cnt == 27)
                    next_state = FILL_PING_ROW1;
            end
            
            FILL_PING_ROW1: begin
                if (conv_valid && col_cnt == 27) begin
                    if (total_row_cnt >= 27)
                        next_state = IDLE;  // Last rows, no more data
                    else
                        next_state = POOL_PING_FILL_PONG;
                end
            end
            
            POOL_PING_FILL_PONG: begin
                // Stay in this state until pong is filled
                if (pong_full) begin
                    if (total_row_cnt >= 27)
                        next_state = IDLE;
                    else
                        next_state = POOL_PONG_FILL_PING;
                end
            end
            
            POOL_PONG_FILL_PING: begin
                // Stay in this state until ping is filled
                if (ping_full) begin
                    if (total_row_cnt >= 27)
                        next_state = IDLE;
                    else
                        next_state = POOL_PING_FILL_PONG;
                end
            end
        endcase
    end
    
    // =====================================
    // Buffer Write Control
    // =====================================
    always @(posedge clk) begin
        if (!rst_n) begin
            col_cnt <= 5'd0;
            row_cnt <= 5'd0;
            total_row_cnt <= 5'd0;
            ping_full <= 1'b0;
            pong_full <= 1'b0;
            
            // Clear buffers
            for (i = 0; i < 6; i = i + 1) begin
                for (j = 0; j < 2; j = j + 1) begin
                    for (k = 0; k < 28; k = k + 1) begin
                        ping_buffer[i][j][k] <= 32'd0;
                        pong_buffer[i][j][k] <= 32'd0;
                    end
                end
            end
        end else begin
            // Column counter management
            if (conv_valid) begin
                if (col_cnt == 27) begin
                    col_cnt <= 5'd0;
                    
                    // Row management
                    if (state == FILL_PING_ROW0 || state == FILL_PING_ROW1) begin
                        if (row_cnt == 1) begin
                            row_cnt <= 5'd0;
                            ping_full <= 1'b1;
                        end else begin
                            row_cnt <= row_cnt + 1;
                        end
                    end else if (state == POOL_PING_FILL_PONG || state == POOL_PONG_FILL_PING) begin
                        if (row_cnt == 1) begin
                            row_cnt <= 5'd0;
                            if (state == POOL_PING_FILL_PONG)
                                pong_full <= 1'b1;
                            else
                                ping_full <= 1'b1;
                        end else begin
                            row_cnt <= row_cnt + 1;
                        end
                    end
                    
                    // Total row counter
                    total_row_cnt <= total_row_cnt + 1;
                end else begin
                    col_cnt <= col_cnt + 1;
                end
            end
            
            // Clear full flags after pooling starts
            if (pool_ping_start) ping_full <= 1'b0;
            if (pool_pong_start) pong_full <= 1'b0;
            
            // Write to appropriate buffer
            if (conv_valid) begin
                case (state)
                    FILL_PING_ROW0, FILL_PING_ROW1: begin
                        ping_buffer[0][row_cnt][col_cnt] <= conv_ch0_out;
                        ping_buffer[1][row_cnt][col_cnt] <= conv_ch1_out;
                        ping_buffer[2][row_cnt][col_cnt] <= conv_ch2_out;
                        ping_buffer[3][row_cnt][col_cnt] <= conv_ch3_out;
                        ping_buffer[4][row_cnt][col_cnt] <= conv_ch4_out;
                        ping_buffer[5][row_cnt][col_cnt] <= conv_ch5_out;
                    end
                    
                    POOL_PING_FILL_PONG: begin
                        pong_buffer[0][row_cnt][col_cnt] <= conv_ch0_out;
                        pong_buffer[1][row_cnt][col_cnt] <= conv_ch1_out;
                        pong_buffer[2][row_cnt][col_cnt] <= conv_ch2_out;
                        pong_buffer[3][row_cnt][col_cnt] <= conv_ch3_out;
                        pong_buffer[4][row_cnt][col_cnt] <= conv_ch4_out;
                        pong_buffer[5][row_cnt][col_cnt] <= conv_ch5_out;
                    end
                    
                    POOL_PONG_FILL_PING: begin
                        ping_buffer[0][row_cnt][col_cnt] <= conv_ch0_out;
                        ping_buffer[1][row_cnt][col_cnt] <= conv_ch1_out;
                        ping_buffer[2][row_cnt][col_cnt] <= conv_ch2_out;
                        ping_buffer[3][row_cnt][col_cnt] <= conv_ch3_out;
                        ping_buffer[4][row_cnt][col_cnt] <= conv_ch4_out;
                        ping_buffer[5][row_cnt][col_cnt] <= conv_ch5_out;
                    end
                endcase
            end
        end
    end
    
    // =====================================
    // Maxpooling Control
    // =====================================
    always @(posedge clk) begin
        if (!rst_n) begin
            pool_ping_start <= 1'b0;
            pool_pong_start <= 1'b0;
            pool_col_cnt <= 4'd0;
            pool_done <= 1'b0;
        end else begin
            pool_ping_start <= 1'b0;
            pool_pong_start <= 1'b0;
            pool_done <= 1'b0;
            
            // Start pooling when buffer is full
            if (ping_full && state == POOL_PING_FILL_PONG) begin
                pool_ping_start <= 1'b1;
                pool_col_cnt <= 4'd0;
            end else if (pong_full && state == POOL_PONG_FILL_PING) begin
                pool_pong_start <= 1'b1;
                pool_col_cnt <= 4'd0;
            end
            
            // Pooling counter
            if ((state == POOL_PING_FILL_PONG && ping_full) ||
                (state == POOL_PONG_FILL_PING && pong_full)) begin
                if (pool_col_cnt < 14) begin
                    pool_col_cnt <= pool_col_cnt + 1;
                    if (pool_col_cnt == 13) begin
                        pool_done <= 1'b1;
                    end
                end
            end
        end
    end
    
    // =====================================
    // 2x2 Maxpooling Pipeline
    // =====================================
    
    // Stage 1: Find max of each 2x1 column
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < 6; i = i + 1) begin
                for (j = 0; j < 2; j = j + 1) begin
                    max_stage1[i][j] <= 32'd0;
                end
            end
            max_valid_stage1 <= 1'b0;
        end else begin
            max_valid_stage1 <= 1'b0;
            
            if (state == POOL_PING_FILL_PONG && pool_col_cnt < 14) begin
                // Pool from ping buffer
                for (i = 0; i < 6; i = i + 1) begin
                    // Column 0 of 2x2 block
                    max_stage1[i][0] <= (ping_buffer[i][0][pool_col_cnt*2] > ping_buffer[i][1][pool_col_cnt*2]) ?
                                        ping_buffer[i][0][pool_col_cnt*2] : ping_buffer[i][1][pool_col_cnt*2];
                    // Column 1 of 2x2 block
                    max_stage1[i][1] <= (ping_buffer[i][0][pool_col_cnt*2+1] > ping_buffer[i][1][pool_col_cnt*2+1]) ?
                                        ping_buffer[i][0][pool_col_cnt*2+1] : ping_buffer[i][1][pool_col_cnt*2+1];
                end
                max_valid_stage1 <= 1'b1;
                
            end else if (state == POOL_PONG_FILL_PING && pool_col_cnt < 14) begin
                // Pool from pong buffer
                for (i = 0; i < 6; i = i + 1) begin
                    // Column 0 of 2x2 block
                    max_stage1[i][0] <= (pong_buffer[i][0][pool_col_cnt*2] > pong_buffer[i][1][pool_col_cnt*2]) ?
                                        pong_buffer[i][0][pool_col_cnt*2] : pong_buffer[i][1][pool_col_cnt*2];
                    // Column 1 of 2x2 block
                    max_stage1[i][1] <= (pong_buffer[i][0][pool_col_cnt*2+1] > pong_buffer[i][1][pool_col_cnt*2+1]) ?
                                        pong_buffer[i][0][pool_col_cnt*2+1] : pong_buffer[i][1][pool_col_cnt*2+1];
                end
                max_valid_stage1 <= 1'b1;
            end
        end
    end
    
    // Stage 2: Find max of 2 columns and apply ReLU + quantization
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < 6; i = i + 1) begin
                max_result[i] <= 8'd0;
            end
            max_valid_stage2 <= 1'b0;
        end else begin
            max_valid_stage2 <= 1'b0;
            
            if (max_valid_stage1) begin
                for (i = 0; i < 6; i = i + 1) begin
                    // Find max and apply ReLU + quantization
                    if (max_stage1[i][0] > max_stage1[i][1]) begin
                        // ReLU: if negative, output 0
                        if (max_stage1[i][0][31]) begin
                            max_result[i] <= 8'd0;
                        end else begin
                            // Simple quantization: take upper 8 bits
                            max_result[i] <= max_stage1[i][0][15:8];
                        end
                    end else begin
                        if (max_stage1[i][1][31]) begin
                            max_result[i] <= 8'd0;
                        end else begin
                            max_result[i] <= max_stage1[i][1][15:8];
                        end
                    end
                end
                max_valid_stage2 <= 1'b1;
            end
        end
    end
    
    // Output assignment
    always @(posedge clk) begin
        if (!rst_n) begin
            mp_valid <= 1'b0;
            mp_ch0_out <= 8'd0;
            mp_ch1_out <= 8'd0;
            mp_ch2_out <= 8'd0;
            mp_ch3_out <= 8'd0;
            mp_ch4_out <= 8'd0;
            mp_ch5_out <= 8'd0;
        end else begin
            mp_valid <= max_valid_stage2;
            if (max_valid_stage2) begin
                mp_ch0_out <= max_result[0];
                mp_ch1_out <= max_result[1];
                mp_ch2_out <= max_result[2];
                mp_ch3_out <= max_result[3];
                mp_ch4_out <= max_result[4];
                mp_ch5_out <= max_result[5];
            end
        end
    end
    
    // Debug output
    assign current_state = state;

endmodule