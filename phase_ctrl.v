///////////////////////////////////////////////////////////////
////
////
////
////   author : zhengquan
////   date   : 2017/2/23
////   function: phase adjustment    
////
///////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module phase_ctrl(
                  input             clk,
                  input             resetn,
                  
                  input             i2c_wr,
                  input  [15:0]     i2c_wdata,
                  input  [3:0]      i2c_addr,
                  
                  input             fifo_empty,
                  input  [17:0]     fifo_rdata,
                  output reg        fifo_rden,
                  
                  output reg [17:0] fifo_wdata,
                  output reg        fifo_wren,
                  input             fifo_almost_full
                      
                 );

reg signed [15:0]    a;
reg signed [15:0]    b;

reg signed [31:0]    v1;
reg signed [31:0]    v2;
reg signed [31:0]    v3;
reg        [15:0]    v4;
reg signed [31:0]    v5;
reg signed [31:0]    v6;

reg signed [15:0]    last_v1;
reg signed [15:0]    last_v2;
reg signed [15:0]    last_v3;
reg signed [15:0]    last_v5;
reg signed [15:0]    last_v6;
reg signed [15:0]    temp1;
reg signed [15:0]    temp2;
wire signed [31:0]    result1;
wire signed [31:0]    result2;
reg           aclr;
reg           multiplier_valid;
reg           multiplier_valid_r;
reg           multiplier_valid_r1;
reg           multiplier_valid_r2;
reg           multiplier_valid_r3;

reg          fifo_rden_r;

reg [6:0]    cs_state;
reg [6:0]    ns_state;

parameter     IDLE    =  7'b000_0001,
	      V1_PROC =  7'b000_0010,
	      V2_PROC =  7'b000_0100,
	      V3_PROC =  7'b000_1000,
	      V4_PROC =  7'b001_0000,
	      V5_PROC =  7'b010_0000,
	      V6_PROC =  7'b100_0000;


always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
        cs_state <= IDLE;
      else
        cs_state <= ns_state;
end

