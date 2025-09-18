class apb_env extends uvm_env;
  
  `uvm_component_utils(apb_env)
  
  apb_master_agent agt;
  apb_slave_agent s_agt;
  
  apb_scoreboard scb;

  
  function new(string name="apb_env", uvm_component parent);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt=apb_master_agent::type_id::create("agt",this);
    s_agt=apb_slave_agent::type_id::create("s_agt",this);
    scb=apb_scoreboard::type_id::create("scb",this);
  endfunction
  
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agt.mon1.ap.connect(scb.master_mon_imp);
    s_agt.mon2.slave_mon_port.connect(scb.slave_mon_imp);
  endfunction
  
  
endclass
    
    