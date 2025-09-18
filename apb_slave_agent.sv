class apb_slave_agent extends uvm_agent;
  
  `uvm_component_utils(apb_slave_agent)
  

  apb_slave_monitor mon2;

  
  function new(string name="apb_slave_agent", uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon2=apb_slave_monitor::type_id::create("mon2",this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

  endfunction
  
  
endclass
    
    