always@(*)begin
   ns_state = cs_state;
   case(cs_state)
        IDLE      :   begin
                          if(!fifo_empty && !fifo_almost_full)
                             ns_state = V1_PROC;
                          else
                             ns_state = IDLE;
                      end
         
         V1_PROC  :   begin
                          if(multiplier_valid)
                             ns_state = V2_PROC;
                          else
                             ns_state = V1_PROC;
                      end
                      
         V2_PROC  :   begin
                          if(multiplier_valid)
                             ns_state = V3_PROC;
                          else
                             ns_state = V2_PROC;
                      end            
                      
         V3_PROC  :   begin
                          if(multiplier_valid)
                             ns_state = V4_PROC;
                          else
                             ns_state = V3_PROC;
                      end       
                      
         V4_PROC  :   begin
                          ns_state = V5_PROC;
                      end   
                      
         V5_PROC  :   begin
                          if(multiplier_valid)
                             ns_state = V6_PROC;
                          else
                             ns_state = V5_PROC;
                      end     
                      
         V6_PROC  :   begin
                          if(multiplier_valid)
                             ns_state = IDLE;
                          else
                             ns_state = V6_PROC;
                      end                                            
   endcase
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
         fifo_rden <= 1'b0;
      else if(cs_state == IDLE && ns_state == V1_PROC)
         fifo_rden <= 1'b1;
      else if(cs_state == V1_PROC && ns_state == V2_PROC)
         fifo_rden <= 1'b1;
      else if(cs_state == V2_PROC && ns_state == V3_PROC)
         fifo_rden <= 1'b1;
      else if(cs_state == V3_PROC && ns_state == V4_PROC)
         fifo_rden <= 1'b1;
      else if(cs_state == V4_PROC && ns_state == V5_PROC)
         fifo_rden <= 1'b1;
      else if(cs_state == V5_PROC && ns_state == V6_PROC)
         fifo_rden <= 1'b1;
      else 
         fifo_rden <= 1'b0;
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)begin
          a <= 16'h100;
          b <= 16'h100;
      end
      else if(i2c_wr)begin
          case(i2c_addr)
            4'b0000  : a <= i2c_wdata;
            4'b0001  : b <= i2c_wdata;
            default : begin
                      a <= a;
                      b <= b;
	      end
          endcase
      end     
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
	 v1 <= 32'h0;
      else if(cs_state == V1_PROC && ns_state == V2_PROC)
	 v1 <= result1 - result2;
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
	 v2 <= 32'h0;
      else if(cs_state == V2_PROC && ns_state == V3_PROC)
	 v2 <= result1 - result2;
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
	 v3 <= 32'h0;
      else if(cs_state == V3_PROC && ns_state == V4_PROC)
	 v3 <= result1 - result2;
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
	 v5 <= 32'h0;
      else if(cs_state == V5_PROC && ns_state == V6_PROC)
	 v5 <= result1 - result2;
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
	 v6 <= 32'h0;
      else if(cs_state == V6_PROC && multiplier_valid_r3)
	 v6 <= result1 - result2;
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
         temp1 <= 16'h0;
      else if(cs_state == V1_PROC)
         temp1 <= fifo_rdata; 
      else if(cs_state == V2_PROC)
         temp1 <= fifo_rdata; 
      else if(cs_state == V3_PROC)
         temp1 <= fifo_rdata; 
      else if(cs_state == V5_PROC)
         temp1 <= fifo_rdata; 
      else if(cs_state == V6_PROC)
         temp1 <= fifo_rdata; 
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
        temp2 <= 16'h0;
      else if(cs_state == IDLE && ns_state == V1_PROC)
        temp2 <= last_v1;
      else if(cs_state == V1_PROC && ns_state == V2_PROC)
        temp2 <= last_v2;
      else if(cs_state == V2_PROC && ns_state == V3_PROC)
        temp2 <= last_v3;
      else if(cs_state == V4_PROC && ns_state == V5_PROC)
        temp2 <= last_v5;
      else if(cs_state == V5_PROC && ns_state == V6_PROC)
        temp2 <= last_v6;
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
	 fifo_rden_r <= 1'b0;
      else
	 fifo_rden_r <= fifo_rden;
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
        aclr <= 1'b0;
      else if(cs_state == V1_PROC)
        aclr <= fifo_rden_r;
      else if(cs_state == V2_PROC)
        aclr <= fifo_rden_r;
      else if(cs_state == V3_PROC)
        aclr <= fifo_rden_r;
      else if(cs_state == V5_PROC)
        aclr <= fifo_rden_r&!aclr;
      else if(cs_state == V6_PROC)
        aclr <= fifo_rden_r;
      else
        aclr <= 1'b0;
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)begin
	 multiplier_valid <= 1'b0;
         multiplier_valid_r <= 1'b0; 
         multiplier_valid_r1 <= 1'b0; 
         multiplier_valid_r2 <= 1'b0; 
         multiplier_valid_r3 <= 1'b0;
      end 
      else begin
        multiplier_valid_r <= aclr;
	multiplier_valid_r1 <= multiplier_valid_r;
	multiplier_valid_r2 <= multiplier_valid_r1;
	multiplier_valid_r3 <= multiplier_valid_r2;
	multiplier_valid <= multiplier_valid_r3;
      end 
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
	  fifo_wren <= 1'b0;
      else if(cs_state == V5_PROC && aclr)
	  fifo_wren <= 1'b1;
      else if(cs_state == V5_PROC && multiplier_valid_r)
	  fifo_wren <= 1'b1;
      else if(cs_state == V5_PROC && multiplier_valid_r1)
	  fifo_wren <= 1'b1;
      else if(cs_state == V5_PROC && multiplier_valid_r2)
	  fifo_wren <= 1'b1;
      else if(cs_state == V6_PROC && aclr)
	  fifo_wren <= 1'b1;
      else if(cs_state == V6_PROC && ns_state == IDLE)
	  fifo_wren <= 1'b1;
      else 
	  fifo_wren <= 1'b0;
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
	  fifo_wdata <= 18'h0;
      else if(cs_state == V5_PROC && aclr)
	  fifo_wdata <= {2'b01,v4};
      else if(cs_state == V5_PROC && multiplier_valid_r)
	  fifo_wdata <= {2'b00,v1[23:8]};
      else if(cs_state == V5_PROC && multiplier_valid_r1)
	  fifo_wdata <= {2'b00,v2[23:8]};
      else if(cs_state == V5_PROC && multiplier_valid_r2)
	  fifo_wdata <= {2'b00,v3[23:8]};
      else if(cs_state == V6_PROC && aclr)
          fifo_wdata <= {2'b00,v5[23:8]};
      else if(cs_state == V6_PROC && ns_state == IDLE)
	  fifo_wdata <= {2'b10,v6[23:8]}; 
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
         last_v1 <= 16'h0;
      else if(cs_state == V1_PROC && ns_state == V2_PROC)
         last_v1 <= temp1;
end  

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
         last_v2 <= 16'h0;
      else if(cs_state == V2_PROC && ns_state == V3_PROC)
         last_v2 <= temp1;
end 

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
         last_v3 <= 16'h0;
      else if(cs_state == V3_PROC && ns_state == V4_PROC)
         last_v3 <= temp1;
end 

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
         v4 <= 16'h0;
      else if(cs_state == V4_PROC)
         v4 <= fifo_rdata;
end 

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
         last_v5 <= 16'h0;
      else if(cs_state == V5_PROC && ns_state == V6_PROC)
         last_v5 <= temp1;
end 

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
         last_v6 <= 16'h0;
      else if(cs_state == V6_PROC && ns_state == IDLE)
         last_v6 <= temp1;
end 

multiplier_mod_signed  multiplier_1
                (.Clock(clk), 
                 .ClkEn(1'b1), 
                 .Aclr(aclr), 
                 .DataA(a), 
                 .DataB(temp1), 
                 .Result(result1)
                 );
                 
multiplier_mod_signed  multiplier_2
                (.Clock(clk), 
                 .ClkEn(1'b1), 
                 .Aclr(aclr), 
                 .DataA(b), 
                 .DataB(temp2), 
                 .Result(result2)
                 );                 
endmodule
