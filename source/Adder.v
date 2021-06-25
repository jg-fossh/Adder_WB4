/////////////////////////////////////////////////////////////////////////////////
// BSD 3-Clause License
//
// Copyright (c) 2020, Jose R. Garcia
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
/////////////////////////////////////////////////////////////////////////////////
// File name     : Adder.v
// Author        : Jose R Garcia
// Created       : 30-05-2021 09:09
// Last modified : 2021/06/22 19:28:38
// Project Name  : Adder
// Module Name   : Adder
// Description   : Performs addition or substraction over two inputs.
//
// Additional Comments:
//   .
/////////////////////////////////////////////////////////////////////////////////
module Adder #(
  // Compile time configurable parameters
  parameter integer P_ADDER_DATA_MSB = 0 // Data most significant bit.
)(
  // Component's clocks and resets
  input i_clk,        // clock
  input i_reset_sync, // reset
  // Wishbone Pipeline Slave Interface
  input                             i_wb4_slave_stb,   // WB stb, valid strobe
  input  [(P_ADDER_DATA_MSB*2)+1:0] i_wb4_slave_data,  // WB data, {data1, data0}
  input                             i_wb4_slave_tgd,   // WB data tag, 0=add 1=substract
  output                            o_wb4_slave_stall, // WB stall, not ready
  output                            o_wb4_slave_ack,   // WB ack, strobe acknowledge
  // Wishbone Pipeline Master Interface
  output                      o_wb4_master_stb,   // WB write enable
  output [P_ADDER_DATA_MSB:0] o_wb4_master_data,  // WB data, result
  input                       i_wb4_master_stall, // WB stall, not ready
  input                       i_wb4_master_ack    // WB ack, strobe acknowledge
);

  ///////////////////////////////////////////////////////////////////////////////
  // Internal Parameter Declarations
  ///////////////////////////////////////////////////////////////////////////////
  localparam integer L_DATA1_LSB = P_ADDER_DATA_MSB+1;
  localparam integer L_DATA1_MSB = (P_ADDER_DATA_MSB*2)+1;
  ///////////////////////////////////////////////////////////////////////////////
  // Internal Signals Declarations
  ///////////////////////////////////////////////////////////////////////////////
  // Adder Controller Process signals
  reg                      r_adder_stb;
  reg                      r_adder_ack;
  reg [P_ADDER_DATA_MSB:0] r_adder_result;
  reg                      r_adder_stall;
  // Control wires (indicate when this module is available)
 //  wire w_adder_stall = (r_adder_stall==1'b0 || (i_wb4_master_stall==1'b0 && r_adder_stall==1'b1)) ? 1'b0 : 1'b1;
  wire w_adder_stall = r_adder_stall & i_wb4_master_stall;

  ///////////////////////////////////////////////////////////////////////////////
  //            ********      Architecture Declaration      ********           //
  ///////////////////////////////////////////////////////////////////////////////

  //
  assign o_wb4_slave_ack   = r_adder_ack;
  assign o_wb4_slave_stall = w_adder_stall;
  
  ///////////////////////////////////////////////////////////////////////////////
  // Process     : Adder Process
  // Description : Generates the result of the addition or substraction based on
  //               the input data and data tag.
  ///////////////////////////////////////////////////////////////////////////////
  always @(posedge i_clk) begin : Adder_Process
    if (i_reset_sync == 1'b1) begin
      r_adder_stb    <= 1'b0;
      r_adder_stall  <= 1'b1;
      r_adder_ack    <= 1'b0;
      r_adder_result <= 'h0;
    end
    else begin
      //
      r_adder_stall <= i_wb4_master_stall;
      
      if (i_wb4_slave_stb == 1'b1 && w_adder_stall == 1'b0) begin
        // When ready and new data comes in.
        r_adder_stb <= 1'b1;
        r_adder_ack <= 1'b1;

        if (i_wb4_slave_tgd == 1'b1) begin
          // Subtracts the two inputs.
          r_adder_result <= i_wb4_slave_data[P_ADDER_DATA_MSB:0] - i_wb4_slave_data[L_DATA1_MSB:L_DATA1_LSB];
        end
        else begin
          // Generate the sum of the two inputs.
          r_adder_result <= i_wb4_slave_data[P_ADDER_DATA_MSB:0] + i_wb4_slave_data[L_DATA1_MSB:L_DATA1_LSB];
        end
      end
      else if (i_wb4_slave_stb == 1'b0) begin
        // 
        r_adder_stb <= 1'b0;
        r_adder_ack <= 1'b0;
      end
      else begin
        // 
        r_adder_stb <= r_adder_stb;
        r_adder_ack <= 1'b0;
      end
    end
  end // Adder_Process
  
  // WB Write interface connections
  assign o_wb4_master_stb  = r_adder_stb;
  assign o_wb4_master_data = r_adder_result;

endmodule
