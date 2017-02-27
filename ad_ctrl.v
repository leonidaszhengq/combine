///////////////////////////////////////////////////////////////
////
////
////
////   author : zhengquan
////   date   : 2017/2/21
////   function: ad control    
////
///////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module ad_ctrl(
               input            clk,
               input            resetn,
               

               input            busy,
               input            douta,
               input            doutb,
               output reg       converst,
               output reg       cs,
               output reg       sclk,
               
               output reg       fifo_wren,
               output reg [17:0] fifo_wdata,
               input            fifo_almost_full
              );

parameter                    time_cycle   =  50;  // 20MHz

parameter                    converst_down2up = (25 / time_cycle + 1),
                             converst2busy    = (40 / time_cycle + 1),
                             busy2cs          = (0  / time_cycle + 1),
                             cs2data          = (15 / time_cycle + 1),
                             data2cs          = (23 / time_cycle + 1);

parameter                    IDLE             =  10'b00_0000_0001,
                             CONVERST         =  10'b00_0000_0010,
                             CONVERST2BUSY    =  10'b00_0000_0100,
                             WAIT_BUSY        =  10'b00_0000_1000,
                             CS_DOWN          =  10'b00_0001_0000,
                             READ_CHANNEL15   =  10'b00_0010_0000,
                             READ_CHANNEL26   =  10'b00_0100_0000,
                             READ_CHANNEL37   =  10'b00_1000_0000,
                             READ_CHANNEL48   =  10'b01_0000_0000,
                             CS_UP            =  10'b10_0000_0000;
                             
                             
reg [7:0]    timer_cnt;
reg [7:0]    read_cnt;                             
reg [9:0]    cs_state;
reg [9:0]    ns_state;
reg [15:0]   v1,v2,v3,v4,v5,v6;

wire         converst_low_pulse;
wire         converst_busy;
wire         cs_down_t;
wire         cs_up_t;


always@(posedge clk or negedge resetn)begin
      if(!resetn)
        cs_state <= IDLE;
      else
        cs_state <= ns_state;
end                                                
              
