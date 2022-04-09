module JPEG_LS_top (
	input wire clk,    // Clock
	input wire rst_n,  // Asynchronous reset active low
	input wire [15:0] pixel_data,
	input wire data_en,
	output wire [3:0] Q1,
	output wire [3:0] Q2,
	output wire [3:0] Q3,
	output wire [15:0] Px,
	output wire en
);
wire [15:0] Rx;
wire [15:0] Ra;
wire [15:0] Rb;
wire [15:0] Rc;
wire [15:0] Rd;
wire [16:0] D1;
wire [16:0] D2;
wire [16:0] D3;
wire out_en;
	Pixel_Rec inst_Pixel_Rec (
			.clk        (clk),
			.rst_n      (rst_n),
			.pixel_data (pixel_data),
			.data_en    (data_en),
			.Rx         (Rx),
			.Ra         (Ra),
			.Rb         (Rb),
			.Rc         (Rc),
			.Rd         (Rd),
			.D1         (D1),
			.D2         (D2),
			.D3         (D3),
			.out_en     (out_en)
		);
	Predict inst_Predict
		(
			.clk        (clk),
			.rst_n      (rst_n),
			.Rx         (Rx),
			.Ra         (Ra),
			.Rb         (Rb),
			.Rc         (Rc),
			.Rd         (Rd),
			.D1         (D1),
			.D2         (D2),
			.D3         (D3),
			.data_en    (out_en),
			.Q1         (Q1),
			.Q2         (Q2),
			.Q3         (Q3),
			.Px         (Px),
			.en         (en)
		);

endmodule : JPEG_LS_top