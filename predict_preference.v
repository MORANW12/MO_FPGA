module predict(
input 		wire 						clk,
input 		wire 						rst_n,
input 		wire 		[15:0] 			Ra,
input 		wire 		[15:0] 			Rb,
input 		wire 		[15:0] 			Rc,
input 		wire 		[15:0] 			Rd,
input 		wire 		[15:0] 			Ix,
input 		wire 		[16:0] 			D1,
input 		wire 		[16:0] 			D2,
input 		wire 		[16:0] 			D3,
input 		wire 			 			en_r,

output 		reg 		[16:0]			MErrval,
output 		reg 						en_r2,
output 		reg 		[3:0]			K
	
);
/*
module predict #(
	parameter  WIDTH_data    = 16;
	parameter  MAX_data      = 2**16-1;
	parameter  MIN_data      = 0;
	parameter  RESET         = 64;
	parameter  WIDTH_RESET   = 6;
	parameter  MAX_C         = 128;
	parameter  MIN_C         = -127; // 9'b1_1000_0001;
	parameter  WIDTH_C_upt   = 9;
)
(
input 		wire 						clk,
input 		wire 						rst_n,
input 		wire 	[WIDTH_data-1:0] 	Ra,
input 		wire 	[WIDTH_data-1:0] 	Rb,
input 		wire 	[WIDTH_data-1:0] 	Rc,
input 		wire 	[WIDTH_data-1:0] 	Rd,
input 		wire 	[WIDTH_data-1:0] 	Ix,
input 		wire 	[WIDTH_data:0] 		D1,
input 		wire 	[WIDTH_data:0] 		D2,
input 		wire 	[WIDTH_data:0] 		D3,
input 		wire 			 			en_r,

output 		reg 	[WIDTH_data:0]		MErrval,
output 		reg 						en_r2,
output 		reg 		[3:0]			k
	
);*/
parameter  WIDTH_data    = 16;
parameter  MAX_data      = 2**16-1;
parameter  MIN_data      = 0;
parameter  WIDTH_Errval  = WIDTH_data+1;
parameter  RESET         = 64;
parameter  WIDTH_RESET   = 7;
parameter  WIDTH_N       = WIDTH_RESET;
parameter  WIDTH_B_upt   = WIDTH_RESET+1;
parameter  WIDTH_B_add   = WIDTH_Errval + 1;
parameter  WIDTH_A       = WIDTH_Errval + WIDTH_RESET;
parameter  WIDTH_C_upt   = 9;
parameter  C_MAX   		 = 9'b0_0111_1111;//9'd127;
parameter  C_MIN	     = 9'b1_1000_0000;//9'd-128;

//parameter bpp = 16;

reg 			[WIDTH_data-1:0] 		Ix_r2;
reg 			[WIDTH_data-1:0]		Px_r2;  //unsigned
wire 			[WIDTH_data:0]			T1;
wire 			[WIDTH_data:0]			T2;
wire 			[WIDTH_data:0]			T3;
wire 			[WIDTH_data:0]			T1_n;
wire 			[WIDTH_data:0]			T2_n;
wire 			[WIDTH_data:0]			T3_n;
reg 			[3:0]					Q1;
reg 			[3:0]					Q2;
reg 			[3:0]					Q3;
reg 			[3:0]					Q1_p;
reg 			[3:0]					Q2_p;
reg 			[3:0]					Q3_p;
wire 			[8:0]					Q;
reg 			[8:0]					Q_r;
reg 			[8:0]					Q_r2;
reg 			[WIDTH_data-1:0]		Px;  //unsigned
reg  			[WIDTH_data+2-1:0]		Px_c; // signed
reg  			[WIDTH_data-1:0]		Px_c_limit; //unsigned
reg 					    			SIGN_Q;
reg 					    			SIGN_Q_r2;
reg 					    			SIGN_E;
reg  			[WIDTH_Errval-1:0]		Errval;
reg             [364:0]       			ini_A;
wire			[WIDTH_A-1:0]			A_upt;
reg 			[WIDTH_A-1:0]			A_add;
reg 			[WIDTH_A-1:0]			A_sl;
wire			[WIDTH_A-1:0]			A_next;
reg 			[WIDTH_A-1:0]			A_next_r;
wire 			[WIDTH_A-1:0]			A_RAM;
reg 			[WIDTH_A-1:0]			slt_data_A;
reg             [364:0]         		ini_B;
wire			[WIDTH_B_upt-1:0]		B_upt;
reg 			[WIDTH_B_add-1:0]		B_upt_p;
wire			[WIDTH_B_upt-1:0]		B_next;
reg 			[WIDTH_B_upt-1:0]		B_next_r;
wire			[WIDTH_B_upt-1:0]		B_RAM;
reg 			[WIDTH_B_upt-1:0]		slt_data_B;
wire 			[WIDTH_B_add-1:0]		B_add;
reg 			[WIDTH_B_add-1:0]		B_sl;
reg             [364:0]         		ini_N;
reg 			[WIDTH_N-1:0]			N_upt;
reg 			[WIDTH_N:0]				N_upt_n;
reg 			[WIDTH_N+1:0]			N_upt_s2_n;
wire 			[WIDTH_N:0]				N_upt_p;
wire			[WIDTH_N-1:0]			N_next;
reg 			[WIDTH_N-1:0]			N_next_r;
wire			[WIDTH_N-1:0]			N_RAM;
reg 			[WIDTH_N-1:0]			slt_data_N;
reg             [364:0]        		 	ini_C;
reg 			[WIDTH_C_upt-1:0]		C_upt;
reg 			[WIDTH_C_upt-1:0]		C_upt_limit;
wire			[WIDTH_C_upt-1:0]		C_next;
reg 			[WIDTH_C_upt-1:0]		C_next_r;
wire			[WIDTH_C_upt-1:0]		C_RAM;
reg 			[WIDTH_C_upt-1:0]		slt_data_C;


