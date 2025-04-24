`timescale 1ns/1ps
module fir24_pruned_q15 #(
    
    parameter L           = 65,      
    parameter NZ          = 24,     
    parameter IN_W        = 16,     
    parameter COEF_W      = 16,    
    parameter MUL_W       = 32,   
    parameter ACC_W       = 40     
)(
    input  wire                      clk,
    input  wire                      rst_n,

    input  wire signed [IN_W-1:0]    data_in,
    input  wire                      data_in_valid,

    output reg  signed [ACC_W-1:0]   data_out,
    output reg                       data_out_valid
);
    
    localparam signed [COEF_W-1:0] COEF_ROM [0:NZ-1] = {
        16'sh009A,       
        16'sh00DF,       
        16'shFE0F,        
        16'shFE00,       
        16'shFF5F,       
        16'shFB71,        
        16'sh0073,        
        16'shFB4E,       
        16'sh003B,       
        16'sh02F7,        
        16'shFFB5,        
        16'sh2858,        
        16'shC2D9,        
        16'sh2858,       
        16'shFFB5,       
        16'sh02F7,       
        16'sh003B,        
        16'shFB4E,       
        16'sh0073,        
        16'shFB71,      
        16'shFE00,        
        16'shFE0F,       
        16'sh00DF,        
        16'sh009A     
    };

    
    localparam [6:0] NONZERO_IDX [0:NZ-1] = {
        7'd17,  7'd19,  7'd21,  7'd23,  7'd24,  7'd25,  7'd26,
        7'd27,  7'd28,  7'd29,  7'd30,  7'd31,  7'd32,  7'd33,
        7'd34,  7'd35,  7'd36,  7'd37,  7'd38,  7'd39,  7'd41,
        7'd43,  7'd45,  7'd47
    };

    
    reg signed [IN_W-1:0] dline [0:L-1];
    integer i;
    always @(posedge clk)
        if (data_in_valid) begin
            for (i=L-1; i>0; i=i-1)
                dline[i] <= dline[i-1];
            dline[0] <= data_in;
        end

    
    localparam ST_IDLE = 2'd0,
               ST_MAC  = 2'd1,
               ST_OUT  = 2'd2;
    reg [1:0] state;
    reg [5:0] k;                        
    reg signed [ACC_W-1:0] acc;
    reg signed [MUL_W-1:0] mult;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= ST_IDLE;
            k              <= 0;
            acc            <= 0;
            data_out       <= 0;
            data_out_valid <= 0;
        end else begin
            data_out_valid <= 0;

            case (state)
            
            ST_IDLE: if (data_in_valid) begin
                k   <= 0;
                acc <= 0;
                state <= ST_MAC;
            end
            
            ST_MAC: begin
                mult <=  $signed(dline[ NONZERO_IDX[k] ]) *
                         $signed(COEF_ROM[k]);
                acc  <=  acc + {{(ACC_W-MUL_W){mult[MUL_W-1]}}, mult};

                if (k == NZ-1)
                    state <= ST_OUT;
                else
                    k <= k + 1'b1;
            end
           
            ST_OUT: begin
                data_out       <= acc;
                data_out_valid <= 1'b1;
                state          <= ST_IDLE;
            end
            
            endcase
        end
    end
endmodule

