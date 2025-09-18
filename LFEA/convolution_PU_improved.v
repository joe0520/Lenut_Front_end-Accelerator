`timescale 1ns / 1ps

module conv_pe_5x5 (
    input           reset_n,
    input           clk,
    input           valid_in,      // Input data valid signal
    output reg      valid_out,     // Output data valid signal
    output [7:0]    pe_out,        // Quantized 8-bit output
    output [31:0]   sum_out,       // Full precision output (for debug)
    
    // Control signals
    input           relu_en,       // Enable ReLU activation
    input           quan_en,       // Enable quantization
    input [31:0]    psum,          // Partial sum for multi-channel accumulation
    
    // 5x5 input feature map window
    input [7:0] in_IF1,  in_IF2,  in_IF3,  in_IF4,  in_IF5,
    input [7:0] in_IF6,  in_IF7,  in_IF8,  in_IF9,  in_IF10,
    input [7:0] in_IF11, in_IF12, in_IF13, in_IF14, in_IF15,
    input [7:0] in_IF16, in_IF17, in_IF18, in_IF19, in_IF20,
    input [7:0] in_IF21, in_IF22, in_IF23, in_IF24, in_IF25,
    
    // 5x5 weight kernel (signed)
    input signed [7:0] in_W1,  in_W2,  in_W3,  in_W4,  in_W5,
    input signed [7:0] in_W6,  in_W7,  in_W8,  in_W9,  in_W10,
    input signed [7:0] in_W11, in_W12, in_W13, in_W14, in_W15,
    input signed [7:0] in_W16, in_W17, in_W18, in_W19, in_W20,
    input signed [7:0] in_W21, in_W22, in_W23, in_W24, in_W25
);

    integer i;
    
    // Pipeline registers
    reg signed [15:0] mul [0:24];      // Multiplication results
    reg signed [31:0] sum_stage1;      // First adder tree stage
    reg signed [31:0] sum_stage2;      // Second adder tree stage
    reg signed [31:0] sum_final;       // Final sum
    reg signed [31:0] relu_out;        // After ReLU
    
    // Valid signal pipeline
    reg valid_d1, valid_d2, valid_d3, valid_d4;
    
    // =====================================
    // Stage 1: Multiplication
    // =====================================
    always @(posedge clk) begin
        if (!reset_n) begin
            for (i = 0; i < 25; i = i + 1) 
                mul[i] <= 16'd0;
        end else if (valid_in) begin
            // Unsigned × Signed multiplication
            mul[0]  <= $signed({1'b0, in_IF1})  * in_W1;
            mul[1]  <= $signed({1'b0, in_IF2})  * in_W2;
            mul[2]  <= $signed({1'b0, in_IF3})  * in_W3;
            mul[3]  <= $signed({1'b0, in_IF4})  * in_W4;
            mul[4]  <= $signed({1'b0, in_IF5})  * in_W5;
            mul[5]  <= $signed({1'b0, in_IF6})  * in_W6;
            mul[6]  <= $signed({1'b0, in_IF7})  * in_W7;
            mul[7]  <= $signed({1'b0, in_IF8})  * in_W8;
            mul[8]  <= $signed({1'b0, in_IF9})  * in_W9;
            mul[9]  <= $signed({1'b0, in_IF10}) * in_W10;
            mul[10] <= $signed({1'b0, in_IF11}) * in_W11;
            mul[11] <= $signed({1'b0, in_IF12}) * in_W12;
            mul[12] <= $signed({1'b0, in_IF13}) * in_W13;
            mul[13] <= $signed({1'b0, in_IF14}) * in_W14;
            mul[14] <= $signed({1'b0, in_IF15}) * in_W15;
            mul[15] <= $signed({1'b0, in_IF16}) * in_W16;
            mul[16] <= $signed({1'b0, in_IF17}) * in_W17;
            mul[17] <= $signed({1'b0, in_IF18}) * in_W18;
            mul[18] <= $signed({1'b0, in_IF19}) * in_W19;
            mul[19] <= $signed({1'b0, in_IF20}) * in_W20;
            mul[20] <= $signed({1'b0, in_IF21}) * in_W21;
            mul[21] <= $signed({1'b0, in_IF22}) * in_W22;
            mul[22] <= $signed({1'b0, in_IF23}) * in_W23;
            mul[23] <= $signed({1'b0, in_IF24}) * in_W24;
            mul[24] <= $signed({1'b0, in_IF25}) * in_W25;
        end
    end
    
    // =====================================
    // Stage 2: First level addition
    // =====================================
    always @(posedge clk) begin
        if (!reset_n) begin
            sum_stage1 <= 32'd0;
            sum_stage2 <= 32'd0;
        end else begin
            // Add first 13 products
            sum_stage1 <= mul[0]  + mul[1]  + mul[2]  + mul[3]  + mul[4]  +
                         mul[5]  + mul[6]  + mul[7]  + mul[8]  + mul[9]  +
                         mul[10] + mul[11] + mul[12];
            
            // Add remaining 12 products + partial sum
            sum_stage2 <= mul[13] + mul[14] + mul[15] + mul[16] + mul[17] +
                         mul[18] + mul[19] + mul[20] + mul[21] + mul[22] +
                         mul[23] + mul[24] + psum;
        end
    end
    
    // =====================================
    // Stage 3: Final addition
    // =====================================
    always @(posedge clk) begin
        if (!reset_n) begin
            sum_final <= 32'd0;
        end else begin
            sum_final <= sum_stage1 + sum_stage2;
        end
    end
    
    // =====================================
    // Stage 4: ReLU activation
    // =====================================
    always @(posedge clk) begin
        if (!reset_n) begin
            relu_out <= 32'd0;
        end else begin
            if (relu_en) begin
                // ReLU: max(0, x)
                relu_out <= (sum_final[31]) ? 32'd0 : sum_final;
            end else begin
                relu_out <= sum_final;
            end
        end
    end
    
    // =====================================
    // Stage 5: Quantization
    // =====================================
    reg [7:0] quan_out;
    
    always @(posedge clk) begin
        if (!reset_n) begin
            quan_out <= 8'd0;
        end else begin
            if (quan_en) begin
                // Improved quantization with saturation and rounding
                if (relu_out[31]) begin
                    // Negative (shouldn't happen after ReLU, but safety check)
                    quan_out <= 8'd0;
                end else if (|relu_out[31:15]) begin
                    // Overflow - saturate to 255
                    quan_out <= 8'd255;
                end else begin
                    // Normal quantization with rounding
                    // Take bits [14:7] and add rounding from bit [6]
                    if (relu_out[14:7] == 8'hFF && relu_out[6]) begin
                        // Would overflow with rounding
                        quan_out <= 8'd255;
                    end else begin
                        // Normal rounding
                        quan_out <= relu_out[14:7] + {7'd0, relu_out[6]};
                    end
                end
            end else begin
                // No quantization - just take lower 8 bits (for debug)
                quan_out <= relu_out[7:0];
            end
        end
    end
    
    // =====================================
    // Valid signal pipeline
    // =====================================
    always @(posedge clk) begin
        if (!reset_n) begin
            valid_d1 <= 1'b0;
            valid_d2 <= 1'b0;
            valid_d3 <= 1'b0;
            valid_d4 <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            valid_d1 <= valid_in;
            valid_d2 <= valid_d1;
            valid_d3 <= valid_d2;
            valid_d4 <= valid_d3;
            valid_out <= valid_d4;
        end
    end
    
    // =====================================
    // Output assignments
    // =====================================
    assign pe_out = quan_out;
    assign sum_out = sum_final;

endmodule