module EEE_IMGPROC(
	// global clock & reset
	clk,
	reset_n,
	
	// mm slave
	s_chipselect,
	s_read,
	s_write,
	s_readdata,
	s_writedata,
	s_address,

	// stream sink
	sink_data,
	sink_valid,
	sink_ready,
	sink_sop,
	sink_eop,
	
	// streaming source
	source_data,
	source_valid,
	source_ready,
	source_sop,
	source_eop,
	
	// conduit
	mode
	
);


// global clock & reset
input	clk;
input	reset_n;

// mm slave
input							s_chipselect;
input							s_read;
input							s_write;
output	reg	[31:0]	s_readdata;
input	[31:0]				s_writedata;
input	[2:0]					s_address;


// streaming sink
input	[23:0]            	sink_data;
input								sink_valid;
output							sink_ready;
input								sink_sop;
input								sink_eop;

// streaming source
output	[23:0]			  	   source_data;
output								source_valid;
input									source_ready;
output								source_sop;
output								source_eop;

// conduit export
input                         mode;

////////////////////////////////////////////////////////////////////////
//
parameter IMAGE_W = 11'd640;
parameter IMAGE_H = 11'd480;
parameter MESSAGE_BUF_MAX = 256;
parameter COLOR_NUMBER = 6;
parameter MSG_INTERVAL = 12;
parameter BB_COL_DEFAULT = 24'h00ff00;
parameter CENTER_COL_DEFAULT=24'h0000ff;

wire [7:0]   red, green, blue, grey,red_filter_out, green_filter_out, blue_filter_out;
wire [7:0]   red_out, green_out, blue_out;

wire         sop, eop, in_valid, out_ready;
////////////////////////////////////////////////////////////////////////

// Detect red areas
wire color_detect;

wire [2:0] detected_color;
// wire [8:0]h;
// wire [7:0]s;
// wire [7:0]v;
// assign blue_detect = (h>=9'd200 & h<=9'd250)&s>=8'd43&v>=8'd80;

assign color_detect=detected_color==debug_color;
// Find boundary of cursor box

