class apb_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(apb_scoreboard)

  // Analysis ports
  uvm_analysis_imp #(apb_seq_item, apb_scoreboard) master_imp;
  uvm_analysis_imp #(apb_seq_item, apb_scoreboard) slave_imp;

  // Transaction queues
  local apb_seq_item master_q[$];
  local apb_seq_item slave_q[$];
  
  // Coverage variables
  protected struct {
    bit [31:0] addr;
    bit        write;
    bit        psel;
    bit [31:0] wdata;
    bit [31:0] rdata;
    bit        error;
    bit [1:0]  state; // 00: IDLE, 01: SETUP, 10: ACCESS
  } cov;

  // Coverage group
  covergroup apb_cg with function sample(bit[31:0] addr, bit wr, 
                                       bit[31:0] wdata, bit[31:0] rdata,
                                       bit error, bit[1:0] state);
    option.per_instance = 1;
    option.name = "apb_protocol_cov";
    
    // Address coverage
    ADDR: coverpoint addr {
      bins low       = {[0:'h0000_FFFF]};
      bins mid       = {['h0001_0000:'hFFFF_0000]};
      bins high      = {['hFFFF_0001:'hFFFF_FFFF]};
      bins page_0    = {[0:'h0000_00FF]};
      bins page_1    = {['h0000_0100:'h0000_01FF]};
    }
    
    // Operation coverage
    OP: coverpoint wr {
      bins read  = {0};
      bins write = {1};
    }
    
    // Write data coverage
    WDATA: coverpoint wdata {
      bins zero      = {0};
      bins all_ones  = {'1};
      bins lo_byte   = {[1:'hFF]};
      bins hi_byte   = {['hFFFFFF00:'hFFFFFFFE]};
      bins walking_1 = (32'b1 << [0:31]);
    }
    
    // Read data coverage
    RDATA: coverpoint rdata {
      bins zero      = {0};
      bins all_ones  = {'1};
      bins alternating = {32'hAAAAAAAA, 32'h55555555};
    }
    
    // Error coverage
    ERR: coverpoint error {
      bins no_err = {0};
      bins err    = {1};
    }
    
    // Protocol state coverage
    STATE: coverpoint state {
      bins idle   = {0};
      bins setup  = {1};
      bins access = {2};
      illegal_bins invalid = {3};
    }
    
    // Cross coverage
    RWxADDR: cross OP, ADDR;
    ERRxOP: cross ERR, OP;
    STATE_TRANS: cross STATE, OP {
      bins idle_to_setup_read  = binsof(STATE.idle) && binsof(OP.read);
      bins setup_to_access_read = binsof(STATE.setup) && binsof(OP.read);
      bins idle_to_setup_write = binsof(STATE.idle) && binsof(OP.write);
      bins setup_to_access_write = binsof(STATE.setup) && binsof(OP.write);
    }
  endgroup

  // Constructor
  function new(string name, uvm_component parent);
    super.new(name, parent);
    master_imp = new("master_imp", this);
    slave_imp  = new("slave_imp", this);
    apb_cg = new();
  endfunction

  // Build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  // Master monitor write implementation
  function void write_master(apb_seq_item tr);
    master_q.push_back(tr);
    update_coverage(tr, "master");
    `uvm_info("SB_MASTER", 
              $sformatf("Received master transaction:\n%s", tr.sprint()), 
              UVM_HIGH)
  endfunction

  // Slave monitor write implementation
  function void write_slave(apb_seq_item tr);
    slave_q.push_back(tr);
    update_coverage(tr, "slave");
    `uvm_info("SB_SLAVE", 
              $sformatf("Received slave transaction:\n%s", tr.sprint()), 
              UVM_HIGH)
  endfunction

  // Coverage update method
  protected function void update_coverage(apb_seq_item tr, string src);
    cov.addr  = tr.paddr;
    cov.wr    = tr.pwrite;
    cov.wdata = tr.pwdata;
    cov.rdata = tr.prdata;
    cov.error = tr.pslverr;
    
    // Protocol state tracking
    if (!tr.psel && !tr.penable) 
      cov.state = 0; // IDLE
    else if (tr.psel && !tr.penable) 
      cov.state = 1; // SETUP
    else if (tr.psel && tr.penable) 
      cov.state = 2; // ACCESS
    
    apb_cg.sample(cov.addr, cov.wr, cov.wdata, cov.rdata, cov.error, cov.state);
    
    `uvm_info("SB_COV", 
              $sformatf("%s coverage sampled - Addr:0x%0h %s WDATA:0x%0h RDATA:0x%0h %s",
              src, cov.addr, cov.wr ? "WR" : "RD", cov.wdata, cov.rdata,
              cov.error ? "ERROR" : "OK"), 
              UVM_MEDIUM)
  endfunction

  // Run phase - transaction comparison
  task run_phase(uvm_phase phase);
    apb_seq_item exp, act;
    
    forever begin
      // Wait for transactions
      wait (master_q.size() > 0 && slave_q.size() > 0);
      
      // Get transactions
      exp = master_q.pop_front();
      act = slave_q.pop_front();
      
      // Compare addresses
      if (exp.paddr !== act.paddr) begin
        `uvm_error("ADDR_MISMATCH", 
                  $sformatf("Address mismatch! Exp:0x%0h Act:0x%0h",
                  exp.paddr, act.paddr))
      end
      
      // Compare write data vs read back data
      if (exp.pwrite && (exp.pwdata !== act.prdata)) begin
        `uvm_error("WDATA_MISMATCH",
                  $sformatf("Write data mismatch! Exp:0x%0h Act:0x%0h",
                  exp.pwdata, act.prdata))
      end
      
      // Compare expected read data
      if (!exp.pwrite && (exp.prdata !== act.prdata)) begin
        `uvm_error("RDATA_MISMATCH",
                  $sformatf("Read data mismatch! Exp:0x%0h Act:0x%0h",
                  exp.prdata, act.prdata))
      end
      
      // Check protocol timing
      if (act.penable && !act.psel) begin
        `uvm_error("PROTOCOL_ERR", "penable high without psel!")
      end
      
      // Successful transaction
      if (exp.paddr === act.paddr && 
          ((exp.pwrite && (exp.pwdata === act.prdata)) || 
           (!exp.pwrite && (exp.prdata === act.prdata)))) begin
        `uvm_info("TX_PASS", 
                 $sformatf("Transaction passed @0x%0h %s Data:0x%0h",
                 exp.paddr, exp.pwrite ? "WR" : "RD", 
                 exp.pwrite ? exp.pwdata : exp.prdata),
                 UVM_MEDIUM)
      end
    end
  endtask

  // Report phase - show coverage
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("COV_REPORT", 
              $sformatf("APB Scoreboard Coverage: %.2f%%", 
              apb_cg.get_coverage()), 
              UVM_MEDIUM)
  endfunction
endclass