always@(*)begin
      ns_state = cs_state;
      case(cs_state)
           IDLE :   begin
                      if(busy == 1'b0 && fifo_almost_full == 1'b0)
                         ns_state = CONVERST;
                      else
                         ns_state = IDLE;
                    end
             
           CONVERST : begin
                          if(converst_low_pulse)
                             ns_state = CONVERST2BUSY;
                          else
                             ns_state = CONVERST;  
                      end       
                      
           CONVERST2BUSY : begin
                              if(converst_busy)
                                 ns_state = WAIT_BUSY;
                              else
                                 ns_state = CONVERST2BUSY;
                           end             
                      
           WAIT_BUSY: begin
                           if(!busy)
                             ns_state = CS_DOWN;
                           else
                             ns_state = WAIT_BUSY;
                      end        
                      
           CS_DOWN:   begin
                          if(cs_down_t)
                             ns_state = READ_CHANNEL15;
                          else
                             ns_state = CS_DOWN;
                      end
                                 
           READ_CHANNEL15 : begin
                              if(read_cnt == 8'hf)
                                 ns_state = READ_CHANNEL26;
                              else
                                 ns_state = READ_CHANNEL15;
                           end       
                               
           READ_CHANNEL26 : begin
                              if(read_cnt == 8'hf)
                                 ns_state = READ_CHANNEL37;
                              else
                                 ns_state = READ_CHANNEL26;
                           end       
                          
           READ_CHANNEL37 : begin
                              if(read_cnt == 8'hf)
                                 ns_state = READ_CHANNEL48;
                              else
                                 ns_state = READ_CHANNEL37;
                           end        
                
           READ_CHANNEL48 : begin
                              if(read_cnt == 8'hf	)
                                 ns_state = CS_UP;
                              else
                                 ns_state = READ_CHANNEL48;
                           end                              
                           
           CS_UP          : begin
                               if(cs_up_t)
                                  ns_state = IDLE;
                               else
                                  ns_state = CS_UP;
                            end                     
      default : ns_state = IDLE;
      endcase
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
         converst <= 1'b1;
      else if(ns_state == CONVERST)
         converst <= 1'b0;
      else
         converst <= 1'b1;
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
         cs <= 1'b1;
      else if(ns_state == CS_DOWN)
         cs <= 1'b0;
      else if(ns_state == IDLE)
         cs <= 1'b1;
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
         timer_cnt <= 8'h0;
      else if(cs_state == IDLE)
         timer_cnt <= 8'h0;
      else if(cs_state != ns_state)
         timer_cnt <= 8'h0;
      else if(cs_state == CONVERST)
         timer_cnt <= timer_cnt + 1;
      else if(cs_state == CONVERST2BUSY)
         timer_cnt <= timer_cnt + 1;
      else if(cs_state == CS_DOWN)
         timer_cnt <= timer_cnt + 1;   
      else if(cs_state == CS_UP)
         timer_cnt <= timer_cnt + 1;
      else
         timer_cnt <= 8'h0;
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
         read_cnt <= 8'h0;
      else if(cs_state == IDLE)
         read_cnt <= 8'h0;
      else if(cs_state == READ_CHANNEL15 && ns_state == READ_CHANNEL26)
         read_cnt <= 8'h0;
      else if(cs_state == READ_CHANNEL26 && ns_state == READ_CHANNEL37)
         read_cnt <= 8'h0;
      else if(cs_state == READ_CHANNEL37 && ns_state == READ_CHANNEL48)
         read_cnt <= 8'h0;
      else if(cs_state == READ_CHANNEL15)
         read_cnt <= read_cnt + 1;
      else if(cs_state == READ_CHANNEL26)
         read_cnt <= read_cnt + 1;
      else if(cs_state == READ_CHANNEL37)
         read_cnt <= read_cnt + 1;
      else if(cs_state == READ_CHANNEL48)
         read_cnt <= read_cnt + 1;
end

assign   converst_low_pulse = (cs_state == CONVERST) && (timer_cnt == converst_down2up);
assign   converst_busy     = (cs_state == CONVERST2BUSY) && (timer_cnt == converst2busy);
assign   cs_down_t          = (cs_state == CS_DOWN) && (timer_cnt == cs2data);
assign   cs_up_t            = (cs_state == CS_UP) && (timer_cnt == data2cs);

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
        v1 <= 16'h0;
      else if(cs_state == IDLE)
        v1 <= 16'h0;
      else if(cs_state == READ_CHANNEL15)
        v1 <= {v1[14:0],douta};
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
        v2 <= 16'h0;
      else if(cs_state == IDLE)
        v2 <= 16'h0;
      else if(cs_state == READ_CHANNEL26)
        v2 <= {v2[14:0],douta};
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
        v3 <= 16'h0;
      else if(cs_state == IDLE)
        v3 <= 16'h0;
      else if(cs_state == READ_CHANNEL37)
        v3 <= {v3[14:0],douta};
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
        v4 <= 16'h0;
      else if(cs_state == IDLE)
        v4 <= 16'h0;
      else if(cs_state == READ_CHANNEL48)
        v4 <= {v4[14:0],douta};
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
        v5 <= 16'h0;
      else if(cs_state == IDLE)
        v5 <= 16'h0;
      else if(cs_state == READ_CHANNEL15)
        v5 <= {v5[14:0],doutb};
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
        v6 <= 16'h0;
      else if(cs_state == IDLE)
        v6 <= 16'h0;
      else if(cs_state == READ_CHANNEL26)
        v6 <= {v6[14:0],doutb};
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
         fifo_wren <= 1'b0;
      else if(cs_state == READ_CHANNEL48)begin
         case(read_cnt)
           8'h0 : fifo_wren <= 1'b1;
           8'h1 : fifo_wren <= 1'b1;
           8'h2 : fifo_wren <= 1'b1;
           8'h3 : fifo_wren <= 1'b1;
           8'h4 : fifo_wren <= 1'b1;
           8'h5 : fifo_wren <= 1'b1;
         default : fifo_wren <= 1'b0;
         endcase
      end
end

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
         fifo_wdata <= 18'b0;
      else if(cs_state == READ_CHANNEL48)begin
         case(read_cnt)
           8'h0 : fifo_wdata <= {2'b01,v1};
           8'h1 : fifo_wdata <= {2'b00,v2};
           8'h2 : fifo_wdata <= {2'b00,v3};
           8'h3 : fifo_wdata <= {2'b00,v4};
           8'h4 : fifo_wdata <= {2'b00,v5};
           8'h5 : fifo_wdata <= {2'b10,v6};
         default : fifo_wdata <= 18'h0;
         endcase
      end
end

endmodule

