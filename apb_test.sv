class apb_test extends uvm_test;
  
  `uvm_component_utils(apb_test)
  
  apb_env env;
  
  apb_sequence seq;

  
  function new(string name="apb_test", uvm_component parent=null);
    super.new(name,parent);
  endfunction
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env=apb_env::type_id::create("env",this);
  endfunction
  

  virtual function void end_of_elaboration();
    //print's the topology
    print();
  endfunction
  
  
  
  //---------------------------------------
  // run_phase - starting the test
  //---------------------------------------
  task run_phase(uvm_phase phase);
    seq=apb_sequence::type_id::create("seq");
    
    phase.raise_objection(this);
    seq.start(env.agt.seqr);
    phase.drop_objection(this);
    
    //set a drain-time for the environment if desired
    phase.phase_done.set_drain_time(this, 50);
  endtask : run_phase
  
  
endclass
    
    