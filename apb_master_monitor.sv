class apb_master_monitor extends uvm_monitor;
  
  `uvm_component_utils(apb_master_monitor)

  virtual apb_if vif;

  uvm_analysis_port #(apb_seq_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", "Failed to get virtual interface")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.pclk);

      // Detect read access phase
      if (vif.psel && vif.penable && vif.pwrite && vif.pready) begin
        apb_seq_item trans = apb_seq_item::type_id::create("trans");

        // Capture read data & address
               trans.paddr   = vif.paddr;
               trans.psel 	 = vif.psel;
               trans.pwrite	 = vif.pwrite;
               trans.penable = vif.penable;
               trans.pready  = vif.pready;
               trans.pwdata	 = vif.pwdata;
               trans.pslverr = vif.pslverr;
               trans.prdata  = vif.prdata;

        `uvm_info("APB_MSTER_MON", $sformatf("WRITE:  paddr=0x%0h  psel=%0d  pwrite=%0d  penable=%0d  pready=%0d  pwdata=%0h  pslverr=%0d  prdata=0x%0h", trans.paddr, trans.psel, trans.pwrite, trans.penable, trans.pready, trans.pwdata, trans.pslverr, trans.prdata), UVM_MEDIUM)

        // Send the transaction to scoreboard/coverage
        ap.write(trans);
      end
    end
  endtask

endclass
