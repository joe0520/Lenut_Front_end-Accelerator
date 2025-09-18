`timescale 1ns / 1ps

module c1_reg_controller (
    input clk,
    input rst_n,
    
    // Input from conv_5x5_pe (6 channels output)
    input conv_valid,
    input [7:0] conv_ch0_out,  // Quantized output from PE
    input [7:0] conv_ch1_out,
    input [7:0] conv_ch2_out,
    input [7:0] conv_ch3_out,
    input [7:0] conv_ch4_out,
    input [7:0] conv_ch5_out,
    
    // Output to maxpooling unit
    output reg c1_reg_valid,
    output reg [31:0] c1_reg_out_ch_0,  // 4 pixels packed [31:24][23:16][15:8][7:0]
    output reg [31:0] c1_reg_out_ch_1,
    output reg [31:0] c1_reg_out_ch_2,
    output reg [31:0] c1_reg_out_ch_3,
    output reg [31:0] c1_reg_out_ch_4,
    output reg [31:0] c1_reg_out_ch_5
);

    // State definitions
    localparam PING_READ = 2'b00;
    localparam PING_WRITE_PONG_READ = 2'b01;
    localparam PONG_READ = 2'b10;
    localparam PONG_WRITE_PING_READ = 2'b11;
    
    // Control signals
    reg push_flag;  // 0: write to ping, 1: write to pong
    reg [4:0] col_cnt;  // Column counter (0-27)
    reg row_cnt;  // Row counter within 2-row buffer (0-1)
    
    // Ping-pong buffers: [channel][row][column]
    // Each buffer stores 2 rows x 28 columns for 6 channels
    reg [7:0] ping_reg_0 [0:5][0:27];  // Row 0 of ping buffer
    reg [7:0] ping_reg_1 [0:5][0:27];  // Row 1 of ping buffer
    reg [7:0] pong_reg_0 [0:5][0:27];  // Row 0 of pong buffer
    reg [7:0] pong_reg_1 [0:5][0:27];  // Row 1 of pong buffer
    
    // State machine
    reg [1:0] current_state;
    reg [1:0] next_state;
    
    // Read counter for outputting 2x2 blocks
    reg [4:0] read_cnt;  // Counts 0,2,4,6...26 (step by 2)
    
    integer i, j;
    
    // =====================================
    // Buffer Write Logic
    // =====================================
    always @(posedge clk) begin
        if (!rst_n) begin
            // Clear all buffers
            for (i = 0; i < 6; i = i + 1) begin
                for (j = 0; j < 28; j = j + 1) begin
                    ping_reg_0[i][j] <= 8'd0;
                    ping_reg_1[i][j] <= 8'd0;
                    pong_reg_0[i][j] <= 8'd0;
                    pong_reg_1[i][j] <= 8'd0;
                end
            end
        end else if (conv_valid && !push_flag) begin
            // Write to ping buffer
            if (!row_cnt) begin
                ping_reg_0[0][col_cnt] <= conv_ch0_out;
                ping_reg_0[1][col_cnt] <= conv_ch1_out;
                ping_reg_0[2][col_cnt] <= conv_ch2_out;
                ping_reg_0[3][col_cnt] <= conv_ch3_out;
                ping_reg_0[4][col_cnt] <= conv_ch4_out;
                ping_reg_0[5][col_cnt] <= conv_ch5_out;
            end else begin
                ping_reg_1[0][col_cnt] <= conv_ch0_out;
                ping_reg_1[1][col_cnt] <= conv_ch1_out;
                ping_reg_1[2][col_cnt] <= conv_ch2_out;
                ping_reg_1[3][col_cnt] <= conv_ch3_out;
                ping_reg_1[4][col_cnt] <= conv_ch4_out;
                ping_reg_1[5][col_cnt] <= conv_ch5_out;
            end
        end else if (conv_valid && push_flag) begin
            // Write to pong buffer
            if (!row_cnt) begin
                pong_reg_0[0][col_cnt] <= conv_ch0_out;
                pong_reg_0[1][col_cnt] <= conv_ch1_out;
                pong_reg_0[2][col_cnt] <= conv_ch2_out;
                pong_reg_0[3][col_cnt] <= conv_ch3_out;
                pong_reg_0[4][col_cnt] <= conv_ch4_out;
                pong_reg_0[5][col_cnt] <= conv_ch5_out;
            end else begin
                pong_reg_1[0][col_cnt] <= conv_ch0_out;
                pong_reg_1[1][col_cnt] <= conv_ch1_out;
                pong_reg_1[2][col_cnt] <= conv_ch2_out;
                pong_reg_1[3][col_cnt] <= conv_ch3_out;
                pong_reg_1[4][col_cnt] <= conv_ch4_out;
                pong_reg_1[5][col_cnt] <= conv_ch5_out;
            end
        end
    end
    
    // =====================================
    // Counter Management
    // =====================================
    always @(posedge clk) begin
        if (!rst_n) begin
            col_cnt <= 5'd0;
            row_cnt <= 1'b0;
            push_flag <= 1'b0;
        end else if (conv_valid) begin
            // Column counter: 0-27
            if (col_cnt == 27) begin
                col_cnt <= 5'd0;
                
                // Row counter toggles between 0 and 1
                row_cnt <= ~row_cnt;
                
                // Switch buffers after filling 2 rows
                if (row_cnt == 1) begin
                    push_flag <= ~push_flag;
                end
            end else begin
                col_cnt <= col_cnt + 1;
            end
        end
    end
    
    // =====================================
    // State Machine
    // =====================================
    always @(posedge clk) begin
        if (!rst_n) begin
            current_state <= PING_READ;
            read_cnt <= 5'd0;
        end else begin
            current_state <= next_state;
            
            // Read counter management (0, 2, 4, ... 26)
            if ((current_state == PING_WRITE_PONG_READ) || 
                (current_state == PONG_WRITE_PING_READ)) begin
                if (read_cnt == 26) begin
                    read_cnt <= 5'd0;
                end else begin
                    read_cnt <= read_cnt + 2;
                end
            end
        end
    end
    
    // Next state logic
    always @(*) begin
        next_state = current_state;
        case (current_state)
            PING_READ: begin
                // Wait for ping buffer to be filled (2 rows)
                if (conv_valid && row_cnt && (col_cnt == 27)) begin
                    next_state = PING_WRITE_PONG_READ;
                end
            end
            
            PING_WRITE_PONG_READ: begin
                // Output from ping while filling pong
                if (read_cnt == 26) begin
                    next_state = PONG_READ;
                end
            end
            
            PONG_READ: begin
                // Wait for pong buffer to be filled
                if (conv_valid && row_cnt && (col_cnt == 27)) begin
                    next_state = PONG_WRITE_PING_READ;
                end
            end
            
            PONG_WRITE_PING_READ: begin
                // Output from pong while filling ping
                if (read_cnt == 26) begin
                    next_state = PING_READ;
                end
            end
        endcase
    end
    
    // =====================================
    // Output Generation - 2x2 blocks for maxpooling
    // =====================================
    always @(posedge clk) begin
        if (!rst_n) begin
            c1_reg_valid <= 1'b0;
            c1_reg_out_ch_0 <= 32'd0;
            c1_reg_out_ch_1 <= 32'd0;
            c1_reg_out_ch_2 <= 32'd0;
            c1_reg_out_ch_3 <= 32'd0;
            c1_reg_out_ch_4 <= 32'd0;
            c1_reg_out_ch_5 <= 32'd0;
        end else if (current_state == PING_WRITE_PONG_READ) begin
            // Read from ping buffer - output 2x2 block
            c1_reg_valid <= 1'b1;
            // Pack 2x2 block: [row0_col0][row0_col1][row1_col0][row1_col1]
            c1_reg_out_ch_0 <= {ping_reg_0[0][read_cnt], ping_reg_0[0][read_cnt+1], 
                                 ping_reg_1[0][read_cnt], ping_reg_1[0][read_cnt+1]};
            c1_reg_out_ch_1 <= {ping_reg_0[1][read_cnt], ping_reg_0[1][read_cnt+1], 
                                 ping_reg_1[1][read_cnt], ping_reg_1[1][read_cnt+1]};
            c1_reg_out_ch_2 <= {ping_reg_0[2][read_cnt], ping_reg_0[2][read_cnt+1], 
                                 ping_reg_1[2][read_cnt], ping_reg_1[2][read_cnt+1]};
            c1_reg_out_ch_3 <= {ping_reg_0[3][read_cnt], ping_reg_0[3][read_cnt+1], 
                                 ping_reg_1[3][read_cnt], ping_reg_1[3][read_cnt+1]};
            c1_reg_out_ch_4 <= {ping_reg_0[4][read_cnt], ping_reg_0[4][read_cnt+1], 
                                 ping_reg_1[4][read_cnt], ping_reg_1[4][read_cnt+1]};
            c1_reg_out_ch_5 <= {ping_reg_0[5][read_cnt], ping_reg_0[5][read_cnt+1], 
                                 ping_reg_1[5][read_cnt], ping_reg_1[5][read_cnt+1]};
        end else if (current_state == PONG_WRITE_PING_READ) begin
            // Read from pong buffer - output 2x2 block
            c1_reg_valid <= 1'b1;
            c1_reg_out_ch_0 <= {pong_reg_0[0][read_cnt], pong_reg_0[0][read_cnt+1], 
                                 pong_reg_1[0][read_cnt], pong_reg_1[0][read_cnt+1]};
            c1_reg_out_ch_1 <= {pong_reg_0[1][read_cnt], pong_reg_0[1][read_cnt+1], 
                                 pong_reg_1[1][read_cnt], pong_reg_1[1][read_cnt+1]};
            c1_reg_out_ch_2 <= {pong_reg_0[2][read_cnt], pong_reg_0[2][read_cnt+1], 
                                 pong_reg_1[2][read_cnt], pong_reg_1[2][read_cnt+1]};
            c1_reg_out_ch_3 <= {pong_reg_0[3][read_cnt], pong_reg_0[3][read_cnt+1], 
                                 pong_reg_1[3][read_cnt], pong_reg_1[3][read_cnt+1]};
            c1_reg_out_ch_4 <= {pong_reg_0[4][read_cnt], pong_reg_0[4][read_cnt+1], 
                                 pong_reg_1[4][read_cnt], pong_reg_1[4][read_cnt+1]};
            c1_reg_out_ch_5 <= {pong_reg_0[5][read_cnt], pong_reg_0[5][read_cnt+1], 
                                 pong_reg_1[5][read_cnt], pong_reg_1[5][read_cnt+1]};
        end else begin
            c1_reg_valid <= 1'b0;
        end
    end

endmodule