// Highlight detected areas
wire [23:0] red_high;
// assign grey = green_filter_out[7:1] + red_filter_out[7:2] + blue_filter_out[7:2]; //Grey = green/2 + red/4 + blue/4
assign grey = green[7:1] + red[7:2] + blue[7:2]; //Grey = green/2 + red/4 + blue/4
assign red_high  =  color_detect ? {8'hff, 8'h0, 8'h0} : {grey, grey, grey};

// Show bounding box
wire [23:0] new_image;
wire bb_active;
wire center_active;
assign bb_active = (x == left[debug_color]) | (x == right[debug_color]) | (y == top[debug_color]) | (y == bottom[debug_color]) ;
assign center_active= (x==center_x[debug_color]) | (y==center_y[debug_color]);

assign new_image = is_color_valid[debug_color] ? (center_active ? center_col : (bb_active ? bb_col : red_high)) : red_high;

// Switch output pixels depending on mode switch
// Don't modify the start-of-packet word - it's a packet discriptor
// Don't modify data in non-video packets
assign {red_out, green_out, blue_out} =new_image;

// assign {red_out, green_out, blue_out} =(mode & ~sop & packet_video) ?  new_image: {red,green,blue};

//Count valid pixels to tget the image coordinates. Reset and detect packet type on Start of Packet.
reg [9:0] x, y;
integer i=0;
reg packet_video;
always@(posedge clk) begin
	if (sop) begin
		filter_rst<=1;
		x <= 10'h0;
		y <= 10'h0;
		packet_video <= (blue[3:0] == 3'h0);
	end
	else if (in_valid) begin
		if (x == IMAGE_W-1) begin
			x <= 10'h0;
			y <= y + 10'h1;
			filter_rst<=1;
			wc_rst<=1;
		end
		else begin
			x <= x + 10'h1;
			filter_rst<=0;
			wc_rst<=0;
		end
	end
end

//Find first and last red pixels



always@(posedge clk) begin
	// if (color_detect & in_valid) begin	//Update bounds when the pixel is red
	// 	if (x < x_min) x_min <= x;
	// 	if (x > x_max) x_max <= x;
	// 	if (y < y_min) y_min <= y;
	// 	y_max <= y;
	// 	x_increment<=x_increment+x;
	// 	y_increment<=y_increment+y;
	// 	xy_cnt<=xy_cnt+1;
	// end
	// if (sop & in_valid) begin	//Reset bounds on start of packet
	// 	x_min <= IMAGE_W-10'h1;
	// 	x_max <= 0;
	// 	y_min <= IMAGE_H-10'h1;
	// 	y_max <= 0;
	// 	x_increment<=0;
	// 	y_increment<=0;
	// 	xy_cnt<=0;
	// end

// if (color_detect & in_valid & detected_color!=UNKNOWN_CODE) begin	//Update bounds when the pixel is red
// 		if (x < x_min[detected_color]) x_min[detected_color] <= x;
// 		if (x > x_max[detected_color]) x_max[detected_color] <= x;
// 		if (y < y_min[detected_color]) y_min[detected_color] <= y;
// 		if (y > y_max[detected_color]) y_max[detected_color] <= y;
// 		x_increment[detected_color]<=x_increment[detected_color]+x;
// 		y_increment[detected_color]<=y_increment[detected_color]+y;
// 		xy_cnt[detected_color]<=xy_cnt[detected_color]+1;
// 	end
	if (detected_color==BLUE_CODE & in_valid & detected_color!=UNKNOWN_CODE) begin	//Update bounds when the pixel is red
		if (x < x_min[BLUE_CODE]) x_min[BLUE_CODE] <= x;
		if (x > x_max[BLUE_CODE]) x_max[BLUE_CODE] <= x;
		if (y < y_min[BLUE_CODE]) y_min[BLUE_CODE] <= y;
		y_max[BLUE_CODE] <= y;
		x_increment[BLUE_CODE]<=x_increment[BLUE_CODE]+x;
		y_increment[BLUE_CODE]<=y_increment[BLUE_CODE]+y;
		xy_cnt[BLUE_CODE]<=xy_cnt[BLUE_CODE]+1;
	end
	else if (detected_color==RED_CODE & in_valid & detected_color!=UNKNOWN_CODE) begin	//Update bounds when the pixel is red
		if (x < x_min[RED_CODE]) x_min[RED_CODE] <= x;
		if (x > x_max[RED_CODE]) x_max[RED_CODE] <= x;
		if (y < y_min[RED_CODE]) y_min[RED_CODE] <= y;
		y_max[RED_CODE] <= y;
		x_increment[RED_CODE]<=x_increment[RED_CODE]+x;
		y_increment[RED_CODE]<=y_increment[RED_CODE]+y;
		xy_cnt[RED_CODE]<=xy_cnt[RED_CODE]+1;
	end
	else if (detected_color==YELLOW_CODE & in_valid & detected_color!=UNKNOWN_CODE) begin	//Update bounds when the pixel is red
		if (x < x_min[YELLOW_CODE]) x_min[YELLOW_CODE] <= x;
		if (x > x_max[YELLOW_CODE]) x_max[YELLOW_CODE] <= x;
		if (y < y_min[YELLOW_CODE]) y_min[YELLOW_CODE] <= y;
		y_max[YELLOW_CODE] <= y;
		x_increment[YELLOW_CODE]<=x_increment[YELLOW_CODE]+x;
		y_increment[YELLOW_CODE]<=y_increment[YELLOW_CODE]+y;
		xy_cnt[YELLOW_CODE]<=xy_cnt[YELLOW_CODE]+1;
	end
		else if (detected_color==PURPLE_CODE & in_valid & detected_color!=UNKNOWN_CODE) begin	//Update bounds when the pixel is red
		if (x < x_min[PURPLE_CODE]) x_min[PURPLE_CODE] <= x;
		if (x > x_max[PURPLE_CODE]) x_max[PURPLE_CODE] <= x;
		if (y < y_min[PURPLE_CODE]) y_min[PURPLE_CODE] <= y;
		y_max[PURPLE_CODE] <= y;
		x_increment[PURPLE_CODE]<=x_increment[PURPLE_CODE]+x;
		y_increment[PURPLE_CODE]<=y_increment[PURPLE_CODE]+y;
		xy_cnt[PURPLE_CODE]<=xy_cnt[PURPLE_CODE]+1;
	end
		else if (detected_color==WHITE_CODE & in_valid & detected_color!=WHITE_CODE) begin	//Update bounds when the pixel is red
		if (x < x_min[WHITE_CODE]) x_min[WHITE_CODE] <= x;
		if (x > x_max[WHITE_CODE]) x_max[WHITE_CODE] <= x;
		if (y < y_min[WHITE_CODE]) y_min[WHITE_CODE] <= y;
		y_max[WHITE_CODE] <= y;
		x_increment[WHITE_CODE]<=x_increment[WHITE_CODE]+x;
		y_increment[WHITE_CODE]<=y_increment[WHITE_CODE]+y;
		xy_cnt[WHITE_CODE]<=xy_cnt[WHITE_CODE]+1;
	end
		else if (detected_color==BLACK_CODE & in_valid & detected_color!=UNKNOWN_CODE) begin	//Update bounds when the pixel is red
		if (x < x_min[BLACK_CODE]) x_min[BLACK_CODE] <= x;
		if (x > x_max[BLACK_CODE]) x_max[BLACK_CODE] <= x;
		if (y < y_min[BLACK_CODE]) y_min[BLACK_CODE] <= y;
		y_max[BLACK_CODE] <= y;
		x_increment[BLACK_CODE]<=x_increment[BLACK_CODE]+x;
		y_increment[BLACK_CODE]<=y_increment[BLACK_CODE]+y;
		xy_cnt[BLACK_CODE]<=xy_cnt[BLACK_CODE]+1;
	end

	// else if(detected_color>=BLACK_CODE&detected_color<=PURPLE_CODE&in_valid & detected_color!=UNKNOWN_CODE) begin
	// 	if (x < x_min[detected_color]) x_min[detected_color] <= x;
	// 	if (x > x_max[detected_color]) x_max[detected_color] <= x;
	// 	if (y < y_min[detected_color]) y_min[detected_color] <= y;
	// 	y_max[detected_color] <= y;
	// 	x_increment[detected_color]<=x_increment[detected_color]+x;
	// 	y_increment[detected_color]<=y_increment[detected_color]+y;
	// 	xy_cnt[detected_color]<=xy_cnt[detected_color]+1;
	// end
	if (sop & in_valid) begin	//Reset bounds on start of packet
		for(i=0;i<COLOR_NUMBER;i=i+1) begin
				x_min[i] <= IMAGE_W-10'h1;
				x_max[i] <= 0;
				y_min[i] <= IMAGE_H-10'h1;
				y_max[i] <= 0;
				x_increment[i]<=0;
				y_increment[i]<=0;
				xy_cnt[i]<=0;
		end
	end

end

//Process bounding box at the end of the frame.



// reg [9:0] x_min, y_min, x_max, y_max;
// reg [9:0] left, right, top, bottom,center_x,center_y;
// reg [18:0] xy_cnt;
// reg [31:0] x_increment,y_increment;

reg [9:0] x_min[0:COLOR_NUMBER], y_min[0:COLOR_NUMBER], x_max[0:COLOR_NUMBER], y_max[0:COLOR_NUMBER];
reg [9:0] left[0:COLOR_NUMBER], right[0:COLOR_NUMBER], top[0:COLOR_NUMBER], bottom[0:COLOR_NUMBER],center_x[0:COLOR_NUMBER],center_y[0:COLOR_NUMBER];
// reg [18:0] xy_cnt[0:COLOR_NUMBER];
// reg [31:0] x_increment[0:COLOR_NUMBER],y_increment[0:COLOR_NUMBER]; 
reg [24:0] xy_cnt[0:COLOR_NUMBER];
reg [37:0] x_increment[0:COLOR_NUMBER],y_increment[0:COLOR_NUMBER]; 

reg [7:0] is_color_valid=8'b11111111;

initial begin
	for(i=0;i<COLOR_NUMBER;i=i+1) begin
				x_min[i] <= IMAGE_W-10'h1;
				x_max[i] <= 0;
				y_min[i] <= IMAGE_H-10'h1;
				y_max[i] <= 0;
				x_increment[i]<=0;
				y_increment[i]<=0;
				xy_cnt[i]<=0;
		end
end

always@(posedge clk) begin
	if (eop & in_valid & packet_video) begin  //Ignore non-video packets
		//Latch edges for display overlay on next frame
			for(i=0;i<COLOR_NUMBER;i=i+1) begin
				if(xy_cnt[i]<=200) begin
					is_color_valid[i]<=1'b0;
					left[i] <= 0;
					right[i] <= IMAGE_W-10'h1;
					top[i] <= 0;
					bottom[i] <= IMAGE_H-10'h1;
					center_x[i]<=0;
					center_y[i]<=0;
				end
			
				else begin
					is_color_valid[i]<=1'b1;
					left[i] <= x_min[i];
					right[i] <= x_max[i];
					top[i] <= y_min[i];
					bottom[i] <= y_max[i];
					center_x[i]<=x_increment[i]/xy_cnt[i];
					center_y[i]<=y_increment[i]/xy_cnt[i];
				end
		end


		
		
		//Start message writer FSM once every MSG_INTERVAL frames, if there is room in the FIFO
		frame_count <= frame_count - 1;
		
		if (frame_count == 0 && msg_buf_size < MESSAGE_BUF_MAX - 3) begin
			msg_state <= 1;
			frame_count <= MSG_INTERVAL-1;
		end
	end
	
	//Cycle through message writer states once started

	if(msg_color<=PURPLE_CODE & msg_state>=3) begin
			if(is_color_valid[msg_color+1]&msg_color<=PURPLE_CODE-1) begin
				msg_color <= msg_color + 1;
										msg_state <= 2;
			end
			else if(is_color_valid[msg_color+2]&msg_color<=PURPLE_CODE-2) begin
				msg_color <= msg_color + 2;
					msg_state <= 2;
			end
			else if(is_color_valid[msg_color+3]&msg_color<=PURPLE_CODE-3) begin
				msg_color <= msg_color + 3;
					msg_state <= 2;
			end
			else if(is_color_valid[msg_color+4]&msg_color<=PURPLE_CODE-4) begin
				msg_color <= msg_color + 4;
					msg_state <= 2;
			end
			else if(is_color_valid[msg_color+5]&msg_color<=PURPLE_CODE-5) begin
				msg_color <= msg_color + 5;
						msg_state <= 2;
			end
			else begin
					msg_state <= 0;
					msg_color <= 0;
			end
	end
	else if(msg_state>=3)  begin
		msg_state <= 0;
		msg_color <= 0;
	end
	else if (msg_state != 0) begin
		 msg_state <= msg_state + 1;
	end

end
reg [3:0] msg_state;
reg [2:0] msg_color=0;
reg [7:0] frame_count;

//Generate output messages for CPU
reg [31:0] msg_buf_in; 
wire [31:0] msg_buf_out;
reg msg_buf_wr;
wire msg_buf_rd, msg_buf_flush;
wire [7:0] msg_buf_size;
wire msg_buf_empty;

parameter BLACK_CODE = 3'b000;
parameter WHITE_CODE = 3'b001;
parameter RED_CODE = 3'b010;
parameter BLUE_CODE = 3'b011;
parameter YELLOW_CODE = 3'b100;
parameter PURPLE_CODE = 3'b101;
parameter UNKNOWN_CODE = 3'b110;

wire [2:0] debug_color;
// assign debug_color=mode?BLUE_CODE : PURPLE_CODE;
assign debug_color=BLUE_CODE;
`define RED_BOX_MSG_ID "RBB"


always@(*) begin	//Write words to FIFO as state machine advances
	case(msg_state)
		0: begin
			msg_buf_in = 32'b0;
			msg_buf_wr = 1'b0;
		end
		1: begin
			msg_buf_in = 32'b11111111111111111111111111111111;	//Message ID
			msg_buf_wr = 1'b1;
		end
		// 2: begin
		// 	msg_buf_in = {msg_color,1'b0,msg_color,1'b0,xy_cnt[msg_color],4'b0,is_color_valid[msg_color]};
		// 	msg_buf_wr = 1'b1;
		// end
		// 3: begin
		// 	msg_buf_in = {center_x[msg_color],1'b0,center_y[msg_color],1'b0,top[msg_color]};	//Top left coordinate
		// 	msg_buf_wr = 1'b1;
		// end
		// 4: begin
		// 	msg_buf_in = {bottom[msg_color],1'b0,left[msg_color],1'b0,right[msg_color]}; //Bottom right coordinate
		// 	msg_buf_wr = 1'b1;
		// end
		2: begin
			msg_buf_in = {1'b0,msg_color,1'b0,msg_color,1'b0,1'b0,is_color_valid[msg_color],2'b0,xy_cnt[msg_color]};
			msg_buf_wr = 1'b1;
		end
		3: begin
			msg_buf_in = {1'b0,msg_color,1'b0,msg_color,1'b1,2'b0,center_x[msg_color],1'b0,center_y[msg_color]};	//Top left coordinate
			msg_buf_wr = 1'b1;
		end
		4: begin
			msg_buf_in = 0;
			msg_buf_wr = 1'b0;
		end
		5: begin
			msg_buf_in = 0;
			msg_buf_wr = 1'b0;
		end

	endcase
end

reg filter_rst=0;
reg use_filter=1;
reg wc_rst=0;
wire calc_weight;
COLOR_DETECT COLOR_DETECT_module(
	.clk(clk),
	.filter_rst(filter_rst),
	.use_filter(use_filter),
	.rgb_r(red),
  .rgb_g(green),
  .rgb_b(blue),
	.color(detected_color),
);

// MEDIAN_FILTER r_filter(.clk(clk),.rst(filter_rst),.data_in(red),.data_out(red_filter_out));
// MEDIAN_FILTER g_filter(.clk(clk),.rst(filter_rst),.data_in(green),.data_out(green_filter_out));
// MEDIAN_FILTER b_filter(.clk(clk),.rst(filter_rst),.data_in(blue),.data_out(blue_filter_out));

// RGB2HSV RGB2HSV_module(
//   .rgb_r(red),
//   .rgb_g(green),
//   .rgb_b(blue),
//   .hsv_h(h),
//   .hsv_s(s),
//   .hsv_v(v));


//Output message FIFO
MSG_FIFO	MSG_FIFO_inst (
	.clock (clk),
	.data (msg_buf_in),
	.rdreq (msg_buf_rd),
	.sclr (~reset_n | msg_buf_flush),
	.wrreq (msg_buf_wr),
	.q (msg_buf_out),
	.usedw (msg_buf_size),
	.empty (msg_buf_empty)
	);


//Streaming registers to buffer video signal
STREAM_REG #(.DATA_WIDTH(26)) in_reg (
	.clk(clk),
	.rst_n(reset_n),
	.ready_out(sink_ready),
	.valid_out(in_valid),
	.data_out({red,green,blue,sop,eop}),
	.ready_in(out_ready),
	.valid_in(sink_valid),
	.data_in({sink_data,sink_sop,sink_eop})
);

STREAM_REG #(.DATA_WIDTH(26)) out_reg (
	.clk(clk),
	.rst_n(reset_n),
	.ready_out(out_ready),
	.valid_out(source_valid),
	.data_out({source_data,source_sop,source_eop}),
	.ready_in(source_ready),
	.valid_in(in_valid),
	.data_in({red_out, green_out, blue_out, sop, eop})
);

WEIGHT_CALC wc(.(clk),.rst(wc_rst),.data_in(color_detect),.data_out(calc_weight));

/////////////////////////////////
/// Memory-mapped port		 /////
/////////////////////////////////

// Addresses
`define REG_STATUS    			0
`define READ_MSG    				1
`define READ_ID    				2
`define REG_BBCOL					3

//Status register bits
// 31:16 - unimplemented
// 15:8 - number of words in message buffer (read only)
// 7:5 - unused
// 4 - flush message buffer (write only - read as 0)
// 3:0 - unused


// Process write

reg  [7:0]   reg_status;
reg	[23:0]	bb_col,center_col;

always @ (posedge clk)
begin
	if (~reset_n)
	begin
		reg_status <= 8'b0;
		bb_col <= BB_COL_DEFAULT;
		center_col<=CENTER_COL_DEFAULT;
	end
	else begin
		if(s_chipselect & s_write) begin
		   if      (s_address == `REG_STATUS)	reg_status <= s_writedata[7:0];
		   if      (s_address == `REG_BBCOL)	bb_col <= s_writedata[23:0];
		end
	end
end


//Flush the message buffer if 1 is written to status register bit 4
assign msg_buf_flush = (s_chipselect & s_write & (s_address == `REG_STATUS) & s_writedata[4]);


// Process reads
reg read_d; //Store the read signal for correct updating of the message buffer

// Copy the requested word to the output port when there is a read.
always @ (posedge clk)
begin
   if (~reset_n) begin
	   s_readdata <= {32'b0};
		read_d <= 1'b0;
	end
	
	else if (s_chipselect & s_read) begin
		if   (s_address == `REG_STATUS) s_readdata <= {16'b0,msg_buf_size,reg_status};
		if   (s_address == `READ_MSG) s_readdata <= {msg_buf_out};
		if   (s_address == `READ_ID) s_readdata <= 32'h1234EEE2;
		if   (s_address == `REG_BBCOL) s_readdata <= {8'h0, bb_col};
	end
	
	read_d <= s_read;
end

//Fetch next word from message buffer after read from READ_MSG
assign msg_buf_rd = s_chipselect & s_read & ~read_d & ~msg_buf_empty & (s_address == `READ_MSG);
						


endmodule

