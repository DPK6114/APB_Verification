class apb_slave_monitor extends uvm_agent;
  
  `uvm_component_utils(apb_slave_monitor)
  
  virtual apb_if vif;
  
  uvm_analysis_port #(apb_seq_item) slave_mon_port;

  function new(string name="apb_slave_monitor", uvm_component parent);
    super.new(name,parent);
    slave_mon_port=new("slave_mon_port",this);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", "Failed to get virtual interface")
  endfunction
      
  task run_phase(uvm_phase phase);
    forever begin
             @(posedge vif.pclk)
             if(vif.psel && vif.penable && !vif.pwrite && vif.pready) begin
             apb_seq_item pkt=apb_seq_item::type_id::create("pkt");

               pkt.paddr  	= vif.paddr;
               pkt.psel 	= vif.psel;
               pkt.pwrite	= vif.pwrite;
               pkt.penable	= vif.penable;
               pkt.pready 	= vif.pready;
               pkt.pwdata	= vif.pwdata;
               pkt.pslverr  = vif.pslverr;
               pkt.prdata 	= vif.prdata;
               
               `uvm_info("APB_SLAVE_MON", $sformatf("READ:  paddr=0x%0h	 psel=%0d  pwrite=%0d  penable=%0d  pready=%0d  pwdata=%0h  pslverr=%0d  prdata=0x%0h", pkt.paddr, pkt.psel, pkt.pwrite, pkt.penable, pkt.pready, pkt.pwdata, pkt.pslverr, pkt.prdata), UVM_MEDIUM)
               
               slave_mon_port.write(pkt);
               
             end
           end
         endtask

  
endclass
    
    