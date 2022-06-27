module  EDGE_DETECT(
  input clk,
  input rst,
	input	             [9:0]  pos_x,
  input data_in,
	output	          up_edge,
  output	          down_edge
);
parameter WINDOW_SIZE = 20;
parameter HALF_WINDOW_SIZE = 10;
reg data[0:WINDOW_SIZE-1];
integer i;
integer j;
reg [18:0] sum_left,sum_right=0;
reg [9:0] edge_x=0;
reg _up_edge,_down_edge;
initial begin
    for(i=0;i<WINDOW_SIZE;i=i+1) begin
          data[i]=0;
    end
    i=0;
    j=0;
end

assign up_edge=_up_edge;
assign down_edge=_down_edge;

always @ (*)
begin
  // for(i=0;i<WINDOW_SIZE;i=i+1) begin
  //     sum_left=sum_left+data[i];
  //   end
// sum=6*data[0]+5*data[1]+4*data[2]+4*data[3]+3*data[4]+2*data[5]+2*data[6]+2*data[7]+1*data[8]+1*data[9]+1;

sum_left=5*data[0]+5*data[1]+5*data[2]+3*data[3]+3*data[4]+2*data[5]+2*data[6]+2*data[7]+data[8]+data[9];
sum_right=data[10]+data[11]+2*data[12]+2*data[13]+3*data[14]+3*data[15]+3*data[16]+5*data[17]+5*data[18]+5*data[19];

if(sum_left>sum_right & sum_left-sum_right>25) begin
  _up_edge=1;
  _down_edge=0;
end
else if(sum_left<sum_right & sum_right-sum_left>25) begin
  _down_edge=1;
  _up_edge=0;
end
else begin
  _up_edge=0;
  _down_edge=0;
end

end

always@(posedge clk)
begin
  if(rst==0) begin
    data[0]<=data_in;
  	for(j=1;j<WINDOW_SIZE;j=j+1) begin
      data[j]<=data[j-1];
    end
    if(_up_edge || _down_edge) begin
      edge_x<=pos_x;
    end
  end
  else begin
    for(j=0;j<WINDOW_SIZE;j=j+1) begin
      data[j]<=0;
    end
    edge_x<=0;
  end
end


endmodule