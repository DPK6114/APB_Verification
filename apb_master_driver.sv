class apb_master_driver extends uvm_driver #(apb_seq_item);

  `uvm_component_utils(apb_master_driver)

  virtual apb_if vif;
  apb_seq_item req;

  // APB FSM states
  typedef enum logic [1:0] {IDLE, SETUP, ACCESS} apb_state_t;
  apb_state_t state;

  // Constructor
  function new(string name = "apb_master_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  // Build phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", {"Interface must be set for: ", get_full_name()})
  endfunction

  // Run phase
  task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      drive(req);  // Write followed by read
      seq_item_port.item_done();
    end
  endtask

  // Drive task: Write then Read using FSM
  task drive(apb_seq_item req);

    // IDLE
    state = IDLE;
    vif.paddr   <= 0;
    vif.pwdata  <= 0;
    vif.pwrite  <= 0;
    vif.psel    <= 0;
    vif.penable <= 0;
    @(posedge vif.pclk);

    // ---------------------------------------------------
    // WRITE TRANSACTION
    // ---------------------------------------------------

    // SETUP phase (WRITE)
    state = SETUP;
    vif.paddr   <= req.paddr;
    vif.pwdata  <= req.pwdata;
    vif.pwrite  <= 1;
    vif.psel    <= 1;
    vif.penable <= 0;
    @(posedge vif.pclk);

    // ACCESS phase (WRITE)
    state = ACCESS;
    vif.penable <= 1;
    wait (vif.pready);
    @(posedge vif.pclk);

    // Return to IDLE
    vif.psel    <= 0;
    vif.penable <= 0;
    @(posedge vif.pclk);

    // ---------------------------------------------------
    // READ TRANSACTION
    // ---------------------------------------------------

    // SETUP phase (READ)
    state = SETUP;
    vif.paddr   <= req.paddr;
    vif.pwdata  <= 0;
    vif.pwrite  <= 0;
    vif.psel    <= 1;
    vif.penable <= 0;
    @(posedge vif.pclk);

    // ACCESS phase (READ)
    state = ACCESS;
    vif.penable <= 1;
    wait (vif.pready);
    req.prdata = vif.prdata;
    @(posedge vif.pclk);

    // Return to IDLE
    state = IDLE;
    vif.psel    <= 0;
    vif.penable <= 0;
  endtask

endclass
