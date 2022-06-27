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