
class uart_int_checker extends uvm_subscriber #(uart_seq_item);

`uvm_component_utils(uart_int_checker)

uart_reg_block rm;
// Register model variables:
uvm_status_e status;
rand uvm_reg_data_t data;

uart_env_config cfg;

uart_seq_item data_q[$];
int interrupt_num;
int errors_num;
int reg_error_num;

function new(string name = "uart_int_checker", uvm_component parent = null);
  super.new(name, parent);
endfunction

task run_phase(uvm_phase phase);
    fork
        count_interrupt;
        count_errors;
    join
endtask: run_phase

task count_interrupt;
    interrupt_num = 0;
    reg_error_num = 0;
    forever begin
        cfg.wait_for_interrupt();
        rm.IID.read(status, data, UVM_BACKDOOR, .parent(this));
        //if the interrupt source is FE,PE
        if(data[3:1]==3'b011) begin
            interrupt_num++;
            rm.LSR.read(status, data, .parent(this));
            if(data[2]!=1'b1) begin
                reg_error_num++;
            end
        end 
    end
endtask:count_interrupt

task count_errors;
    errors_num = 0;
    uart_seq_item uart_data;
    forever begin
        if(data_q.size() > 0) begin
        uart_data = data_q.pop_front();
            if (uart_data.pe == 1'b1)
                errors_num++;
        end
    end
endtask:count_errors

function void report_phase(uvm_phase phase);

  if((interrupt_num == errors_num) && (reg_error_num == 0)) begin
    `uvm_info("report_phase", $sformatf("compare succeed!!! %0d PF error recieved and %0d interrupt generated  by the UART PE inserted errors", interrupt_num, errors_num), UVM_LOW)
  end
  if(interrupt_num != errors_num) begin
    `uvm_error("report_phase", $sformatf("compare failed!!! %0d PF error recieved and %0d interrupt generated  by the UART PE inserted errors", errors_num,interrupt_num))
  end
  if(reg_error_num != 0) begin
    `uvm_error("report_phase", $sformatf("compare failed!!! PE bit in LSR is not asserted when interrupt generated!"))
  end
endfunction: report_phase

function void write(uart_seq_item t);
    data_q.push_back(t);
endfunction: write

endclass: uart_int_checker
