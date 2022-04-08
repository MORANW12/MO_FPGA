module Predict (
	input wire clk,    
	input wire rst_n, 

	//data ports
	input wire [15:0] Rx,
	input wire [15:0] Ra,
	input wire [15:0] Rb,
	input wire [15:0] Rc,
	input wire [15:0] Rd,
	input wire  [15:0] D1,
	input wire  [15:0] D2,
	input wire  [15:0] D3,
	input wire  data_en
);
//step 1 Quantization of gradient
reg [3:0] Q1;
reg [3:0] Q2;
reg [3:0] Q3;

assign 			T1 = 'd18;//=(bpp-7)*3+near;
assign 			T2 = 'd67;//=(bpp-7)*7+2*near;
assign 			T3 = 'd276;//=(bpp-7)*21+3*near;
assign 			T1_n = 0 - 'd18;//=(bpp-7)*3+near;
assign 			T2_n = 0 - 'd67;//=(bpp-7)*7+2*near;
assign 			T3_n = 0 - 'd276;//=(bpp-7)*21+3*near;

always @(*) begin:Q1_value
	if (D1==0) begin
		Q1 <= 0;
	end else if (D1[15]==1&&D1<T3_n) begin
		Q1 <= 0-4;
	end else if (D1[15]==1&&D1<T2_n&&D1>T3_n) begin
		Q1 <= 0-3;
	end else if (D1[15]==1&&D1<T1_n&&D1>T2_n) begin
		Q1 <= 0-2;
	end else if (D1[15]==1&&D1>T1_n) begin
		Q1 <= 0-1;
	end else if (D1[15]==0&&D1<T1) begin
		Q1 <= 1;
	end else if (D1[15]==0&&D1>T1&&D1<T2) begin
		Q1 <= 2;
	end else if (D1[15]==0&&D1>T2&&D1<T3) begin
		Q1 <= 3;
	end else if (D1[15]==0&&D1>T3) begin
		Q1 <= 4;
	end else begin
		Q1 <= 0;
	end
end
always @(*) begin:Q2_value
	if (D2==0) begin
		Q2 <= 0;
	end else if (D2[15]==1&&D2<T3_n) begin
		Q2 <= 0-4;
	end else if (D2[15]==1&&D2<T2_n&&D2>T3_n) begin
		Q2 <= 0-3;
	end else if (D2[15]==1&&D2<T1_n&&D2>T2_n) begin
		Q2 <= 0-2;
	end else if (D2[15]==1&&D2>T1_n) begin
		Q2 <= 0-1;
	end else if (D2[15]==0&&D2<T1) begin
		Q2 <= 1;
	end else if (D2[15]==0&&D2>T1&&D2<T2) begin
		Q2 <= 2;
	end else if (D2[15]==0&&D2>T2&&D2<T3) begin
		Q2 <= 3;
	end else if (D2[15]==0&&D2>T3) begin
		Q2 <= 4;
	end else begin
		Q2 <= 0;
	end
end
always @(*) begin:Q3_value
	if (D3==0) begin
		Q3 <= 0;
	end else if (D3[15]==1&&D3<T3_n) begin
		Q3 <= 0-4;
	end else if (D3[15]==1&&D3<T2_n&&D3>T3_n) begin
		Q3 <= 0-3;
	end else if (D3[15]==1&&D3<T1_n&&D3>T2_n) begin
		Q3 <= 0-2;
	end else if (D3[15]==1&&D3>T1_n) begin
		Q3 <= 0-1;
	end else if (D3[15]==0&&D3<T1) begin
		Q3 <= 1;
	end else if (D3[15]==0&&D3>T1&&D3<T2) begin
		Q3 <= 2;
	end else if (D3[15]==0&&D3>T2&&D3<T3) begin
		Q3 <= 3;
	end else if (D3[15]==0&&D3>T3) begin
		Q3 <= 4;
	end else begin
		Q3 <= 0;
	end
end
//step 2 Q value
assign Q = (Q1*9 + Q2)*9 + Q3;
//step 3 Sobel detect
reg [15:0] Px;
always @(posedge clk or negedge rst_n) begin : proc_Px
	if(~rst_n) begin
		Px <= 0;
	end else if(Rc>Ra&&Rc>Rb)begin
		if (Ra<Rb) begin
			Px <= Ra;
		end
		else begin
			Px <= Rb;
		end	
	end else if(Rc<Ra&&Rc<Rb)begin
		if (Ra<Rb) begin
			Px <= Rb;
		end
		else begin
			Px <= Ra;
		end	
	end else if((Rc<Ra&&Rc>Rb)||(Rc>Ra&&Rc<Rb))begin
			Px <= Ra + Rb -Rc;	
	end
end
//step 4 Correction of predicted values
wire [15:0] Px_r;
reg  [15:0] SIGN;
always @(*) begin: get_SIGN_Q
	if (Q1[3] == 1'b1) begin
		SIGN <= 1'b1;
	end else if (Q2[3] == 1'b1 && Q1 == 'd0) begin
		SIGN <= 1'b1;
	end else if (Q3[3] == 1'b1 && Q2 == 'd0 && Q1 == 'd0) begin
		SIGN <= 1'b1;
	end else begin
		SIGN <= 1'b0;
	end
end

assign Px_r = Px + SIGN*CQ;
//step 5 Calculation of prediction error
//step 6 Modulus subtraction and mapping of prediction errors
//step 7 Update of encoding parameters
reg CQ;
//step 8 Coding of prediction error

endmodule : Predict