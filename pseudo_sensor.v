module pseudo_sensor (
		    input wire	      clk, // 100 MHz input clock
		    input wire	      rstn, // Active-low asynchronous reset,
		    input wire        start, // 08.24 modify
		    output wire	      p_clk,
		    output wire	      p_vsync, // Vertical sync pulse
		    output wire	      p_hsync, // Horizontal sync pulse
		    output wire [7:0] p_data,
		    output reg [3:0]  image_num
		    );
   //YOUR PATH
   parameter coe_path = "C:/Users/khmga/Desktop/down_scale/pseudo_image";
   
   // Parameters
   parameter H_ACTIVE = 640;
   parameter H_BLANK  = 360;
   parameter H_TOTAL  = H_ACTIVE + H_BLANK; // 1000
   
   parameter V_ACTIVE = 480;
   parameter V_BLANK  = 2853;
   parameter V_TOTAL  = V_ACTIVE + V_BLANK; // 3333

   parameter IMAGE_MAX_NUM = 10;

   reg 		 vsync;
   reg 		 vsync_d;
   wire 	 vsync_rise;
   wire 	 vsync_fall;

   reg	     hsync;
   reg	     hsync_d;
   wire	     hsync_rise;
   wire	     hsync_fall;

   assign p_clk = clk;
   assign p_vsync = vsync_d;
   assign p_hsync = hsync_d;
   assign p_data = (ena[0]) ? dout_0 :
		   (ena[1]) ? dout_1 :
		   (ena[2]) ? dout_2 : 
		   (ena[3]) ? dout_3 : 
		   (ena[4]) ? dout_4 : 
		   (ena[5]) ? dout_5 : 
		   (ena[6]) ? dout_6 : 
		   (ena[7]) ? dout_7 : 
		   (ena[8]) ? dout_8 : 
		   (ena[9]) ? dout_9 : 0;
   
   // Counters
   reg [9:0] 		       h_cnt;
   reg [11:0] 		       v_cnt;

   wire [IMAGE_MAX_NUM-1:0]    ena;
   reg [18:0]		       addra;
   wire [7:0]		       dout_0,dout_1,dout_2,dout_3,dout_4,dout_5,dout_6,dout_7,dout_8,dout_9;
   
   // ****if you have to add start control, use this. End at line 89 ****

   
   // Horizontal counter
   always @(posedge clk or negedge rstn) begin
      if (!rstn)
        h_cnt <= 0;
      else if (h_cnt == H_TOTAL - 1)
        h_cnt <= 0;
      else if(start)
        h_cnt <= h_cnt + 1;
   end
   
   // Vertical counter
   always @(posedge clk or negedge rstn) begin
      if (!rstn)
        v_cnt <= 0;
      else if (h_cnt == H_TOTAL - 1) begin
         if (v_cnt == V_TOTAL - 1)
           v_cnt <= 0;
         else if(start)
           v_cnt <= v_cnt + 1;
      end
   end
   //****End modify****
   
   /*
   // Horizontal counter
   always @(posedge clk or negedge rstn) begin
      if (!rstn)
        h_cnt <= 0;
      else if (h_cnt == H_TOTAL - 1)
        h_cnt <= 0;
      else
        h_cnt <= h_cnt + 1;
   end
   
   // Vertical counter
   always @(posedge clk or negedge rstn) begin
      if (!rstn)
        v_cnt <= 0;
      else if (h_cnt == H_TOTAL - 1) begin
         if (v_cnt == V_TOTAL - 1)
           v_cnt <= 0;
         else
           v_cnt <= v_cnt + 1;
      end
   end
   */

     // HSYNC: active-low during blanking
   always @(posedge clk or negedge rstn) begin
      if (!rstn)
        hsync <= 0;
      else
        hsync <= ((h_cnt >= H_BLANK/2) && (h_cnt < H_ACTIVE + H_BLANK/2));
   end
   
   always @(posedge clk or negedge rstn) begin
      if (!rstn)
	vsync <= 0;
      else begin
	 vsync <= (v_cnt < V_ACTIVE);
      end
   end

   always@(posedge clk or negedge rstn) begin
      if(!rstn) begin
	 vsync_d <= 'd0;
	 hsync_d <= 'd0;
      end
      else begin
	 vsync_d <= vsync;
	 hsync_d <= hsync;
      end
   end

   assign vsync_rise = (vsync && !vsync_d);
   assign vsync_fall = (!vsync && vsync_d);

   always@(posedge clk or negedge rstn) begin
      if(!rstn)
	image_num <= IMAGE_MAX_NUM-1;
      else begin
	 if(vsync_rise) begin
	   if(image_num == (IMAGE_MAX_NUM - 1))
	     image_num <= 'd0;
	   else
	     image_num <= image_num + 1'd1;
	 end
      end
   end // always@ (posedge clk or ngedge rstn)

   assign ena = (1 << image_num);
   
   always@(posedge clk or negedge rstn) begin
      if(!rstn)
	addra <= 'd0;
      else begin
	 if(!vsync)
	   addra <= 'd0;
	 else if(hsync)
	   addra <= addra + 1'd1;
      end
   end
 
   xilinx_true_dual_port_no_change_2_clock_ram #(
      .RAM_WIDTH(8),
      .RAM_DEPTH(307200),
      .RAM_PERFORMANCE("LOW_LATENCY"),
      .INIT_FILE({coe_path,"/pseudo_image_0.coe"})
   ) pseudo_image_0 (
                  .clka(clk),    // input wire clka
                  .ena(ena[0]),      // input wire ena
                  .addra(addra),  // input wire [18 : 0] addra
                  .douta(dout_0)  // output wire [7 : 0] douta
                   );

   xilinx_true_dual_port_no_change_2_clock_ram #(
      .RAM_WIDTH(8),
      .RAM_DEPTH(307200),
      .RAM_PERFORMANCE("LOW_LATENCY"),
      .INIT_FILE({coe_path,"/pseudo_image_1.coe"})
   ) pseudo_image_1 (
				  .clka(clk),    // input wire clka
				  .ena(ena[1]),      // input wire ena
				  .addra(addra),  // input wire [18 : 0] addra
				  .douta(dout_1)  // output wire [7 : 0] douta
				  );
    
   xilinx_true_dual_port_no_change_2_clock_ram #(
      .RAM_WIDTH(8),
      .RAM_DEPTH(307200),
      .RAM_PERFORMANCE("LOW_LATENCY"),
      .INIT_FILE({coe_path,"/pseudo_image_2.coe"})
   ) pseudo_image_2 (
				  .clka(clk),    // input wire clka
				  .ena(ena[2]),      // input wire ena
				  .addra(addra),  // input wire [18 : 0] addra
				  .douta(dout_2)  // output wire [7 : 0] douta
				  );

   xilinx_true_dual_port_no_change_2_clock_ram #(
      .RAM_WIDTH(8),
      .RAM_DEPTH(307200),
      .RAM_PERFORMANCE("LOW_LATENCY"),
      .INIT_FILE({coe_path,"/pseudo_image_3.coe"})
   ) pseudo_image_3 (
				  .clka(clk),    // input wire clka
				  .ena(ena[3]),      // input wire ena
				  .addra(addra),  // input wire [18 : 0] addra
				  .douta(dout_3)  // output wire [7 : 0] douta
				  );

   xilinx_true_dual_port_no_change_2_clock_ram #(
      .RAM_WIDTH(8),
      .RAM_DEPTH(307200),
      .RAM_PERFORMANCE("LOW_LATENCY"),
      .INIT_FILE({coe_path,"/pseudo_image_4.coe"})
   ) pseudo_image_4 (
				  .clka(clk),    // input wire clka
				  .ena(ena[4]),      // input wire ena
				  .addra(addra),  // input wire [18 : 0] addra
				  .douta(dout_4)  // output wire [7 : 0] douta
				  );

   xilinx_true_dual_port_no_change_2_clock_ram #(
      .RAM_WIDTH(8),
      .RAM_DEPTH(307200),
      .RAM_PERFORMANCE("LOW_LATENCY"),
      .INIT_FILE({coe_path,"/pseudo_image_5.coe"})
   ) pseudo_image_5 (
				  .clka(clk),    // input wire clka
				  .ena(ena[5]),      // input wire ena
				  .addra(addra),  // input wire [18 : 0] addra
				  .douta(dout_5)  // output wire [7 : 0] douta
				  );

   xilinx_true_dual_port_no_change_2_clock_ram #(
      .RAM_WIDTH(8),
      .RAM_DEPTH(307200),
      .RAM_PERFORMANCE("LOW_LATENCY"),
      .INIT_FILE({coe_path,"/pseudo_image_6.coe"})
   ) pseudo_image_6 (
				  .clka(clk),    // input wire clka
				  .ena(ena[6]),      // input wire ena
				  .addra(addra),  // input wire [18 : 0] addra
				  .douta(dout_6)  // output wire [7 : 0] douta
				  );

   xilinx_true_dual_port_no_change_2_clock_ram #(
      .RAM_WIDTH(8),
      .RAM_DEPTH(307200),
      .RAM_PERFORMANCE("LOW_LATENCY"),
      .INIT_FILE({coe_path,"/pseudo_image_7.coe"})
   ) pseudo_image_7 (
				  .clka(clk),    // input wire clka
				  .ena(ena[7]),      // input wire ena
				  .addra(addra),  // input wire [18 : 0] addra
				  .douta(dout_7)  // output wire [7 : 0] douta
				  );

   xilinx_true_dual_port_no_change_2_clock_ram #(
      .RAM_WIDTH(8),
      .RAM_DEPTH(307200),
      .RAM_PERFORMANCE("LOW_LATENCY"),
      .INIT_FILE({coe_path,"/pseudo_image_8.coe"})
   ) pseudo_image_8 (
				  .clka(clk),    // input wire clka
				  .ena(ena[8]),      // input wire ena
				  .addra(addra),  // input wire [18 : 0] addra
				  .douta(dout_8)  // output wire [7 : 0] douta
				  );

   xilinx_true_dual_port_no_change_2_clock_ram #(
      .RAM_WIDTH(8),
      .RAM_DEPTH(307200),
      .RAM_PERFORMANCE("LOW_LATENCY"),
      .INIT_FILE({coe_path,"/pseudo_image_9.coe"})
   ) pseudo_image_9 (
				  .clka(clk),    // input wire clka
				  .ena(ena[9]),      // input wire ena
				  .addra(addra),  // input wire [18 : 0] addra
				  .douta(dout_9)  // output wire [7 : 0] douta
				  );
			   
endmodule
