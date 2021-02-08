'/////////////////////////////////////////////////////////////////////
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

class tx_int_vseq extends uart_vseq_base;

`uvm_object_utils(tx_int_vseq)

function new(string name = "tx_int_vseq");
  super.new(name);
endfunction

task body;
  uart_config_seq       setup = uart_config_seq::type_id::create("setup");
  uart_int_enable_seq   ien = uart_int_enable_seq::type_id::create("ien");
  uart_int_tx_only_seq  isr = uart_int_tx_only_seq::type_id::create("isr");

  //tb to the dut(rx of dut)
  //uart_rx_seq           rx_serial = uart_rx_seq::type_id::create("rx_serial");
  //read from the dut apb interface
  //uart_host_rx_seq      rx_poll = uart_host_rx_seq::type_id::create("rx_poll");

  //sent to dut at the apb side
  uart_host_tx_seq      tx_poll = uart_host_tx_seq::type_id::create("tx_poll");
  uart_wait_empty_seq   wait_empty = uart_wait_empty_seq::type_id::create("wait_empty");

  bit[7:0] lcr;
  bit[15:0] divisor;
  bit[1:0] fcr;

  lcr = 0;
  divisor = 2;

  //rx_serial.no_rx_chars = 2;

  //no errors(such as frame error, parity error)
  //rx_serial.no_errors = 1;

  repeat(64) begin
    assert(setup.randomize() with {setup.LCR == lcr;
                                   setup.DIV == divisor;});
    setup.start(apb);

    //only enable tx interrupt
    ien.IER = 4'h2;
    ien.start(apb);

    //configure for rx(comment)
    //rx_serial.baud_divisor = divisor;
    //rx_serial.lcr = lcr;

    rx_uart_config.baud_divisor = divisor;
    rx_uart_config.lcr = lcr;

    tx_uart_config.baud_divisor = divisor;
    tx_uart_config.lcr = lcr;

    //when no_tx_chars > 8, the tx_interrupt will assert
    assert(isr.randomize() with {no_tx_chars inside {[1:20]};});
    isr.FCR = setup.FCR;

    //to assert rx_interrupt
    case(setup.FCR)
      2'b00: isr.no_rx_chars = $urandom_range(2, 10);
      2'b01: isr.no_rx_chars = $urandom_range(4, 12);
      2'b10: isr.no_rx_chars = $urandom_range(8, 16);
      2'b11: isr.no_rx_chars = $urandom_range(14, 22);
    endcase

    //rx_serial.no_rx_chars = isr.no_rx_chars;

    tx_poll.no_tx_chars = 1;
    tx_poll.start(apb);

    fork
      begin
        while(isr.no_tx_chars > 0) begin
          if(!cfg.get_interrupt_level()) begin
            cfg.wait_for_interrupt();
          end
          isr.start(apb);
        end
      end
    join
    wait_empty.start(apb);
    lcr++;
  end

endtask: body

endclass: word_format_int_vseq