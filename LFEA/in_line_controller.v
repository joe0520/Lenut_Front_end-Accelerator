module in_line_controller (
    input                 clk,
    input                 reset_n,        // Active-low 리셋

    // --- 제어 신호 ---
    input                 i_start,        // 전체 동작 시작 신호
    output reg            o_done,         // 전체 동작 완료 신호

    // --- 데이터 입력 (Down-scaling 모듈로부터) ---
    input                 pixel_in_valid,
    input      [7:0]      pixel_in,

    // --- Conv PE 인터페이스 ---
    output reg            o_conv_valid,   // Conv PE로 윈도우 데이터 유효 신호
    input                 i_conv_ready,   // Conv PE의 ready 신호
    output reg            o_conv_row_start, // 새로운 출력 행 시작 신호
    output reg            o_conv_row_end,   // 출력 행 종료 신호
    
    // --- 5x5 윈도우 출력 (conv_pe_5x5로) ---
    output reg [7:0]      window_0_0, window_0_1, window_0_2, window_0_3, window_0_4,
    output reg [7:0]      window_1_0, window_1_1, window_1_2, window_1_3, window_1_4,
    output reg [7:0]      window_2_0, window_2_1, window_2_2, window_2_3, window_2_4,
    output reg [7:0]      window_3_0, window_3_1, window_3_2, window_3_3, window_3_4,
    output reg [7:0]      window_4_0, window_4_1, window_4_2, window_4_3, window_4_4,

    // --- 디버깅용 출력 ---
    output     [2:0]      o_read_pointer,
    output     [2:0]      o_write_pointer,
    output     [3:0]      o_current_state,
    output     [4:0]      o_window_col,
    output     [4:0]      o_output_row_cnt
);

    // --- FSM 상태 정의 ---
    localparam S_IDLE        = 4'd0;
    localparam S_INIT_FILL_0 = 4'd1;  // Line 0 채우기
    localparam S_INIT_FILL_1 = 4'd2;  // Line 1 채우기
    localparam S_INIT_FILL_2 = 4'd3;  // Line 2 채우기
    localparam S_INIT_FILL_3 = 4'd4;  // Line 3 채우기
    localparam S_INIT_FILL_4 = 4'd5;  // Line 4 채우기
    localparam S_PRE_FETCH   = 4'd6;  // Line 5 pre-fetch
    localparam S_CONV_WAIT   = 4'd7;  // Convolution 시작 대기
    localparam S_CONV_PROC   = 4'd8;  // Convolution 수행
    localparam S_ROW_DONE    = 4'd9;  // 한 행 완료, 다음 준비
    localparam S_FINISH      = 4'd10; // 종료

    // --- 내부 변수 선언 ---
    reg [3:0] state, next_state;
    reg [7:0] line_buffer [0:5][0:31]; // 6 lines x 32 columns
    reg [4:0] wr_col_cnt;               // 쓰기 컬럼 카운터 (0-31)
    reg [2:0] write_pointer;            // 쓰기 라인 포인터 (0~5)
    reg [2:0] read_pointer;             // 읽기 시작 라인 포인터 (0~5)
    reg [4:0] window_col;               // 윈도우 컬럼 위치 (0~27)
    reg [4:0] output_row_cnt;           // 출력 행 카운터 (0~27)
    reg [4:0] prefetch_row_cnt;         // Pre-fetch할 입력 행 번호
    reg       prefetch_done;            // Pre-fetch 완료 플래그
    reg       conv_processing;          // Convolution 처리 중 플래그

    integer i, j;

    // --- FSM 상태 천이 (조합 논리) ---
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (i_start) next_state = S_INIT_FILL_0;
            end
            
            S_INIT_FILL_0: begin
                if (pixel_in_valid && wr_col_cnt == 31) 
                    next_state = S_INIT_FILL_1;
            end
            
            S_INIT_FILL_1: begin
                if (pixel_in_valid && wr_col_cnt == 31) 
                    next_state = S_INIT_FILL_2;
            end
            
            S_INIT_FILL_2: begin
                if (pixel_in_valid && wr_col_cnt == 31) 
                    next_state = S_INIT_FILL_3;
            end
            
            S_INIT_FILL_3: begin
                if (pixel_in_valid && wr_col_cnt == 31) 
                    next_state = S_INIT_FILL_4;
            end
            
            S_INIT_FILL_4: begin
                if (pixel_in_valid && wr_col_cnt == 31) 
                    next_state = S_PRE_FETCH;
            end
            
            S_PRE_FETCH: begin
                if (pixel_in_valid && wr_col_cnt == 31) 
                    next_state = S_CONV_WAIT;
            end
            
            S_CONV_WAIT: begin
                if (i_conv_ready) 
                    next_state = S_CONV_PROC;
            end
            
            S_CONV_PROC: begin
                if (window_col == 27 && o_conv_valid && i_conv_ready) 
                    next_state = S_ROW_DONE;
            end
            
            S_ROW_DONE: begin
                if (output_row_cnt == 27) begin
                    next_state = S_FINISH;
                end else if (prefetch_done) begin
                    next_state = S_CONV_WAIT;
                end
            end
            
            S_FINISH: begin
                next_state = S_IDLE;
            end
        endcase
    end

    // --- FSM 상태 레지스터 ---
    always @(posedge clk) begin
        if (!reset_n) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end

    // --- 주요 제어 로직 ---
    always @(posedge clk) begin
        if (!reset_n) begin
            // 초기화
            o_done <= 1'b0;
            wr_col_cnt <= 5'd0;
            write_pointer <= 3'd0;
            read_pointer <= 3'd0;
            window_col <= 5'd0;
            output_row_cnt <= 5'd0;
            prefetch_row_cnt <= 5'd5;
            prefetch_done <= 1'b0;
            conv_processing <= 1'b0;
            o_conv_valid <= 1'b0;
            o_conv_row_start <= 1'b0;
            o_conv_row_end <= 1'b0;
            
            // Line buffer 초기화
            for (i = 0; i < 6; i = i + 1) begin
                for (j = 0; j < 32; j = j + 1) begin
                    line_buffer[i][j] <= 8'd0;
                end
            end
        end else begin
            // 기본값
            o_conv_row_start <= 1'b0;
            o_conv_row_end <= 1'b0;
            
            case (state)
                S_IDLE: begin
                    o_done <= 1'b0;
                    if (i_start) begin
                        write_pointer <= 3'd0;
                        read_pointer <= 3'd0;
                        wr_col_cnt <= 5'd0;
                        output_row_cnt <= 5'd0;
                        prefetch_row_cnt <= 5'd5;
                    end
                end

                S_INIT_FILL_0, S_INIT_FILL_1, S_INIT_FILL_2, 
                S_INIT_FILL_3, S_INIT_FILL_4: begin
                    if (pixel_in_valid) begin
                        line_buffer[write_pointer][wr_col_cnt] <= pixel_in;
                        if (wr_col_cnt == 31) begin
                            wr_col_cnt <= 5'd0;
                            write_pointer <= write_pointer + 1;
                        end else begin
                            wr_col_cnt <= wr_col_cnt + 1;
                        end
                    end
                end

                S_PRE_FETCH: begin
                    if (pixel_in_valid) begin
                        line_buffer[5][wr_col_cnt] <= pixel_in;
                        if (wr_col_cnt == 31) begin
                            wr_col_cnt <= 5'd0;
                            write_pointer <= 3'd0; // 다음은 line 0에 쓰기
                            prefetch_done <= 1'b1;
                        end else begin
                            wr_col_cnt <= wr_col_cnt + 1;
                        end
                    end
                end

                S_CONV_WAIT: begin
                    window_col <= 5'd0;
                    o_conv_row_start <= 1'b1;
                    conv_processing <= 1'b1;
                    prefetch_done <= 1'b0;
                end

                S_CONV_PROC: begin
                    // Convolution 윈도우 이동
                    if (i_conv_ready) begin
                        o_conv_valid <= 1'b1;
                        if (window_col == 27) begin
                            o_conv_row_end <= 1'b1;
                            conv_processing <= 1'b0;
                        end else begin
                            window_col <= window_col + 1;
                        end
                    end else begin
                        o_conv_valid <= 1'b0;
                    end
                    
                    // 병렬로 다음 줄 Pre-fetch
                    if (pixel_in_valid && !prefetch_done && output_row_cnt < 27) begin
                        line_buffer[write_pointer][wr_col_cnt] <= pixel_in;
                        if (wr_col_cnt == 31) begin
                            wr_col_cnt <= 5'd0;
                            prefetch_done <= 1'b1;
                        end else begin
                            wr_col_cnt <= wr_col_cnt + 1;
                        end
                    end
                end

                S_ROW_DONE: begin
                    o_conv_valid <= 1'b0;
                    if (output_row_cnt < 27) begin
                        // 포인터 순환
                        read_pointer <= (read_pointer == 5) ? 0 : read_pointer + 1;
                        write_pointer <= (write_pointer == 5) ? 0 : write_pointer + 1;
                        output_row_cnt <= output_row_cnt + 1;
                        prefetch_row_cnt <= prefetch_row_cnt + 1;
                    end else begin
                        output_row_cnt <= output_row_cnt + 1; // 28로 만들기
                    end
                end

                S_FINISH: begin
                    o_done <= 1'b1;
                    o_conv_valid <= 1'b0;
                end
            endcase
        end
    end

    // --- 5x5 윈도우 출력 (조합 논리) ---
    always @(*) begin
        if (state == S_CONV_PROC || state == S_CONV_WAIT) begin
            // Line 0
            window_0_0 = line_buffer[(read_pointer + 0) % 6][window_col + 0];
            window_0_1 = line_buffer[(read_pointer + 0) % 6][window_col + 1];
            window_0_2 = line_buffer[(read_pointer + 0) % 6][window_col + 2];
            window_0_3 = line_buffer[(read_pointer + 0) % 6][window_col + 3];
            window_0_4 = line_buffer[(read_pointer + 0) % 6][window_col + 4];
            
            // Line 1
            window_1_0 = line_buffer[(read_pointer + 1) % 6][window_col + 0];
            window_1_1 = line_buffer[(read_pointer + 1) % 6][window_col + 1];
            window_1_2 = line_buffer[(read_pointer + 1) % 6][window_col + 2];
            window_1_3 = line_buffer[(read_pointer + 1) % 6][window_col + 3];
            window_1_4 = line_buffer[(read_pointer + 1) % 6][window_col + 4];
            
            // Line 2
            window_2_0 = line_buffer[(read_pointer + 2) % 6][window_col + 0];
            window_2_1 = line_buffer[(read_pointer + 2) % 6][window_col + 1];
            window_2_2 = line_buffer[(read_pointer + 2) % 6][window_col + 2];
            window_2_3 = line_buffer[(read_pointer + 2) % 6][window_col + 3];
            window_2_4 = line_buffer[(read_pointer + 2) % 6][window_col + 4];
            
            // Line 3
            window_3_0 = line_buffer[(read_pointer + 3) % 6][window_col + 0];
            window_3_1 = line_buffer[(read_pointer + 3) % 6][window_col + 1];
            window_3_2 = line_buffer[(read_pointer + 3) % 6][window_col + 2];
            window_3_3 = line_buffer[(read_pointer + 3) % 6][window_col + 3];
            window_3_4 = line_buffer[(read_pointer + 3) % 6][window_col + 4];
            
            // Line 4
            window_4_0 = line_buffer[(read_pointer + 4) % 6][window_col + 0];
            window_4_1 = line_buffer[(read_pointer + 4) % 6][window_col + 1];
            window_4_2 = line_buffer[(read_pointer + 4) % 6][window_col + 2];
            window_4_3 = line_buffer[(read_pointer + 4) % 6][window_col + 3];
            window_4_4 = line_buffer[(read_pointer + 4) % 6][window_col + 4];
        end else begin
            // 초기값
            {window_0_0, window_0_1, window_0_2, window_0_3, window_0_4} = 40'd0;
            {window_1_0, window_1_1, window_1_2, window_1_3, window_1_4} = 40'd0;
            {window_2_0, window_2_1, window_2_2, window_2_3, window_2_4} = 40'd0;
            {window_3_0, window_3_1, window_3_2, window_3_3, window_3_4} = 40'd0;
            {window_4_0, window_4_1, window_4_2, window_4_3, window_4_4} = 40'd0;
        end
    end

    // --- 디버깅 출력 ---
    assign o_read_pointer = read_pointer;
    assign o_write_pointer = write_pointer;
    assign o_current_state = state;
    assign o_window_col = window_col;
    assign o_output_row_cnt = output_row_cnt;

endmodule