module apb_peripheral (
  input  wire        pclk,
  input  wire        prst_n,     // active low reset

  input  wire [31:0] paddr,
  input  wire [31:0] pwdata,
  input  wire        pwrite,
  input  wire        psel,
  input  wire        penable,

  output reg  [31:0] prdata,
  output reg         pready,
  output reg         pslverr
);

  // ------------------------------------------
  // FSM States for APB Protocol
  // ------------------------------------------
  typedef enum logic [1:0] {
    IDLE,
    SETUP,
    ACCESS
  } apb_state_t;

  apb_state_t state, next_state;

  // ------------------------------------------
  // Simple Register File (e.g., 256 x 32-bit)
  // ------------------------------------------
  reg [31:0] mem [0:255];  // Can scale up as needed

  // Latched values from SETUP phase
  reg [31:0] addr_reg;
  reg [31:0] wdata_reg;
  reg        write_reg;

  // ------------------------------------------
  // FSM - State Register
  // ------------------------------------------
  always_ff @(posedge pclk or negedge prst_n) begin
    if (!prst_n)
      state <= IDLE;
    else
      state <= next_state;
  end

  // ------------------------------------------
  // FSM - Next State Logic
  // ------------------------------------------
  always_comb begin
    case (state)
      IDLE:   next_state = (psel && !penable) ? SETUP : IDLE;
      SETUP:  next_state = ACCESS;
      ACCESS: next_state = (psel && penable) ? IDLE : ACCESS;
      default: next_state = IDLE;
    endcase
  end

  // ------------------------------------------
  // Output and Action Logic
  // ------------------------------------------
  always_ff @(posedge pclk or negedge prst_n) begin
    if (!prst_n) begin
      pready   <= 0;
      prdata   <= 32'h0;
      pslverr  <= 0;
    end else begin
      pready   <= 0;
      pslverr  <= 0;

      case (state)

        IDLE: begin
          // Clear everything
          pready   <= 0;
          prdata   <= 32'h0;
        end

        SETUP: begin
          // Latch inputs
          addr_reg  <= paddr[9:2]; // word aligned access (256 entries)
          wdata_reg <= pwdata;
          write_reg <= pwrite;
        end

        ACCESS: begin
          pready <= 1;

          // Check for out-of-range address
          if (addr_reg > 8'd255) begin
            pslverr <= 1;
          end else begin
            if (write_reg) begin
              // Write operation
              mem[addr_reg] <= wdata_reg;
            end else begin
              // Read operation
              prdata <= mem[addr_reg];
            end
          end
        end

      endcase
    end
  end

endmodule
