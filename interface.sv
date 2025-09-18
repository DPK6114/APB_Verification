interface apb_if(input logic pclk,prst_n);
  
  
  logic [31:0] paddr;
  logic [31:0] pwdata;
  logic        pwrite;
  logic        psel;
  logic        penable;
  logic        pready;
  logic        pslverr;
  logic [31:0] prdata;
  
  
  
  
endinterface