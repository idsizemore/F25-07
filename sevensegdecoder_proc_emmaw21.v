////////////////////////////////////////////////////////////////////////////////
// Filename:    sevensegdecoder_proc_emmaw21.v
// Author:      Emma Wallace
// Date:        30 September 2024
// Version:     1
// Description: This file contains a module that uses procedural assignments and
//              dataflow operators to build a seven-segment display with outputs
//        	on display of 0-F, where display bits are active-low
////////////////////////////////////////////////////////////////////////////////

module sevensegdecoder_proc_emmaw21(hex_digit, hex_display);
   input  [3:0] hex_digit;	// Input value
   output [6:0] hex_display;	// Display output
   reg    [6:0] hex_display;

   always@(hex_digit) begin
      case(hex_digit)
         4'h0:	  hex_display = 7'h40;// "O"
         4'h1:	  hex_display = 7'h79;// "I"
         4'h2:	  hex_display = 7'h0C;// "P"
         4'h3:	  hex_display = 7'h09;// "H"
         4'h4:	  hex_display = 7'h41;// "U"
         4'h5:	  hex_display = 7'h12;// "S"
         4'h6:	  hex_display = 7'h47;// "L"
         4'h7:	  hex_display = 7'h2B;// "n"
         4'h8:	  hex_display = 7'h2F;// "r"
         4'h9:	  hex_display = 7'h0F;// "t"
         4'hA:	  hex_display = 7'h08;// "A"
         4'hB:	  hex_display = 7'h03;
         4'hC:	  hex_display = 7'h46;
         4'hD:	  hex_display = 7'h21;
         4'hE:	  hex_display = 7'h06;// "E"
         4'hF:	  hex_display = 7'h0E;// "F"
         default: hex_display = 7'hx;
      endcase
   end

endmodule
