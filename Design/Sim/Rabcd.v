// Author : MORAN
// File   : Rabcd.v
// Create : 2022-04-09 09:25:36
// Revise : 2022-04-09 09:25:36
// Editor : sublime text4, tab size (8)
// -----------------------------------------------------------------------------
`timescale 1ns / 1ps

module sim_test();

        // input data
        reg clk;
        reg rst_n;
        reg data_en;
        reg [15:0] pixel_data=0;
        //output data
        wire [15:0] Ra;
        wire [15:0] Rb;
        wire [15:0] Rc;
        wire [15:0] Rd;
        wire out_en;

        //test data
        reg [15:0] ra='d0;
        reg [15:0] rb='d0;
        reg [15:0] rc='d0;
        reg [15:0] rd='d0;

        reg  Ra_flag=1'b0;
        reg  Rb_flag=1'b0;
        reg  Rc_flag=1'b0;
        reg  Rd_flag=1'b0;
        integer file_path;
        integer Ra_path;
        integer Rb_path;
        integer Rc_path;
        integer Rd_path;


        initial begin
                Ra_path=$fopen("F:/FPGA/JPEG_LS/Matlab_Prj/Rabcd/Ra.txt","r");
                Rb_path=$fopen("F:/FPGA/JPEG_LS/Matlab_Prj/Rabcd/Rb.txt","r");
                Rc_path=$fopen("F:/FPGA/JPEG_LS/Matlab_Prj/Rabcd/Rc.txt","r");
                Rd_path=$fopen("F:/FPGA/JPEG_LS/Matlab_Prj/Rabcd/Rd.txt","r");
        
                file_path=$fopen("F:/FPGA/JPEG_LS/matlab/one/Ix.txt","r");
        end

        initial begin
                clk = 'd0;
                forever #(5) clk = ~clk;
        end

        initial begin
                data_en <= 1'b0;
                rst_n <= 'd0;
                repeat(10)@(posedge clk);
                rst_n <= 'd1;
                repeat(10)@(posedge clk);
                data_en <= 1'b1;
        end

        always @ (posedge clk)  begin :proc_pixel_data
            if (data_en==1'b1) begin
                $fscanf(file_path,"%d",pixel_data); 
            end   
        end
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
                .out_en     (out_en)
        );

        always @(posedge clk or negedge rst_n) begin : proc_data_out
                if(out_en==1'b1) begin
                        $fscanf(Ra_path,"%d",ra);
                        $fscanf(Rb_path,"%d",rb);
                        $fscanf(Rc_path,"%d",rc);
                        $fscanf(Rd_path,"%d",rd);
                end
        end
        always @(posedge clk or negedge rst_n) begin : proc_compare_a
                if (out_en==1'b1&&ra!=Ra) begin
                    Ra_flag<=1'b1;
                end
        end
        always @(posedge clk or negedge rst_n) begin : proc_compare_b
                if (out_en==1'b1&&rb!=Rb) begin
                    Rb_flag<=1'b1;
                end
        end
        always @(posedge clk or negedge rst_n) begin : proc_compare_c
                if (out_en==1'b1&&rc!=Rc) begin
                    Rc_flag<=1'b1;
                end
        end
        always @(posedge clk or negedge rst_n) begin : proc_compare_d
                if (out_en==1'b1&&rd!=Rd) begin
                    Rd_flag<=1'b1;
                end
        end


endmodule
