// Author : MORAN
// File   : test.v
// Create : 2022-04-06 09:37:33
// Revise : 2022-04-06 09:37:33
// Editor : sublime text4, tab size (4)
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module Pixel_Rec(
  //input ports
  input wire clk,
  input wire rst_n,
  input wire [15:0] pixel_data,
  input wire data_en,
  // output ports
  output reg [15:0] Ra,
  output reg [15:0] Rb,
  output reg [15:0] Rc,
  output reg [15:0] Rd,
  output reg [15:0] Rx_r,
  output wire [15:0] D1,
  output wire [15:0] D2,
  output wire [15:0] D3,
  output reg        calu_flag
);
//image sizes
parameter IMAGE_W = 11;
parameter IMAGE_H = 9;
reg [9:0] col;
//fifo 1
reg        wr_en;
reg        rd_en;
reg [9:0]  cnt_col;
reg [9:0]  cnt_row;


 wire[15:0] Rx;
// reg [15:0] Rx_r;       
// reg [15:0] Ra;
// reg [15:0] Rc;
// reg [15:0] Rb;
// wire [15:0] Rd;
wire [15:0]D1_r;
wire [15:0]D2_r;
wire [15:0]D3_r;
// wire [15:0] D1;
// wire [15:0] D2;
// wire [15:0] D3;
// reg         calu_flag;

always @ (posedge clk or negedge rst_n)  begin :proc_cnt_col
    if(rst_n==1'b0) begin
        cnt_col <= 'd0;
    end
    else if (cnt_col==(IMAGE_W-1)) begin
        cnt_col <= 'd0;     
    end
    else if(data_en==1'b1) begin
        cnt_col <= cnt_col + 1;
    end
end

always @ (posedge clk or negedge rst_n)  begin :proc_cnt_row
    if(rst_n==1'b0) begin
        cnt_row <= 'd0;
    end
    else if (cnt_row==(IMAGE_H-1)&&cnt_col==(IMAGE_W-1)) begin
        cnt_row <= 'd0;     
    end
    else if(cnt_col==(IMAGE_W-1)) begin
        cnt_row <= cnt_row + 1;
    end
end

//fifo 1 :to Complete the line of the picture
//wr_en1
    assign wr_en = data_en;
// always @ (posedge clk or negedge rst_n)  begin :proc_wr_en
//     if(rst_n==1'b0) begin
//         wr_en <= 1'b0;
//     end
//     else  begin
//         wr_en <= data_en;
//     end
// end

//rd_en
always @ (posedge clk or negedge rst_n)  begin :proc_rd_en
    if(rst_n==1'b0) begin
        rd_en <= 1'b0;
    end
    else if(cnt_col<=IMAGE_W-1&&rd_flag==1'b1) begin
        rd_en <= 1'b1;
    end
    else begin
        rd_en <= 1'b0;
    end
end


//The current line



//The previous line
assign dout2 =(rd_en2==1'b1)?dout_t:'d0 ;

//caculate D1 D2 D3
assign Rd = dout2;

always @ (posedge clk or negedge rst_n)  begin :proc_Rb
    if(rst_n==1'b0) begin
        Rb <= 'd0;
    end
    else if(data_en==1'b1) begin
        Rb <= Rd;
    end
end
always @ (posedge clk or negedge rst_n)  begin :proc_Rc
    if(rst_n==1'b0) begin
        Rc <= 'd0;
    end
    else if(data_en==1'b1) begin
        Rc <= Rb;
    end
end
assign Rx = dout;
always @ (posedge clk or negedge rst_n)  begin :proc_Rx_r
    if(rst_n==1'b0) begin
        Rx_r <= 'd0;
    end
    else if(data_en==1'b1) begin
        Rx_r <= Rx;
    end
end
always @ (posedge clk or negedge rst_n)  begin :proc_Ra
    if(rst_n==1'b0) begin
        Ra <= 'd0;
    end
    else if(data_en==1'b1) begin
        Ra <= Rx_r;
    end
end
assign D1_r = (cnt_col>1&&cnt_col<=12)?Rd-Rb:'dz;
assign D2_r = (cnt_col>1&&cnt_col<=12)?Rb-Rc:'dz;
assign D3_r = (cnt_col>1&&cnt_col<=12)?Rc-Ra:'dz;

assign D1 = (D1_r[15]==0)?D1_r:(~D1_r+1'b1);
assign D2 = (D2_r[15]==0)?D2_r:(~D2_r+1'b1);
assign D3 = (D3_r[15]==0)?D3_r:(~D3_r+1'b1);

data_model1 data_model1_inst (
  .clk(clk),      // input wire clk
  .din(pixel_data),      // input wire [15 : 0] din
  .wr_en(wr_en),  // input wire wr_en
  .rd_en(rd_en),  // input wire rd_en
  .dout(dout1)    // output wire [15 : 0] dout
);
endmodule
