// Author : MORAN
// File   : Q123.V
// Create : 2022-04-04 16:29:41
// Revise : 2022-04-09 16:56:34
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

        wire en;
        wire [3:0] Q1;
        wire [3:0] Q2;
        wire [3:0] Q3;
        wire [15:0] Px;
        wire da_en;

        //test data
        reg [3:0] q1='d0;
        reg [3:0] q2='d0;
        reg [3:0] q3='d0;
        reg [15:0] px='d0;

        reg  Q1_flag=1'b0;
        reg  Q2_flag=1'b0;
        reg  Q3_flag=1'b0;
        reg  Px_flag=1'b0;
        
        integer file_path;
        integer Q1_path;
        integer Q2_path;
        integer Q3_path;
        integer Px_path;
        initial begin
                force da_en = inst_JPEG_LS_top.inst_Predict.en;
        end


        initial begin
                Q1_path=$fopen("F:/FPGA/JPEG_LS/Matlab_Prj/Q123Px/Q1.txt","r");
                Q2_path=$fopen("F:/FPGA/JPEG_LS/Matlab_Prj/Q123Px/Q2.txt","r");
                Q3_path=$fopen("F:/FPGA/JPEG_LS/Matlab_Prj/Q123Px/Q3.txt","r");
                Px_path=$fopen("F:/FPGA/JPEG_LS/Matlab_Prj/Q123Px/Px.txt","r");
        
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
        JPEG_LS_top inst_JPEG_LS_top
                (
                        .clk        (clk),
                        .rst_n      (rst_n),
                        .pixel_data (pixel_data),
                        .data_en    (data_en),
                        .Q1         (Q1),
                        .Q2         (Q2),
                        .Q3         (Q3),
                        .Px         (Px),
                        .en         (en)
                );


        always @(posedge clk or negedge rst_n) begin : proc_data_out
                if(da_en==1'b1) begin
                        $fscanf(Q1_path,"%d",q1);
                        $fscanf(Q2_path,"%d",q2);
                        $fscanf(Q3_path,"%d",q3);
                        $fscanf(Px_path,"%d",px);
                end
        end
        always @(posedge clk or negedge rst_n) begin : proc_compare_Q1
                if (da_en==1'b1&&q1!=Q1) begin
                        Q1_flag<=1'b1;
                end
        end
        always @(posedge clk or negedge rst_n) begin : proc_compare_Q2
                if (da_en==1'b1&&q2!=Q2) begin
                    Q2_flag<=1'b1;
                end
        end
        always @(posedge clk or negedge rst_n) begin : proc_compare_Q3
                if (da_en==1'b1&&q3!=Q3) begin
                    Q3_flag<=1'b1;
                end
        end
        always @(posedge clk or negedge rst_n) begin : proc_compare_Px
                if (da_en==1'b1&&px!=Px) begin
                    Px_flag<=1'b1;
                end
        end


endmodule
