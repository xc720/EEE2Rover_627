module  MEDIAN_FILTER(
  input clk,
  input rst,
	input	     [7:0]            data_in,
	output	     [7:0]            data_out
);
parameter WINDOW_SIZE = 20;
reg [7:0] data[0:WINDOW_SIZE-1];
integer i;
initial begin
	for(i=0;i<WINDOW_SIZE;i=i+1) begin
        data[i]=0;
    end
    i=0;
end
reg [15:0]sum=0;
integer j;
always @ (*)
begin
  // for(i=0;i<WINDOW_SIZE;i=i+1) begin
  //     sum=sum+data[i];
  //   end
sum=data[0]+data[1]+data[2]+data[3]+data[4]+data[5]+data[6]+data[7]+data[8]+data[9]+
data[10]+data[11]+data[12]+data[13]+data[14]+data[15]+data[16]+data[17]+data[18]+data[19];
end

assign data_out=rst ? data_in : sum/WINDOW_SIZE;

always@(posedge clk)
begin
  if(rst==0) begin
    data[0]<=data_in;
  	for(j=1;j<WINDOW_SIZE;j=j+1) begin
      data[j]<=data[j-1];
    end
  end
  else begin
    for(j=0;j<WINDOW_SIZE;j=j+1) begin
      data[j]<=0;
    end
  end
end


endmodule

module  COLOR_DETECT(
  input clk,
  input filter_rst,
  input use_filter,
	input	     [7:0]            rgb_r,
	input	     [7:0]            rgb_g,
	input	     [7:0]            rgb_b,
  input      [31:0]           tun_col,	
	output [2:0] color,
  output detected
);

wire [8:0]h;
wire [7:0]s;
wire [7:0]v;

wire [8:0]h_filter_out;
wire [7:0]s_filter_out;
wire [7:0]v_filter_out;

wire [8:0] h_used;
wire [7:0] s_used;
wire [7:0] v_used;

assign h_used = use_filter ? h_filter_out : h;
assign s_used = use_filter ? s_filter_out : s;
assign v_used = use_filter ? v_filter_out : v;

parameter BLACK_CODE = 3'b000;
parameter WHITE_CODE = 3'b001;
parameter RED_CODE = 3'b010;
parameter BLUE_CODE = 3'b011;
parameter YELLOW_CODE = 3'b100;
parameter PURPLE_CODE = 3'b101;
parameter DGREEN_CODE = 3'b110;
parameter LGREEN_CODE = 3'b111;
parameter UNKNOWN_CODE = 3'b000;
parameter HSV_V_MIN= 8'd110;

parameter BLACK_HSV_DEFUALT = {9'd0,8'd0,8'd0,9'd360,8'd76,8'd90};
parameter WHITE_HSV_DEFUALT = {9'd0,8'd0,8'd100,9'd360,8'd100,8'd255};
parameter RED_HSV_DEFUALT = {9'd13,8'd169,8'd153,9'd25,8'd234,8'd255};
parameter BLUE_HSV_DEFUALT = {9'd160,8'd40,8'd49,9'd240,8'd155,8'd255};
parameter YELLOW_HSV_DEFUALT = {9'd53,8'd127,8'd185,9'd86,8'd255,8'd255};
parameter PURPLE_HSV_DEFUALT = {9'd0,8'd78,8'd153,9'd20,8'd196,8'd255};
parameter DGREEN_HSV_DEFUALT = {9'd88,8'd46,8'd0,9'd176,8'd255,8'd166};
parameter LGREEN_HSV_DEFUALT = {9'd96,8'd94,8'd221,9'd126,8'd255,8'd255};



reg [49:0] red_hsv;
reg [49:0] blue_hsv;
reg [49:0] yellow_hsv;
reg [49:0] purple_hsv;
reg [49:0] dgreen_hsv;
reg [49:0] lgreen_hsv;
reg [49:0] black_hsv;
reg [49:0] white_hsv;
initial begin
   red_hsv = RED_HSV_DEFUALT;
   blue_hsv = BLUE_HSV_DEFUALT;
   yellow_hsv = YELLOW_HSV_DEFUALT;
   purple_hsv = PURPLE_HSV_DEFUALT;
   dgreen_hsv = DGREEN_HSV_DEFUALT;
   lgreen_hsv = LGREEN_HSV_DEFUALT;
   white_hsv = WHITE_HSV_DEFUALT;
   black_hsv = BLACK_HSV_DEFUALT;
end


RGB2HSV RGB2HSV_module(
  .rgb_r(rgb_r),
  .rgb_g(rgb_g),
  .rgb_b(rgb_b),
  .hsv_h(h),
  .hsv_s(s),
  .hsv_v(v));
reg [2:0] _color;
reg  _detected;
assign color=_color;
assign  detected = _detected;

MEDIAN_FILTER H_filter(.clk(clk),.rst(filter_rst),.data_in(h),.data_out(h_filter_out));
MEDIAN_FILTER S_filter(.clk(clk),.rst(filter_rst),.data_in(s),.data_out(s_filter_out));
MEDIAN_FILTER V_filter(.clk(clk),.rst(filter_rst),.data_in(v),.data_out(v_filter_out));

