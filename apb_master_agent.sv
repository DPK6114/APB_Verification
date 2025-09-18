class apb_master_agent extends uvm_agent;
  
  `uvm_component_utils(apb_master_agent)
  
  apb_master_sequencer seqr;
  apb_master_driver drv;
  apb_master_monitor mon1;

  
  function new(string name="apb_master_agent", uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    seqr=apb_master_sequencer::type_id::create("seqr",this);
    drv=apb_master_driver::type_id::create("drv",this);
    mon1=apb_master_monitor::type_id::create("mon1",this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
  
  
endclass
    
    