assign 			T1 = 'd18;//=(bpp-7)*3+near;
assign 			T2 = 'd67;//=(bpp-7)*7+2*near;
assign 			T3 = 'd276;//=(bpp-7)*21+3*near;
assign 			T1_n = 0 - 'd18;//=(bpp-7)*3+near;
assign 			T2_n = 0 - 'd67;//=(bpp-7)*7+2*near;
assign 			T3_n = 0 - 'd276;//=(bpp-7)*21+3*near;

always @(*) begin: get_Q1
	if (D1==0) begin
		Q1 	<=  3'd0;
	end else if (D1[WIDTH_data]==1'b0 && D1 < T1) begin
		Q1  <=	3'd1; 
	end else if (D1[WIDTH_data]==1'b1 && D1 > T1_n)begin
		Q1  <=	3'd0-3'd1; 
	end else if (D1[WIDTH_data]==1'b0 && D1 >= T1   && D1 < T2) begin
		Q1  <=	3'd2; 
	end else if (D1[WIDTH_data]==1'd1 && D1 <= T1_n && D1 > T2_n)begin
		Q1  <=	3'd0-3'd2; 
	end else if (D1[WIDTH_data]==1'b0 && D1 >= T2   && D1 < T3) begin
		Q1  <=	3'd3; 
	end else if (D1[WIDTH_data]==1'd1 && D1 <= T2_n && D1 > T3_n)begin
		Q1  <=	3'd0-3'd3;  
	end else if (D1[WIDTH_data]==1'b0 && D1 >= T3) begin
		Q1  <=	3'd4; 
	end else if (D1[WIDTH_data]==1'd1 && D1 <= T3_n)begin
		Q1  <=	3'd0-3'd4; 
	end else begin
		Q1  <= 'd0;
	end
end

always @(*) begin: get_Q2
	if (D2==0) begin
		Q2 	<=  3'd0;
	end else if (D2[WIDTH_data]==1'b0 && D2 < T1) begin
		Q2  <=	3'd1; 
	end else if (D2[WIDTH_data]==1'b1 && D2 > T1_n)begin
		Q2  <=	3'd0-3'd1; 
	end else if (D2[WIDTH_data]==1'b0 && D2 >= T1   && D2 < T2) begin
		Q2  <=	3'd2; 
	end else if (D2[WIDTH_data]==1'd1 && D2 <= T1_n && D2 > T2_n)begin
		Q2  <=	3'd0-3'd2; 
	end else if (D2[WIDTH_data]==1'b0 && D2 >= T2   && D2 < T3) begin
		Q2  <=	3'd3; 
	end else if (D2[WIDTH_data]==1'd1 && D2 <= T2_n && D2 > T3_n)begin
		Q2  <=	3'd0-3'd3;  
	end else if (D2[WIDTH_data]==1'b0 && D2 >= T3) begin
		Q2  <=	3'd4; 
	end else if (D2[WIDTH_data]==1'd1 && D2 <= T3_n)begin
		Q2  <=	3'd0-3'd4; 
	end else begin
		Q2  <= 'd0;
	end
end

always @(*) begin: get_Q3
	if (D3==0) begin
		Q3 	<=  3'd0;
	end else if (D3[WIDTH_data]==1'b0 && D3 < T1) begin
		Q3  <=	3'd1; 
	end else if (D3[WIDTH_data]==1'b1 && D3 > T1_n)begin
		Q3  <=	3'd0-3'd1; 
	end else if (D3[WIDTH_data]==1'b0 && D3 >= T1   && D3 < T2) begin
		Q3  <=	3'd2; 
	end else if (D3[WIDTH_data]==1'd1 && D3 <= T1_n && D3 > T2_n)begin
		Q3  <=	3'd0-3'd2; 
	end else if (D3[WIDTH_data]==1'b0 && D3 >= T2   && D3 < T3) begin
		Q3  <=	3'd3; 
	end else if (D3[WIDTH_data]==1'd1 && D3 <= T2_n && D3 > T3_n)begin
		Q3  <=	3'd0-3'd3;  
	end else if (D3[WIDTH_data]==1'b0 && D3 >= T3) begin
		Q3  <=	3'd4; 
	end else if (D3[WIDTH_data]==1'd1 && D3 <= T3_n)begin
		Q3  <=	3'd0-3'd4; 
	end else begin
		Q3  <= 'd0;
	end
end


always @(*) begin: get_Q_p
	if (SIGN_Q==1'b1) begin
		Q1_p	<=	0 - Q1;
		Q2_p 	<=  0 - Q2;
		Q3_p	<=	0 - Q3;
	end else begin
		Q1_p	<=	Q1;
		Q2_p 	<=  Q2;
		Q3_p	<=	Q3;
	end
end

assign  Q = ({{5{Q1_p[3]}},Q1_p} * 9 + {{5{Q2_p[3]}},Q2_p} ) * 9 + {{5{Q3_p[3]}},Q3_p} ;

//Px
always @(*) begin: get_Px
	if (Rc > Ra && Rc > Rb && Ra > Rb) begin
		Px	<= Rb;
	end else if (Rc > Ra && Rc > Rb && Ra <= Rb) begin
		Px	<= Ra;
	end else if(Rc < Ra && Rc < Rb && Ra > Rb)begin
		Px	<= Ra;
	end else if(Rc < Ra && Rc < Rb && Ra <= Rb)begin
		Px	<= Rb;
	end else if((Rc >= Ra && Rc <= Rb) || (Rc <= Ra && Rc >= Rb))begin
		Px	<= Ra + Rb - Rc;
	end 

		else begin
		Px  <= 0;//组合逻辑若不满足上诉情况 则锁存；
	end
end

//SIGN_Q
always @(*) begin: get_SIGN_Q
	if (Q1[3] == 1'b1) begin
		SIGN_Q <= 1'b1;
	end else if (Q2[3] == 1'b1 && Q1 == 'd0) begin
		SIGN_Q <= 1'b1;
	end else if (Q3[3] == 1'b1 && Q2 == 'd0 && Q1 == 'd0) begin
		SIGN_Q <= 1'b1;
	end else begin
		SIGN_Q <= 1'b0;
	end
end
//101 + 100 => 0101 + 0100 => 1001 // >max
//001 - 100 => 0001 - 0100 => 1101 // <0
//101 + 001 => 00101 + 00001 => 00110 // 0<  <max
//101 + 100 => 00101 + 00100 => 01001 // >max
//001 - 100 => 00001 - 00100 => 11101 // <0
//assign Px_c = Px + SIGN_Q*C

always @(posedge clk or negedge rst_n) begin: register2
	if(rst_n == 1'b0) begin
		Px_r2 <= 'd0;
		Ix_r2 <= 'd0;
		SIGN_Q_r2 <= 'd0;
	end else if(en_r) begin
		Px_r2 <= Px;
		Ix_r2 <= Ix;
		SIGN_Q_r2 <= SIGN_Q;
	end
end

always @(*) begin: get_Px_c
	if (SIGN_Q_r2 == 1'b1) begin
		Px_c <= {2'b0, Px_r2} - {{(WIDTH_data-WIDTH_C_upt+2){slt_data_C[WIDTH_C_upt-1]}}, slt_data_C};
	end else begin
		Px_c <= {2'b0, Px_r2} + {{(WIDTH_data-WIDTH_C_upt+2){slt_data_C[WIDTH_C_upt-1]}}, slt_data_C};
	end 
end

always @(*) begin: get_Px_c_limit
	if (Px_c[WIDTH_data+2-1:WIDTH_data+2-1-1] == 2'b01) begin
		Px_c_limit <= MAX_data;
	end else if (Px_c[WIDTH_data+2-1:WIDTH_data+2-1-1] == 2'b11) begin
		Px_c_limit <= MIN_data;
	end else begin
		Px_c_limit <= Px_c[WIDTH_data-1:0];
	end
end

//Errval
always @(*) begin
	if (SIGN_Q_r2 == 1'b0) begin
		Errval = {1'b0, Ix_r2} - {1'b0, Px_c_limit};
	end else begin
		Errval = {1'b0, Px_c_limit} - {1'b0, Ix_r2};
	end
end

//奇偶对应正负号的映射
always @(*) begin: get_MErrval
	if (Errval[WIDTH_Errval-1]	== 0) begin
		MErrval	<= 	2 * Errval;
	end else begin
		MErrval	<= 	(0-2) * Errval - 1;
	end
end

//A[Q]
//寄存
always @(posedge clk or negedge rst_n) begin: get_en_r2
  if (rst_n==0) begin
      en_r2 <= 0;
  end else begin
      en_r2 <= en_r;
  end
end

always @(posedge clk or negedge rst_n) begin: get_Q_r
  if (rst_n==0) begin
      Q_r <= 0;
  end else if(en_r == 1'b1) begin
      Q_r <= Q; 
  end
end

assign A_next = A_upt;

always @(posedge clk or negedge rst_n) begin: get_Q_r2
  if (rst_n==0) begin
      Q_r2 <= 0;
      A_next_r <= 0;
  end else if(en_r == 1'b1) begin
      Q_r2 <= Q_r; 
      A_next_r <= A_next;
  end
end

//ini
always@(posedge clk or negedge rst_n) begin: get_ini_A
      if(rst_n==0)begin 
          ini_A <= ~'d0;
      end else if(en_r2 == 1'b1) begin
          ini_A[Q_r] <= 'd0;
      end
end

//slt_data_A
always @(*) begin: get_slt_data_A
  if(ini_A[Q_r]==1)begin
      slt_data_A <= 'd1024;
  end else if (Q_r2==Q_r) begin
      slt_data_A <= A_next_r;
  end else begin
      slt_data_A <= A_RAM; 
  end
end

//SIGN_E
always @(*) begin: get_SIGN_E
	if (Errval[WIDTH_Errval-1] == 1'b1) begin
		SIGN_E <= 1'b1;
	end else begin
		SIGN_E <= 1'b0;
	end
end

//A_add
always @(*) begin
	if (SIGN_E==1'b0) begin
		A_add	<=	slt_data_A + {{WIDTH_A-WIDTH_Errval{Errval[WIDTH_Errval-1]}}, Errval};
	end else begin
		A_add	<=	slt_data_A - {{WIDTH_A-WIDTH_Errval{Errval[WIDTH_Errval-1]}}, Errval};
	end
end

//A_sl
always @(*) begin:get_A_sl
	if(slt_data_N == RESET) begin
	   A_sl <= {A_add[WIDTH_A-1], A_add[WIDTH_A-1:1]};
	end else begin
	   A_sl <= A_add;
	end
end

assign A_upt = A_sl;

// always @(*) begin: get_A_upt
// 	if(slt_data_N == RESET && SIGN_E == 1'b1)begin
// 		//A_upt <= (slt_data - ErrVal) >> 1;
// 		A_upt <= {1'b0, slt_data_A[WIDTH_A-1:1]} - {{WIDTH_A-WIDTH_Errval{Errval[WIDTH_Errval-1]}}, Errval[WIDTH_Errval-1:1]} - ((~slt_data_A[0]) & Errval[0]);
// 	end else if(slt_data_N == RESET && SIGN_E == 1'b0)begin
// 		//A_upt <= (slt_data + ErrVal) >> 1;
// 		A_upt <= {1'b0, slt_data_A[WIDTH_A-1:1]} + {{WIDTH_A-WIDTH_Errval{Errval[WIDTH_Errval-1]}}, Errval[WIDTH_Errval-1:1]} + (slt_data_A[0] & Errval[0]);
// 	end else if (SIGN_E == 1'b1) begin
// 		A_upt <= slt_data_A - {{WIDTH_A-WIDTH_Errval{Errval[WIDTH_Errval-1]}},Errval};
// 	end else begin
// 		A_upt <= slt_data_A + {{WIDTH_A-WIDTH_Errval{Errval[WIDTH_Errval-1]}},Errval};
// 	end
// end


ram_A 			ram_A_inst (
  .clka 				 (clk),    // input wire clka
  .ena 					 (en_r),      // input wire ena
  .wea 					 ('d0),      // input wire [0 : 0] wea
  .addra 				 (Q),  // input wire [8 : 0] addra
  .dina 				 ('d0),    // input wire [8 : 0] dina
  .douta 				 (A_RAM),  // output wire [8 : 0] douta
  .clkb 				 (clk),    // input wire clkbS
  .enb 					 (en_r2),      // input wire enb
  .web 					 ('d1),      // input wire [0 : 0] web
  .addrb 				 (Q_r),  // input wire [8 : 0] addrb
  .dinb 				 (A_upt),    // input wire [8 : 0] dinb
  .doutb 				 ()  // output wire [8 : 0] doutb
);

//B[Q]

always @(posedge clk or negedge rst_n) begin: get_B_next_r
  if (rst_n==0) begin
      B_next_r <= 0;
  end else if(en_r == 1'b1) begin
      B_next_r <= B_next;
  end
end

assign B_next = B_upt_p;

//ini
always@(posedge clk or negedge rst_n) begin:get_ini_B
      if(rst_n==0)begin 
          ini_B <= ~'d0;
      end else if(en_r2 == 1'b1) begin
          ini_B[Q_r] <= 'd0;
      end
end

//slt_data
always @(*) begin:get_slt_data_B
  if(ini_B[Q_r]==1)begin
      slt_data_B <= 0;
  // end else if(N_upt == RESET-1)begin
  // 	  slt_data_B <= B_sl;
  end else if (Q_r2==Q_r) begin
      slt_data_B <= B_next_r;
  end else begin
      slt_data_B <= B_RAM; 
  end
end


//assign B_add = {{(WIDTH_B_add-WIDTH_B_upt){1'b0}},slt_data_B} + {{(WIDTH_B_add-WIDTH_Errval){Errval[WIDTH_Errval-1]}},Errval};
assign B_add = {{(WIDTH_B_add-WIDTH_B_upt){slt_data_B[WIDTH_B_upt-1]}},slt_data_B} + {{(WIDTH_B_add-WIDTH_Errval){Errval[WIDTH_Errval-1]}},Errval};

always @(*) begin:get_B_sl
	if(slt_data_N == RESET) begin
	   B_sl <= {B_add[WIDTH_B_add-1], B_add[WIDTH_B_add-1:1]};//B_sl <= {1'b0, B_add[WIDTH_B_add-1:1]};
	end else begin
	   B_sl <= B_add;
	end
end

always @(*) begin: get_N_upt_n
	N_upt_n <= 0 - {1'b0, N_upt};
	N_upt_s2_n <= 0 - {1'b0, N_upt, 1'b0};
end

always @(*)begin:get_B_upt_p
	if(B_sl > {{{WIDTH_B_add-WIDTH_N{1'b0}},N_upt}} && B_sl[WIDTH_B_add-1] == 0)begin
		B_upt_p <= 18'd0;
	end else if(B_sl[WIDTH_B_add-1] == 0 && B_sl != 18'd0)begin
		B_upt_p <= B_sl - {{{WIDTH_B_add-WIDTH_N{1'b0}},N_upt}}; //{{WBSL-WN{1'b0}},N_upt}
	end else if((B_sl[WIDTH_B_add-1] == 1 && (B_sl > {{WIDTH_B_add-WIDTH_N-1{N_upt_n[WIDTH_N]}}, N_upt_n})) || (B_sl == 18'd0))begin
		B_upt_p <= B_sl;
	end else if(B_sl[WIDTH_B_add-1] == 1 && B_sl > {{(WIDTH_B_add-WIDTH_N-2){N_upt_s2_n[WIDTH_N+1]}}, N_upt_s2_n})begin
		B_upt_p <= B_sl + {{{WIDTH_B_add-WIDTH_N{1'b0}},N_upt}};
	end else begin 
    	B_upt_p <= 18'd1-{{{WIDTH_B_add-WIDTH_N{1'b0}},N_upt}};
    end 
end

assign B_upt  = B_upt_p[8:0];

// always @(*) begin
// 	if (en_r2 == 1'b1) begin
// 		B_upt <= slt_data_B + ErrVal;
// 	end else if(N_upt >= 64)begin
// 		B_upt <= B_upt >> 1 ;
// 	end else if(B_upt > 0) begin
// 		B_upt <= B_upt - N_upt;
// 	end else if((B_upt -  N_upt) > 0) begin
// 		B_upt <= 0;
// 	end else if(N_upt[16] == 1'b1 && B_upt > N_upt) begin
// 		B_upt <= B_upt + N_upt;
// 	end else if(N_upt[16]==1'b1 && (B_upt+N_upt) > N_upt) begin
// 		B_upt <= 1 - N_upt;
// 	end else begin
// 	    B_upt <= B_upt;
// 	end
// end




ram_B 			ram_B_inst (
  .clka 				 (clk),    // input wire clka
  .ena 					 (en_r),      // input wire ena
  .wea 					 ('d0),      // input wire [0 : 0] wea
  .addra 				 (Q),  // input wire [8 : 0] addra
  .dina 				 ('d0),    // input wire [8 : 0] dina
  .douta 				 (B_RAM),  // output wire [8 : 0] douta
  .clkb 				 (clk),    // input wire clkbS
  .enb 					 (en_r2),      // input wire enb
  .web 					 ('d1),      // input wire [0 : 0] web
  .addrb 				 (Q_r),  // input wire [8 : 0] addrb
  .dinb 				 (B_upt),    // input wire [8 : 0] dinb
  .doutb 				 ()  // output wire [8 : 0] doutb
);

//N[Q]

always @(posedge clk or negedge rst_n) begin:get_N_next_r
  if (rst_n==0) begin
      N_next_r <= 0;
  end else if(en_r == 1'b1) begin
      N_next_r <= N_next;
  end
end

assign N_next = N_upt;

//ini
always@(posedge clk or negedge rst_n) begin:get_ini_N
      if(rst_n==0)begin 
          ini_N <= ~'d0;
      end else if(en_r2 == 1'b1) begin
          ini_N[Q_r] <= 'd0;
      end
end

//slt_data
always @(*) begin:get_slt_data_N
  if(ini_N[Q_r]==1)begin
      slt_data_N <= 'd1;
  end else if (Q_r2==Q_r) begin
      slt_data_N <= N_next_r;
  end else begin
      slt_data_N <= N_RAM; 
  end
end


always @(*) begin:get_N_upt
	if(slt_data_N == RESET)begin
		N_upt <= 6'd33;
	end else begin
		N_upt <= slt_data_N + 1;
	end
end
//assign N_upt_p = N_upt + 1;


ram_N 			ram_N_inst (
  .clka 				 (clk),    // input wire clka
  .ena 					 (en_r),      // input wire ena
  .wea 					 ('d0),      // input wire [0 : 0] wea
  .addra 				 (Q),  // input wire [8 : 0] addra
  .dina 				 ('d0),    // input wire [8 : 0] dina
  .douta 				 (N_RAM),  // output wire [8 : 0] douta
  .clkb 				 (clk),    // input wire clkbS
  .enb 					 (en_r2),      // input wire enb
  .web 					 ('d1),      // input wire [0 : 0] web
  .addrb 				 (Q_r),  // input wire [8 : 0] addrb
  .dinb 				 ({3'b0,N_upt}),    // input wire [8 : 0] dinb
  .doutb 				 ()  // output wire [8 : 0] doutb
);



//C[Q]

always @(posedge clk or negedge rst_n) begin:get_C_next_r
  if (rst_n==0) begin
      C_next_r <= 0;
  end else if(en_r == 1'b1) begin
      C_next_r <= C_next;
  end
end

assign C_next = C_upt_limit;

//ini
always@(posedge clk or negedge rst_n) begin:get_ini_C
      if(rst_n==0)begin 
          ini_C <= ~'d0;
      end else if(en_r2 == 1'b1) begin
          ini_C[Q_r] <= 'd0;
      end
end

//slt_data
always @(*) begin:get_slt_data_C
  if(ini_C[Q_r]==1)begin
      slt_data_C <= 0;
  end else if (Q_r2==Q_r) begin
      slt_data_C <= C_next_r;
  end else begin
      slt_data_C <= C_RAM; 
  end
end

always @(*)begin:get_C_upt
	if(B_sl > {{{WIDTH_B_add-WIDTH_N{1'b0}},N_upt}} && B_sl[WIDTH_B_add-1] == 0)begin
		C_upt <= slt_data_C + 1'b1;
	end else if(B_sl[WIDTH_B_add-1] == 0 && B_sl != 18'd0)begin
		C_upt <= slt_data_C + 1'b1;
	end else if(B_sl[WIDTH_B_add-1] == 1 && (B_sl > {{WIDTH_B_add-WIDTH_N-1{N_upt_n[WIDTH_N]}}, N_upt_n}) || (B_sl == 18'd0))begin
		C_upt <= slt_data_C;
	end else if(B_sl[WIDTH_B_add-1] == 1 && B_sl > {{(WIDTH_B_add-WIDTH_N-2){N_upt_s2_n[WIDTH_N+1]}}, N_upt_s2_n})begin
		C_upt <= slt_data_C - 1'b1;
	end else begin
    	C_upt <= slt_data_C - 1'b1;
    end
end

always @(*) begin
	if (C_upt[WIDTH_C_upt-1]==1'b0 && C_upt>C_MAX) begin
		C_upt_limit <= C_MAX;
	end else if(C_upt[WIDTH_C_upt-1]==1'b1 && C_upt<C_MIN) begin
		C_upt_limit <= C_MIN;
	end else begin
		C_upt_limit <= C_upt;
	end
end

ram_C 			ram_C_inst (
  .clka 				 (clk),    // input wire clka
  .ena 					 (en_r),      // input wire ena
  .wea 					 ('d0),      // input wire [0 : 0] wea
  .addra 				 (Q),  // input wire [8 : 0] addra
  .dina 				 ('d0),    // input wire [8 : 0] dina
  .douta 				 (C_RAM),  // output wire [8 : 0] douta
  .clkb 				 (clk),    // input wire clkbS
  .enb 					 (en_r2),      // input wire enb
  .web 					 ('d1),      // input wire [0 : 0] web
  .addrb 				 (Q_r),  // input wire [8 : 0] addrb
  .dinb 				 (C_upt_limit),    // input wire [8 : 0] dinb
  .doutb 				 ()  // output wire [8 : 0] doutb
);

always @ (*)begin:get_k
if ({17'd0,N_upt} >= A_upt)
	K <= 'd0;
else if ({16'd0,slt_data_N, 1'd0} >= slt_data_A)
	K <= 'd1;
else if ({15'd0,slt_data_N, 2'd0} >= slt_data_A)
	K <= 'd2;
else if ({14'd0,slt_data_N, 3'd0} >= slt_data_A)
	K <= 'd3;
else if ({13'd0,slt_data_N, 4'd0} >= slt_data_A)
	K <= 'd4;
else if ({12'd0,slt_data_N, 5'd0} >= slt_data_A)
	K <= 'd5;
else if ({11'd0,slt_data_N, 6'd0} >= slt_data_A)
	K <= 'd6;
else if ({10'd0,slt_data_N, 7'd0} >= slt_data_A)
	K <= 'd7;
else if ({9'd0,slt_data_N, 8'd0} >= slt_data_A)
	K <= 'd8;
else if ({8'd0,slt_data_N, 9'd0} >= slt_data_A)
	K <= 'd9;
else if ({7'd0,slt_data_N, 10'd0} >= slt_data_A)
	K <= 'd10;
else if ({6'd0,slt_data_N, 11'd0} >= slt_data_A)
	K <= 'd11;
else if ({5'd0,slt_data_N, 12'd0} >= slt_data_A)
	K <= 'd12;
else if ({4'd0,slt_data_N, 13'd0} >= slt_data_A)
	K <= 'd13;
else if ({3'd0,slt_data_N, 14'd0} >= slt_data_A)
	K <= 'd14;
else if ({2'd0,slt_data_N, 15'd0} >= slt_data_A)
	K <= 'd15;
else 
    K <= 'd15;
end


endmodule



