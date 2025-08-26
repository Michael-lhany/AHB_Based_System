`timescale 1ns/100ps

module AHB_TOP #(
parameter DATA_WIDTH = 32,
parameter REG_FILE_DEPTH = 16,
parameter ADDR_WIDTH = 32
)
(

/////////////// COMMON SIGNALS //////////////////


input  logic 				  HCLK,
input  logic 				  HRESETn,
output logic 				  pwm, 
output logic 				  wd_rst,

/////////////// MASTER 0 INTERFACE //////////////////


input  logic [ADDR_WIDTH-1:0] HADDR_M0,
input  logic                  HWRITE_M0,
input  logic [DATA_WIDTH-1:0] HWDATA_M0,
input  logic [1:0]            HTRANS_M0,
input  logic [2:0]            HSIZE_M0,
input  logic [3:0]            HPROT_M0,
input  logic [2:0]            HBURST_M0,
input  logic                  req0,

output logic [DATA_WIDTH-1:0] HRDATA_M0,
output logic                  HREADY_M0,
output logic 		          HRESP_M0,


/////////////// MASTER 1 INTERFACE //////////////////


input  logic [ADDR_WIDTH-1:0] HADDR_M1,
input  logic                  HWRITE_M1,
input  logic [DATA_WIDTH-1:0] HWDATA_M1,
input  logic [1:0]            HTRANS_M1,
input  logic [2:0]            HSIZE_M1,
input  logic [3:0]            HPROT_M1,
input  logic [2:0]            HBURST_M1,
input  logic                  req1,

output logic [DATA_WIDTH-1:0] HRDATA_M1,
output logic                  HREADY_M1,
output logic                  HRESP_M1


);


/////////////// Internal signals //////////////////
logic HSEL0, HSEL1, HSEL2;
logic [DATA_WIDTH-1:0] HRDATA0, HRDATA1, HRDATA2;
logic HRESP0, HRESP1, HRESP2;
logic HREADY0, HREADY1, HREADY2;
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

//APB bridge signals
logic                  PSEL;
logic                  PENABLE;
logic [ADDR_WIDTH-1:0] PADDR;
logic [DATA_WIDTH-1:0] PWDATA;
logic [DATA_WIDTH-1:0] PRDATA;
logic                  PREADY;
logic                  PSLVERR;

//APB Reg file signals
logic                  rd_en_r_apb;
logic                  wr_en_r_apb;
logic [ADDR_WIDTH-1:0] address_r_apb;
logic [DATA_WIDTH-1:0] wr_data_r_apb;
logic [DATA_WIDTH-1:0] rd_data_r_apb;
logic                  ready_r_apb;
logic                  error_r_apb;

//Arbiter signls
logic [2:0] HSIZE;
logic [3:0] HPROT;
logic [2:0] HBURST;
logic [ADDR_WIDTH-1:0] HADDR;
logic HWRITE;
logic [1:0] HTRANS;
logic [DATA_WIDTH-1:0] HWDATA;
logic HREADY;
logic [DATA_WIDTH-1:0] HRDATA;
logic HRESP;


/////////////// Arbiter //////////////////


arbiter #(.DATA_WIDTH(DATA_WIDTH),.ADDR_WIDTH(ADDR_WIDTH)) arb (
.HADDR_M0  (HADDR_M0),
.HPROT_M0  (HPROT_M0),
.HRESP_M0  (HRESP_M0),
.HSIZE_M0  (HSIZE_M0),
.HBURST_M0 (HBURST_M0),
.HRDATA_M0 (HRDATA_M0),
.HREADY_M0 (HREADY_M0),
.HTRANS_M0 (HTRANS_M0),
.HWDATA_M0 (HWDATA_M0),
.HWRITE_M0 (HWRITE_M0),
.req0      (req0),
.HADDR_M1  (HADDR_M1),
.HPROT_M1  (HPROT_M1),
.HRESP_M1  (HRESP_M1),
.HSIZE_M1  (HSIZE_M1),
.HBURST_M1 (HBURST_M1),
.HRDATA_M1 (HRDATA_M1),
.HREADY_M1 (HREADY_M1),
.HTRANS_M1 (HTRANS_M1),
.HWDATA_M1 (HWDATA_M1),
.HWRITE_M1 (HWRITE_M1),
.req1      (req1),
.HADDR_OUT (HADDR),
.HWRITE_OUT(HWRITE),
.HWDATA_OUT(HWDATA),
.HTRANS_OUT(HTRANS),
.HSIZE_OUT (HSIZE),
.HPROT_OUT (HPROT),
.HBURST_OUT(HBURST),
.HRDATA_IN (HRDATA),
.HREADY_IN (HREADY),
.HRESP_IN  (HRESP)
);


/////////////// Reset synchronizers //////////////////
rst_sync reset_sync(
.clk     (HCLK),
.rst     (HRESETn),
.sync_rst(sync_rst)
);




/////////////////// Bus decoder /////////////////////
decoder  #( .ADDR_WIDTH(ADDR_WIDTH) ) dec (
.HADDR(HADDR),
.HSEL0(HSEL0),
.HSEL1(HSEL1),
.HSEL2(HSEL2)
);




/////////////////// Bus mux /////////////////////
mux  #( .DATA_WIDTH(DATA_WIDTH) ) bus_mux(
.HSEL0  (HSEL0),
.HSEL1  (HSEL1),
.HSEL2  (HSEL2),
.HRESP0 (HRESP0),
.HRESP1 (HRESP1),
.HRESP2 (HRESP2),
.HRDATA0(HRDATA0),
.HRDATA1(HRDATA1),
.HRDATA2(HRDATA2),
.HREADY0(HREADY0),
.HREADY1(HREADY1),
.HREADY2(HREADY2),
.HREADY (HREADY),
.HRESP  (HRESP),
.HRDATA (HRDATA)
);




///////////////// Register File ///////////////////
Reg_File #(.DATA_WIDTH(DATA_WIDTH), .REG_FILE_DEPTH(REG_FILE_DEPTH)) reg_file (
.clk (HCLK),
.rst (sync_rst),
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
.HCLK	(HCLK),
.HRESETn (sync_rst),
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
.clk (HCLK),
.rst (sync_rst),
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
.HCLK	(HCLK),
.HRESETn (sync_rst),
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


/////////////////// ahb2apb bridge /////////////////////
ahb2apb_bridge #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) ahb2apb (
.HCLK   (HCLK),
.HRESETn(sync_rst),
.HSEL   (HSEL2),
.HADDR  (HADDR),
.HTRANS (HTRANS),
.HWRITE (HWRITE),
.HSIZE  (HSIZE),
.HWDATA (HWDATA),
.HRDATA (HRDATA2),
.HREADY (HREADY2),
.HRESP  (HRESP2),
.PSEL   (PSEL),
.PENABLE(PENABLE),
.PWRITE (PWRITE),
.PADDR  (PADDR),
.PWDATA (PWDATA),
.PRDATA (PRDATA),
.PREADY (PREADY),
.PSLVERR(PSLVERR)
);


/////////////////// APB slave  /////////////////////
generic_apb_slave #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) slave_apb_reg (
.PSEL   (PSEL),
.PENABLE(PENABLE),
.PWRITE (PWRITE),
.PADDR  (PADDR),
.PWDATA (PWDATA),
.error  (error_r_apb),
.rd_en  (rd_en_r_apb),
.ready  (ready_r_apb),
.wr_en  (wr_en_r_apb),
.address(address_r_apb),
.rd_data(rd_data_r_apb),
.wr_data(wr_data_r_apb),
.PRDATA (PRDATA),
.PREADY (PREADY),
.PSLVERR(PSLVERR)
);


///////////////// APB Register File ///////////////////
Reg_File #(.DATA_WIDTH(DATA_WIDTH), .REG_FILE_DEPTH(REG_FILE_DEPTH)) apb_reg_file (
.clk (HCLK),
.rst (sync_rst),
.rd_data(rd_data_r_apb),
.ready  (ready_r_apb),
.error  (error_r_apb),
.rd_en  (rd_en_r_apb),
.wr_en  (wr_en_r_apb),
.address(address_r_apb),
.wr_data(wr_data_r_apb)
);


endmodule 