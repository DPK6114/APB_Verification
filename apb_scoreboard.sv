class apb_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(apb_scoreboard)

  // Analysis imports from master and slave monitors
  uvm_analysis_imp #(apb_seq_item, apb_scoreboard) master_mon_imp;
  uvm_analysis_imp #(apb_seq_item, apb_scoreboard) slave_mon_imp;

  // Transaction queues
  apb_seq_item master_queue[$];
  apb_seq_item slave_queue[$];
  
  // Coverage variables (now properly declared as class members)
  bit [31:0] addr;
  bit pwrite;
  bit [31:0] pwdata;
  bit pslverr;
  bit penable;
  bit psel;
  bit preday;

  // Coverage group
  covergroup apb_transaction_cg;
        option.per_instance = 1;
    paddr_cp: coverpoint addr {
      bins low_range    = {[0:32'h0000_FFFF]};
      bins mid_range    = {[32'h0001_0000:32'hFFFF_0000]};
      bins high_range   = {[32'hFFFF_0001:32'hFFFF_FFFF]};
    }
    
    // Control signals coverage
    pwrite_cp: coverpoint pwrite {
      bins write = {1};
      bins read  = {0};
    }
    
    // Data coverage
    pwdata_cp: coverpoint pwdata {
      bins zeros     = {0};
      bins ones      = {32'hFFFF_FFFF};
      bins low_val   = {[1:32'h0000_FFFF]};
      bins high_val  = {[32'hFFFF_0000:32'hFFFF_FFFE]};
      bins alternating = {32'hAAAA_AAAA, 32'h5555_5555};
    }
    
    // Error coverage
    pslverr_cp: coverpoint pslverr {
      bins no_error = {0};
      bins error    = {1};
    }
    
    // Protocol timing coverage
    penable_cp: coverpoint penable {
      bins active = {1};
    }
    
    // Cross coverage
    rw_addr_cross: cross pwrite_cp, paddr_cp;
    error_addr_cross: cross pslverr_cp, paddr_cp;
  endgroup

  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    master_mon_imp = new("master_mon_imp", this);
    slave_mon_imp  = new("slave_mon_imp", this);
    apb_transaction_cg = new();
  endfunction

  // Build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  function void write(apb_seq_item t);
    if (t.pwrite) begin
      master_queue.push_back(t);
      `uvm_info("APB_SCOREBOARD", $sformatf("WRITE_TXN: paddr=0x%0h psel=%0d pwrite=%0d penable=%0d pready=%0d pwdata=%0h pslverr=%0d prdata=0x%0h", 
               t.paddr, t.psel, t.pwrite, t.penable, t.pready, t.pwdata, t.pslverr, t.prdata), UVM_MEDIUM);
    end else begin
      slave_queue.push_back(t);
      `uvm_info("APB_SCOREBOARD", $sformatf("READ_TXN: paddr=0x%0h psel=%0d pwrite=%0d penable=%0d pready=%0d pwdata=%0h pslverr=%0d prdata=0x%0h", 
               t.paddr, t.psel, t.pwrite, t.penable, t.pready, t.pwdata, t.pslverr, t.prdata), UVM_MEDIUM);
    end
    
    // Update coverage variables
    addr = t.paddr;
    pwrite = t.pwrite;
    pwdata = t.pwdata;
    pslverr = t.pslverr;
    penable = t.penable;
    
    // Sample coverage
    apb_transaction_cg.sample();
  endfunction
  
  task run_phase(uvm_phase phase);
    apb_seq_item expected_txn, actual_txn;

    forever begin
      // Wait until both queues have at least one transaction
      wait (master_queue.size() > 0 && slave_queue.size() > 0);

      // Pop transactions
      expected_txn = master_queue.pop_front();
      actual_txn   = slave_queue.pop_front();
      
      // Update coverage variables with actual transaction
      addr = actual_txn.paddr;
      pwrite = actual_txn.pwrite;
      pwdata = actual_txn.pwdata;
      pslverr = actual_txn.pslverr;
      penable = actual_txn.penable;
      apb_transaction_cg.sample();

      // Compare transactions
      if (expected_txn.paddr !== actual_txn.paddr) begin
        `uvm_error("APB_SCOREBOARD", $sformatf("Address mismatch: Expected 0x%0h, Got 0x%0h", 
                 expected_txn.paddr, actual_txn.paddr))
      end

      if (expected_txn.pwrite && expected_txn.pwdata !== actual_txn.prdata) begin
        `uvm_error("APB_SCOREBOARD", $sformatf("Write Data mismatch: Expected 0x%0h, Got 0x%0h", 
                 expected_txn.pwdata, actual_txn.prdata))
      end
      else if (!expected_txn.pwrite && expected_txn.pwdata !== actual_txn.prdata) begin
        `uvm_error("APB_SCOREBOARD", $sformatf("Read Data mismatch: Expected 0x%0h, Got 0x%0h", 
                 expected_txn.pwdata, actual_txn.prdata))
      end
      else begin
        `uvm_info("APB_SCOREBOARD PASSED", $sformatf("MATCH: Addr=0x%0h Data=0x%0h", 
                 expected_txn.paddr, actual_txn.prdata), UVM_LOW)
      end
    end
  endtask

endclass