always @(posedge clk)begin
  if(tun_col != 32'hffffffff) begin


  if (tun_col[31:29]==BLUE_CODE) begin
    if (tun_col[28]==0)begin
      blue_hsv[49:25]<=tun_col[24:0];
    end
    else begin
      blue_hsv[24:0]<=tun_col[24:0];
    end
  end
  else if (tun_col[31:29]==RED_CODE) begin
    if (tun_col[28]==0)begin
      red_hsv[49:25]<=tun_col[24:0];
    end
    else begin
      red_hsv[24:0]<=tun_col[24:0];
    end
  end
    else if (tun_col[31:29]==YELLOW_CODE) begin
    if (tun_col[28]==0)begin
      yellow_hsv[49:25]<=tun_col[24:0];
    end
    else begin
      yellow_hsv[24:0]<=tun_col[24:0];
    end
  end
    else if (tun_col[31:29]==PURPLE_CODE) begin
    if (tun_col[28]==0)begin
      purple_hsv[49:25]<=tun_col[24:0];
    end
    else begin
      purple_hsv[24:0]<=tun_col[24:0];
    end
  end
    else if (tun_col[31:29]==WHITE_CODE) begin
    if (tun_col[28]==0)begin
      white_hsv[49:25]<=tun_col[24:0];
    end
    else begin
      white_hsv[24:0]<=tun_col[24:0];
    end
  end
      else if (tun_col[31:29]==DGREEN_CODE) begin
    if (tun_col[28]==0)begin
      dgreen_hsv[49:25]<=tun_col[24:0];
    end
    else begin
      dgreen_hsv[24:0]<=tun_col[24:0];
    end
  end
    else if (tun_col[31:29]==LGREEN_CODE) begin
    if (tun_col[28]==0)begin
      lgreen_hsv[49:25]<=tun_col[24:0];
    end
    else begin
      lgreen_hsv[24:0]<=tun_col[24:0];
    end
  end
    else if (tun_col[31:29]==BLACK_CODE) begin
    if (tun_col[28]==0)begin
      black_hsv[49:25]<=tun_col[24:0];
    end
    else begin
      black_hsv[24:0]<=tun_col[24:0];
    end
  end
    end
end

always @ (*)
begin
  if (h_used>=blue_hsv[49:41] & h_used<=blue_hsv[24:16] & s_used>=blue_hsv[40:33] & s_used<=blue_hsv[15:8] & v_used>=blue_hsv[32:25]&v_used<=blue_hsv[7:0]) begin
    _color=BLUE_CODE;
    _detected=1;
  end
  // if (((h_used>=9'd160) & (h_used<=9'd240)) & ((s_used>=8'd40) & (s_used<=8'd155)) & ((v_used>=8'd49)&(v_used<=8'd255))) begin
  //   _col cD
  else if ((h_used>=red_hsv[49:41] & h_used<=red_hsv[24:16]) & (s_used>=red_hsv[40:33] & s_used<=red_hsv[15:8]) & (v_used>=red_hsv[32:25]&v_used<=red_hsv[7:0])) begin
    _color=RED_CODE;
     _detected=1;
  end
  else if (h_used>=yellow_hsv[49:41] & h_used<=yellow_hsv[24:16] & s_used>=yellow_hsv[40:33] & s_used<=yellow_hsv[15:8] & v_used>=yellow_hsv[32:25]&v_used<=yellow_hsv[7:0]) begin
    _color=YELLOW_CODE;
     _detected=1;
  end
  else if (h_used>=purple_hsv[49:41] & h_used<=purple_hsv[24:16] & s_used>=purple_hsv[40:33] & s_used<=purple_hsv[15:8] & v_used>=purple_hsv[32:25]&v_used<=purple_hsv[7:0]) begin
    _color=PURPLE_CODE;
     _detected=1;
  end
  else if (h_used>=white_hsv[49:41] & h_used<=white_hsv[24:16] & s_used>=white_hsv[40:33] & s_used<=white_hsv[15:8] & v_used>=white_hsv[32:25]&v_used<=white_hsv[7:0]) begin
    _color=WHITE_CODE;
     _detected=1;
  end
    else if (h_used>=lgreen_hsv[49:41] & h_used<=lgreen_hsv[24:16] & s_used>=lgreen_hsv[40:33] & s_used<=lgreen_hsv[15:8] & v_used>=lgreen_hsv[32:25]&v_used<=lgreen_hsv[7:0]) begin
    _color=LGREEN_CODE;
     _detected=1;
  end
    else if (h_used>=dgreen_hsv[49:41] & h_used<=dgreen_hsv[24:16] & s_used>=dgreen_hsv[40:33] & s_used<=dgreen_hsv[15:8] & v_used>=dgreen_hsv[32:25]&v_used<=dgreen_hsv[7:0]) begin
    _color=DGREEN_CODE;
     _detected=1;
  end
  else if (h_used>=black_hsv[49:41] & h_used<=black_hsv[24:16] & s_used>=black_hsv[40:33] & s_used<=black_hsv[15:8] & v_used>=black_hsv[32:25]&v_used<=black_hsv[7:0]) begin
    _color=BLACK_CODE;
     _detected=1;
  end
  else begin
     _detected=0;
    _color=UNKNOWN_CODE;
  end

  
end


endmodule