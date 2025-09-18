`include "uvm_macros.svh"
import uvm_pkg::*;

include "design.sv"
`include "interface.sv"

`include "apb_seq_item.sv"
`include "apb_sequence.sv"
`include "apb_master_sequencer.sv"
`include "apb_master_driver.sv"
`include "apb_master_monitor.sv"
`include "apb_slave_monitor.sv"
`include "apb_master_agent.sv"
`include "apb_slave_agent.sv"
`include "apb_scoreboard.sv"
`include "apb_env.sv"
`include "apb_test.sv"

module top;
  
  reg pclk;
  reg prst_n;
  
  always #5 pclk=~pclk;
  
  initial pclk=0;
  
  initial begin
    prst_n=0;
    #5 prst_n=1;
  end
  
  apb_if intf(pclk,prst_n);
  
  apb_peripheral dut(
    .pclk(intf.pclk),
    .prst_n(intf.prst_n),
    .paddr(intf.paddr),
    .pwdata(intf.pwdata),
    .pwrite(intf.pwrite),
    .psel(intf.psel),
    .penable(intf.penable),
    .pready(intf.pready),
    .pslverr(intf.pslverr),
    .prdata(intf.prdata)
  );
    
  
  initial begin
    uvm_config_db#(virtual apb_if)::set(null,"*","vif",intf);
  end
 
  
  initial begin
    run_test("apb_test");
  end
  
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars();
  end
  
  initial begin
    #3000 $finish();
  end
  
endmodule