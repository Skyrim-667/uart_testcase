/////////////////////////////////////////////////////////////////////
////                                                             ////
////   THIS CODE IS FOR COVERAGE VERIFICATION OF INTERRUPT FOR   ////
////         16550A UART, WHICH GIVEN BY Mentor Graphics   		   ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
// ---------------------------------------------------------------------
// Skyrim_C@outlook.com (teddy Cheng)
//----------------------------------------------------------------------
//   Copyright 2012 Mentor Graphics Corporation
//   All Rights Reserved Worldwide
//
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//----------------------------------------------------------------------

class uart_int_rx_only_seq extends host_if_base_seq;

`uvm_object_utils(uart_int_rx_only_seq)


rand int rx_fifo_threshold;
rand int no_rx_chars;
rand bit[1:0] FCR;

function new(string name = "uart_int_rx_only_seq");
  super.new(name);
endfunction

task body;
  super.body();

  case(FCR)
    2'b00: rx_fifo_threshold = 1;
    2'b01: rx_fifo_threshold = 4;
    2'b10: rx_fifo_threshold = 8;
    2'b11: rx_fifo_threshold = 14;
  endcase

  rm.IID.read(status, data, .parent(this));
  if(data[0] == 0) begin
    case(data[3:1])
      3'b011: begin
                rm.LSR.read(status, data, .parent(this));
              end
      3'b010: begin
                for(int i = 0; i < rx_fifo_threshold; i++) begin
                  rm.RXD.read(status, data, .parent(this));
                  no_rx_chars--;
                  if(no_rx_chars == 0) begin
                    break;
                  end
                end
              end
      3'b001: begin
                `uvm_error("uart_int_rx_only_seq", "tx_interrupt asserted while no data is sent!")
                break;
              end
    endcase
  end
endtask: body

endclass: uart_int_rx_only_seq