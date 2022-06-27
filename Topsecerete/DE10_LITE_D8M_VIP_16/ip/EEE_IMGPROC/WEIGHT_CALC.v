module  WEIGHT_CALC(
  input clk,
  input rst,
	input	               data_in,
  	input	    [2:0]           color,
	output	    [4:0]       data_out
);
parameter WINDOW_SIZE = 10;
reg data[0:WINDOW_SIZE-1][0:8];
integer i;
integer j;
reg [15:0] sum[0:8];
initial begin
  	for(j=0;j<8;j=j+1) begin
      for(i=0;i<WINDOW_SIZE;i=i+1) begin
            data[i][j]=0;
      end
      // sum[j]=0;
    end
    i=0;
    j=0;
end

always @ (*)
begin
  // for(i=0;i<WINDOW_SIZE;i=i+1) begin
  //     sum=sum+data[i];
  //   end
// sum=6*data[0]+5*data[1]+4*data[2]+4*data[3]+3*data[4]+2*data[5]+2*data[6]+2*data[7]+1*data[8]+1*data[9]+1;

sum[color]=6*data[0][color]+5*data[1][color]+4*data[2][color]+4*data[3][color]+3*data[4][color]+2*data[5][color]+2*data[6][color]+2*data[7][color]+1*data[8][color]+1*data[9][color]+1;
end

assign data_out=rst ? 1 : sum[color];

always@(posedge clk)
begin
  if(rst==0) begin
    data[0][color]<=data_in;
  	for(j=1;j<WINDOW_SIZE;j=j+1) begin
      data[j][color]<=data[j-1][color];
    end
  end
  else begin
    for(j=0;j<WINDOW_SIZE;j=j+1) begin
      data[j][color]<=0;
    end
  end
end


endmodule