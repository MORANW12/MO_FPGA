// Author : MORAN
// File   : Pixel_Rec.v
// Create : 2022-04-06 09:31:33
// Revise : 2022-04-08 10:28:12
// Editor : sublime text4, tab size (4)
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module Pixel_Rec(
  //input ports
  input wire clk,
  input wire rst_n,
  input wire [15:0] pixel_data,
  input wire data_en,
  //outputs ports
  output reg [15:0] Rx,
  output reg [15:0] Ra,
  output reg [15:0] Rb,
  output reg [15:0] Rc,
  output reg [15:0] Rd,
  output wire [15:0] D1,
  output wire [15:0] D2,
  output wire [15:0] D3,
  output reg out_en
);
 
//image sizes
parameter IMAGE_W = 256;
parameter IMAGE_H = 256;

reg data_en_r;
//fifo 
wire        wr_en;
reg         rd_en;
reg  [9:0]  cnt_col;
reg  [9:0]  cnt_row;
wire [15:0] dout;

reg [15:0] dout_r; 
reg [15:0] Rx_r; 



always @(posedge clk or negedge rst_n) begin : proc_daen_en_r
    if(~rst_n) begin
        data_en_r <= 1'b0;
    end else begin
        data_en_r <= data_en;
    end
end
always @ (posedge clk or negedge rst_n)  begin :proc_cnt_col
    if(rst_n==1'b0) begin
        cnt_col <= 'd0;
    end
    else if (cnt_col==(IMAGE_W-1)) begin
        cnt_col <= 'd0;     
    end
    else if(data_en_r==1'b1) begin
        cnt_col <= cnt_col + 1;
    end
end
always @ (posedge clk or negedge rst_n)  begin :proc_cnt_row
    if(rst_n==1'b0) begin
        cnt_row <= 'd0;
    end
    else if (cnt_row==(IMAGE_H)&&cnt_col==(IMAGE_W-1)) begin
        cnt_row <= cnt_row;     
    end
    else if(cnt_col==(IMAGE_W-1)) begin
        cnt_row <= cnt_row + 1;
    end
end

//wr_en
    assign wr_en = data_en;

//rd_en
always @ (posedge clk or negedge rst_n)  begin :proc_rd_en
    if(rst_n==1'b0) begin
        rd_en <= 1'b0;
    end
    else if(cnt_col==IMAGE_W-2&&cnt_row==0) begin
        rd_en <= 1'b1;
    end
end

always @(posedge clk or negedge rst_n) begin : proc_Rd
    if(~rst_n) begin
        Rd <= 0;
    end 
    else if (cnt_col==0) begin
        Rd <= Rd;
    end
    else begin
        Rd <= dout;
    end
end
always @(posedge clk or negedge rst_n) begin : proc_dout_r
    if(~rst_n) begin
        dout_r <= 'd0;
    end else begin
        dout_r <= dout;
    end
end
always @(posedge clk or negedge rst_n) begin : proc_Rb
    if(~rst_n) begin
        Rb <= 0;
    end
    else begin
        Rb <= dout_r;
    end
end
always @(posedge clk or negedge rst_n) begin : proc_Rc
    if(~rst_n) begin
        Rc <= 0;
    end
    else if(cnt_col==1) begin
        Rc <= dout_r;
    end
    else begin
        Rc <= Rb;
    end
end

always @(posedge clk or negedge rst_n) begin : proc_Rx_r
    if(~rst_n) begin
        Rx_r <= 0;
    end else begin
        Rx_r <= pixel_data;
    end
end
always @(posedge clk or negedge rst_n) begin : proc_Rx
    if(~rst_n) begin
        Rx <= 0;
    end else begin
        Rx <= Rx_r;
    end
end
always @(posedge clk or negedge rst_n) begin : proc_Ra
    if(~rst_n) begin
        Ra <= 0;
    end 
    else if (cnt_col==1) begin
        Ra <= dout_r;
    end
    else begin
        Ra <= Rx;
    end
end
always @(posedge clk or negedge rst_n) begin : proc_out_en
    if(~rst_n) begin
        out_en <= 1'b0;
    end 
    else if(cnt_col==1&&cnt_row==0)begin
        out_en <= 1'b1;
    end
    else if(cnt_col==1&&cnt_row==IMAGE_H||cnt_row==256) begin
        out_en <= 1'b0;
    end
end

 assign D1 = (out_en)?Rd-Rb:'dz;
 assign D2 = (out_en)?Rb-Rc:'dz;
 assign D3 = (out_en)?Rc-Ra:'dz;
data_model1 data_model1_inst (
  .clk(clk),      // input wire clk
  .din(pixel_data),      // input wire [15 : 0] din
  .wr_en(wr_en),  // input wire wr_en
  .rd_en(rd_en),  // input wire rd_en
  .dout(dout)    // output wire [15 : 0] dout
);
endmodule
