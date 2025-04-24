`timescale 1ns/1ps
module fir24_pruned_q15_tb;

    localparam L        = 31;  
    localparam NZ       = 24;  
    localparam IN_W     = 16;
    localparam COEF_W   = 16;
    localparam MUL_W    = 32;
    localparam ACC_W    = 40;

    
    reg                       clk;
    reg                       rst_n;
    reg  signed [IN_W-1:0]    data_in;
    reg                       data_in_valid;
    wire signed [ACC_W-1:0]   data_out;
    wire                      data_out_valid;

    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    
    fir24_pruned_q15 #(
        .L       (L),
        .NZ      (NZ),
        .IN_W    (IN_W),
        .COEF_W  (COEF_W),
        .MUL_W   (MUL_W),
        .ACC_W   (ACC_W)
    ) dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .data_in        (data_in),
        .data_in_valid  (data_in_valid),
        .data_out       (data_out),
        .data_out_valid (data_out_valid)
    );

    
    initial begin
        
        rst_n         = 0;
        data_in       = 0;
        data_in_valid = 0;
        #100;
        rst_n = 1;
        #20;

        
        send_sample(16'h4000);

        #800;
        send_sample(16'h3000);

        #500;
        $finish;
    end

    task automatic send_sample(input signed [IN_W-1:0] val);
        begin
            @(posedge clk);
            data_in       <= val;
            data_in_valid <= 1'b1;
            @(posedge clk);
            data_in_valid <= 1'b0;
            data_in       <= 0;
        end
    endtask

    always @(posedge clk) begin
        if (rst_n && data_out_valid) begin
            $display("T=%0t_ns : data_out = %0d (0x%h)",
                      $time, data_out, data_out);
        end
    end

endmodule

