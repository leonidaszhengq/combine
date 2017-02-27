
`timescale 1ns/1ps
module amplitude_ctrl(
                       input        clk,
                       input        resetn,

                       input        fifo_empty,
                       input [15:0] fifo_rdata,
                       output reg   fifo_rden,

                       input        fifo_almost_full,
                       output reg [15:0] fifo_wdata,
                       output reg   fifo_wren
                     );

reg []   cs_state;
reg []   ns_state;

always@(posedge clk or negedge resetn)begin
      if(resetn == 1'b0)
        cs_state <= IDLE;
      else
        cs_state <= ns_state;
end

always@(*)begin
    ns_state = cs_state;
    case(cs_state)
         IDLE          :   begin
                                if(fifo_emtpy == 1'b0 && fifo_almost_full == 1'b0)
                                   ns_state = V1_RD;
                                else
                                   ns_state = IDLE;
                           end

         V1_RD         :  ns_state = V1_LATCH;
                          
         V1_LATCH      :  ns_state = V1_PROC;

         V1_PROC       :  ns_state = V1_WR;

         V1_WR         :  ns_state = V2_RD;

         V2_RD         :  ns_state = V2_LATCH;

         V2_LATCH      :  ns_state = V2_PROC;

         V2_PROC       :  ns_state = V3_PROC;
                          
         V2_WR         :  ns_state = V3_RD;

         V3_RD         :  ns_state = V3_LATCH;

         V3_LATCH      :  ns_state = V3_PROC;

         V3_PROC       :  ns_state = V3_WR;
               
         V3_WR         :  ns_state = V4_RD;

         V4_RD         :  ns_state = V4_WR;

         V4_WR         :  ns_state = V5_RD;
                         
         V5_RD         :  ns_state = V5_WR;

         V5_WR         :  ns_state = V6_RD;

         V6_RD         :  ns_state = V6_WR;
         
         V6_WR         :  ns_state = IDLE;

         default       : ns_state = IDLE;
    endcase
end

endmodule
