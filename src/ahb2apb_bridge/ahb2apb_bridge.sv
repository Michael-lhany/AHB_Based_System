module ahb2apb_bridge #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32
)(
  // AHB-Lite slave interface
  input  logic                    HCLK,
  input  logic                    HRESETn,
  input  logic                    HSEL,
  input  logic [ADDR_WIDTH-1:0]   HADDR,
  input  logic [1:0]              HTRANS,   // [NONSEQ|SEQ]=2'b1x valid, 2'b00 IDLE, 2'b01 BUSY
  input  logic                    HWRITE,
  input  logic [2:0]              HSIZE,    // Ignored in this simple bridge
  input  logic [DATA_WIDTH-1:0]   HWDATA,
  output logic [DATA_WIDTH-1:0]   HRDATA,
  output logic                    HREADY,
  output logic                    HRESP,    // 0=OKAY, 1=ERROR per AHB-Lite

  // APB3 master interface
  output logic                    PSEL,
  output logic                    PENABLE,
  output logic                    PWRITE,
  output logic [ADDR_WIDTH-1:0]   PADDR,
  output logic [DATA_WIDTH-1:0]   PWDATA,
  input  logic [DATA_WIDTH-1:0]   PRDATA,
  input  logic                    PREADY,   // If unused, tie high
  input  logic                    PSLVERR   // If unused, tie low
);



  
/////////////////////////////////////////////////////////
/////////////////// Internal signals ////////////////////
/////////////////////////////////////////////////////////



  typedef enum bit [1:0] {  IDLE_STATE = 2'b00,
                            ADDR_STATE = 2'b01,
                            DATA_STATE = 2'b11 } state;


  state     current_state,
            next_state ;

  logic [ADDR_WIDTH-1:0]  addr_q;
  logic [DATA_WIDTH-1:0]  wdata_q;
  logic                   write_q;
  logic [DATA_WIDTH-1:0]  rdata_q;
  logic                   hresp_q;





/////////////////////////////////////////////////////////
////////////////// State transitions ////////////////////
/////////////////////////////////////////////////////////
  


  always_ff @(posedge HCLK or negedge HRESETn) begin
    if (~HRESETn) begin
      current_state <= IDLE_STATE;
    end
    else begin
      current_state <= next_state;
    end
  end 



/////////////////////////////////////////////////////////
////////////////// Next State Logic /////////////////////
/////////////////////////////////////////////////////////


// Valid AHB transfer when selected, previous transfer ready, and HTRANS[1] set
  wire ahb_valid = HSEL && HTRANS[1];

  always_comb begin 
    case (current_state)
      IDLE_STATE : begin
        if (ahb_valid) begin
          next_state = ADDR_STATE;
        end else begin
          next_state = current_state;
        end
      end
      ADDR_STATE : begin
        next_state = DATA_STATE;
      end
      DATA_STATE : begin
        if (PREADY) begin
          next_state = IDLE_STATE;
        end
      end
      default : begin
        next_state = current_state;
      end
    endcase
  end


/////////////////////////////////////////////////////////
//////////////////// Output Logic ///////////////////////
/////////////////////////////////////////////////////////



  always_comb begin 
    // AHB outputs (default)
    HREADY = 1'b1;   
    HRESP     = hresp_q;
    HRDATA    = rdata_q;

    // APB outputs (default)
    PSEL      = HSEL;
    PENABLE   = 1'b0;
    PWRITE    = write_q;
    PADDR     = addr_q;
    PWDATA    = wdata_q;

    case (current_state)
      IDLE_STATE : begin
        if (ahb_valid) begin
          PENABLE   = 1'b0;
          HREADY = 1'b0;
        end
      end
      ADDR_STATE : begin
        PENABLE   = 1'b0;
        HREADY = 1'b0;
      end
      DATA_STATE : begin
        PENABLE   = 1'b1;
        if (PREADY) begin
          HREADY = 1'b1;
        end else begin
          HREADY = 1'b0;
        end
      end
      default : begin
        // AHB outputs (default)
        HREADY    = 1'b1;   
        HRESP     = hresp_q;
        HRDATA    = rdata_q;

        // APB outputs (default)
        PSEL      = HSEL;
        PENABLE   = 1'b0;
        PWRITE    = write_q;
        PADDR     = addr_q;
        PWDATA    = wdata_q;
      end
    endcase
  end
  


/////////////////////////////////////////////////////////
/////////////////// Internal Logic //////////////////////
/////////////////////////////////////////////////////////

  // Sequential: capture AHB and APB info
  always_ff @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
      addr_q  <= '0;
      wdata_q <= '0;
      write_q <= 1'b0;
      rdata_q <= '0;
      hresp_q <= 1'b0;
    end else begin
      if (current_state == IDLE_STATE && ahb_valid) begin
        addr_q  <= HADDR;
        wdata_q <= HWDATA;
        write_q <= HWRITE;
        hresp_q <= 1'b0;
      end

      // On ACCESS completion, sample read data and error
      if (current_state == DATA_STATE && PREADY) begin
        if (!write_q) begin
          rdata_q <= PRDATA;
        end
        hresp_q <= PSLVERR; // 1=ERROR, 0=OKAY
      end
    end
  end

endmodule : ahb2apb_bridge