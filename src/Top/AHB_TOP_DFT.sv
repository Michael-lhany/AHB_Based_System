`timescale 1ns/100ps

module AHB_TOP #(
parameter DATA_WIDTH = 32,
parameter REG_FILE_DEPTH = 16,
parameter ADDR_WIDTH = 32
)
(
input logic HCLK,
input logic HRESETn,
input logic [2:0] HSIZE,
input logic [3:0] HPROT,
input logic [2:0] HBURST,
input logic [ADDR_WIDTH-1:0] HADDR,
input logic HWRITE,
input logic [1:0] HTRANS,
input logic [DATA_WIDTH-1:0] HWDATA,
output logic HREADY,
output logic [DATA_WIDTH-1:0] HRDATA,
output logic HRESP,
output logic pwm, 
output logic wd_rst,

// DFT signals 
input logic scan_in,
input logic scan_shift_en,
input logic test_mode,
input logic scan_clk,
input logic scan_rst,
output logic scan_out
);



/////////////// Internal signals //////////////////
logic HSEL0, HSEL1;
logic [DATA_WIDTH-1:0] HRDATA0, HRDATA1;
logic HRESP0, HRESP1;
logic HREADY0, HREADY1;
logic sync_rst;

//Reg file signals
logic                  rd_en_r;
logic                  wr_en_r;
logic [ADDR_WIDTH-1:0] address_r;
logic [DATA_WIDTH-1:0] wr_data_r;
logic [DATA_WIDTH-1:0] rd_data_r;
logic                  ready_r;
logic                  error_r;

//Timer/PWM signals
logic                  rd_en_t;
logic                  wr_en_t;
logic [ADDR_WIDTH-1:0] address_t;
logic [DATA_WIDTH-1:0] wr_data_t;
logic [DATA_WIDTH-1:0] rd_data_t;
logic                  ready_t;
logic                  error_t; 


//////////////  DFT Internal signals  ////////////////

logic ref_scan_clk;
logic ref_scan_rst;
logic ref_scan_sync_rst;

///////////////////  DFT muxes  /////////////////////
mux2X1 U0_mux2X1 (
.IN_0(HCLK),
.IN_1(scan_clk),
.SEL(test_mode),
.OUT(ref_scan_clk)
); 


mux2X1 U1_mux2X1 (
.IN_0(HRESETn),
.IN_1(scan_rst),
.SEL(test_mode),
.OUT(ref_scan_rst)
); 


mux2X1 U2_mux2X1 (
.IN_0(sync_rst),
.IN_1(scan_rst),
.SEL(test_mode),
.OUT(ref_scan_sync_rst)
); 


/////////////// Reset synchronizers //////////////////
rst_sync reset_sync(
.clk     (ref_scan_clk),
.rst     (ref_scan_rst),
.sync_rst(sync_rst)
);


/////////////////// Bus decoder /////////////////////
decoder  #( .ADDR_WIDTH(ADDR_WIDTH) ) dec (
.HADDR(HADDR),
.HSEL0(HSEL0),
.HSEL1(HSEL1)
);




/////////////////// Bus mux /////////////////////
mux  #( .DATA_WIDTH(DATA_WIDTH) ) bus_mux(
.HSEL0  (HSEL0),
.HSEL1  (HSEL1),
.HRESP1 (HRESP1),
.HRESP0 (HRESP0),
.HRDATA0(HRDATA0),
.HRDATA1(HRDATA1),
.HREADY0(HREADY0),
.HREADY1(HREADY1),
.HREADY (HREADY),
.HRESP  (HRESP),
.HRDATA (HRDATA)
);




///////////////// Register File ///////////////////
Reg_File #(.DATA_WIDTH(DATA_WIDTH), .REG_FILE_DEPTH(REG_FILE_DEPTH)) reg_file (
.clk (ref_scan_clk),
.rst (ref_scan_sync_rst),
.rd_data(rd_data_r),
.ready  (ready_r),
.error  (error_r),
.rd_en  (rd_en_r),
.wr_en  (wr_en_r),
.address(address_r),
.wr_data(wr_data_r)
);




/////////////////// reg slave /////////////////////
generic_slave slave_reg (
.HCLK	(ref_scan_clk),
.HRESETn (ref_scan_sync_rst),
.HSIZE   (HSIZE),
.HPROT   (HPROT),
.HBURST  (HBURST),
.HADDR   (HADDR),
.HWRITE  (HWRITE),
.HTRANS  (HTRANS),
.HWDATA  (HWDATA),
.HRESP   (HRESP0),
.HRDATA  (HRDATA0),
.HREADY  (HREADY0),
.HSEL    (HSEL0),
.rd_data(rd_data_r),
.ready  (ready_r),
.error  (error_r),
.rd_en  (rd_en_r),
.wr_en  (wr_en_r),
.address(address_r),
.wr_data(wr_data_r)
);




///////////////////// Timer ///////////////////////
Timer #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) timer (
.clk (ref_scan_clk),
.rst (ref_scan_sync_rst),
.rd_data(rd_data_t),
.ready  (ready_t),
.error  (error_t),
.rd_en  (rd_en_t),
.wr_en  (wr_en_t),
.address(address_t),
.wr_data(wr_data_t),
.pwm(pwm),
.wd_rst (wd_rst)
);



/////////////////// timer slave /////////////////////
generic_slave slave_timer (
.HCLK	(ref_scan_clk),
.HRESETn (ref_scan_sync_rst),
.HSIZE   (HSIZE),
.HPROT   (HPROT),
.HBURST  (HBURST),
.HADDR   (HADDR),
.HWRITE  (HWRITE),
.HTRANS  (HTRANS),
.HWDATA  (HWDATA),
.HRESP   (HRESP1),
.HRDATA  (HRDATA1),
.HREADY  (HREADY1),
.HSEL    (HSEL1),
.rd_data(rd_data_t),
.ready  (ready_t),
.error  (error_t),
.rd_en  (rd_en_t),
.wr_en  (wr_en_t),
.address(address_t),
.wr_data(wr_data_t)
);



endmodule 
