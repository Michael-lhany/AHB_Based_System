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

output logic [DATA_WIDTH-1:0] HRDATA_M1,
output logic                  HREADY_M1,
output logic                  HRESP_M1


);


/////////////// Internal signals //////////////////
logic HSEL0_M0, HSEL1_M0, HSEL2_M0;
logic HSEL0_M1, HSEL1_M1, HSEL2_M1;
logic HSEL_OUT_S0, HSEL_OUT_S1, HSEL_OUT_S2;
logic [DATA_WIDTH-1:0] HRDATA0_M0, HRDATA1_M0, HRDATA2_M0;
logic [DATA_WIDTH-1:0] HRDATA0_M1, HRDATA1_M1, HRDATA2_M1;
logic HRESP0_M0, HRESP1_M0, HRESP2_M0;
logic HRESP0_M1, HRESP1_M1, HRESP2_M1;
logic HREADY0_M0, HREADY1_M0, HREADY2_M0;
logic HREADY0_M1, HREADY1_M1, HREADY2_M1;
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
logic [2:0] HSIZE_S0, HSIZE_S1, HSIZE_S2;
logic [3:0] HPROT_S0, HPROT_S1, HPROT_S2;
logic [2:0] HBURST_S0, HBURST_S1, HBURST_S2;
logic [ADDR_WIDTH-1:0] HADDR_S0, HADDR_S1, HADDR_S2;
logic HWRITE_S0, HWRITE_S1, HWRITE_S2;
logic [1:0] HTRANS_S0, HTRANS_S1, HTRANS_S2;
logic [DATA_WIDTH-1:0] HWDATA_S0, HWDATA_S1, HWDATA_S2;
logic HREADY_S0, HREADY_S1, HREADY_S2;
logic [DATA_WIDTH-1:0] HRDATA_S0, HRDATA_S1, HRDATA_S2;
logic HRESP_S0, HRESP_S1, HRESP_S2;
logic HREADY_M0_A0, HREADY_M0_A1, HREADY_M0_A2;
logic [DATA_WIDTH-1:0] HRDATA_M0_A0, HRDATA_M0_A1, HRDATA_M0_A2;
logic HRESP_M0_A0, HRESP_M0_A1, HRESP_M0_A2;
logic HREADY_M1_A0, HREADY_M1_A1, HREADY_M1_A2;
logic [DATA_WIDTH-1:0] HRDATA_M1_A0, HRDATA_M1_A1, HRDATA_M1_A2;
logic HRESP_M1_A0, HRESP_M1_A1, HRESP_M1_A2;



/////////////// Reset synchronizers //////////////////
rst_sync reset_sync(
.clk     (HCLK),
.rst     (HRESETn),
.sync_rst(sync_rst)
);


/////////////////// Bus decoder for master 0 /////////////////////
decoder  #( .ADDR_WIDTH(ADDR_WIDTH) ) dec_M0 (
.HADDR(HADDR_M0),
.HSEL0(HSEL0_M0),
.HSEL1(HSEL1_M0),
.HSEL2(HSEL2_M0)
);


/////////////////// Bus decoder for master 1 /////////////////////
decoder  #( .ADDR_WIDTH(ADDR_WIDTH) ) dec_M1 (
.HADDR(HADDR_M1),
.HSEL0(HSEL0_M1),
.HSEL1(HSEL1_M1),
.HSEL2(HSEL2_M1)
);


/////////////////// Bus mux for master 0 /////////////////////
mux  #( .DATA_WIDTH(DATA_WIDTH) ) bus_mux_M0(
.HSEL0  (HSEL0_M0),
.HSEL1  (HSEL1_M0),
.HSEL2  (HSEL2_M0),
.HRESP0 (HRESP_M0_A0),
.HRESP1 (HRESP_M0_A1),
.HRESP2 (HRESP_M0_A2),
.HRDATA0(HRDATA_M0_A0),
.HRDATA1(HRDATA_M0_A1),
.HRDATA2(HRDATA_M0_A2),
.HREADY0(HREADY_M0_A0),
.HREADY1(HREADY_M0_A1),
.HREADY2(HREADY_M0_A2),
.HREADY (HREADY_M0),
.HRESP  (HRESP_M0),
.HRDATA (HRDATA_M0)
);	


/////////////////// Bus mux for master 1 /////////////////////
mux  #( .DATA_WIDTH(DATA_WIDTH) ) bus_mux_M1(
.HSEL0  (HSEL0_M1),
.HSEL1  (HSEL1_M1),
.HSEL2  (HSEL2_M1),
.HRESP0 (HRESP_M1_A0),
.HRESP1 (HRESP_M1_A1),
.HRESP2 (HRESP_M1_A2),
.HRDATA0(HRDATA_M1_A0),
.HRDATA1(HRDATA_M1_A1),
.HRDATA2(HRDATA_M1_A2),
.HREADY0(HREADY_M1_A0),
.HREADY1(HREADY_M1_A1),
.HREADY2(HREADY_M1_A2),
.HREADY (HREADY_M1),
.HRESP  (HRESP_M1),
.HRDATA (HRDATA_M1)
);	

/////////////// Arbiter slave 0 //////////////////


arbiter #(.DATA_WIDTH(DATA_WIDTH),.ADDR_WIDTH(ADDR_WIDTH)) arb_S0 (
.HADDR_M0  (HADDR_M0),
.HPROT_M0  (HPROT_M0),
.HRESP_M0  (HRESP_M0_A0),
.HSIZE_M0  (HSIZE_M0),
.HBURST_M0 (HBURST_M0),
.HRDATA_M0 (HRDATA_M0_A0),
.HREADY_M0 (HREADY_M0_A0),
.HTRANS_M0 (HTRANS_M0),
.HWDATA_M0 (HWDATA_M0),
.HWRITE_M0 (HWRITE_M0),
.HSEL_0    (HSEL0_M0),
.HADDR_M1  (HADDR_M1),
.HPROT_M1  (HPROT_M1),
.HRESP_M1  (HRESP_M1_A0),
.HSIZE_M1  (HSIZE_M1),
.HBURST_M1 (HBURST_M1),
.HRDATA_M1 (HRDATA_M1_A0),
.HREADY_M1 (HREADY_M1_A0),
.HTRANS_M1 (HTRANS_M1),
.HWDATA_M1 (HWDATA_M1),
.HWRITE_M1 (HWRITE_M1),
.HSEL_1    (HSEL0_M1),
.HADDR_OUT (HADDR_S0),
.HWRITE_OUT(HWRITE_S0),
.HWDATA_OUT(HWDATA_S0),
.HTRANS_OUT(HTRANS_S0),
.HSIZE_OUT (HSIZE_S0),
.HPROT_OUT (HPROT_S0),
.HBURST_OUT(HBURST_S0),
.HRDATA_IN (HRDATA_S0),
.HREADY_IN (HREADY_S0),
.HRESP_IN  (HRESP_S0),
.HSEL_OUT  (HSEL_OUT_S0)
); 


/////////////////// reg slave /////////////////////
generic_slave slave_reg (
.HCLK	(HCLK),
.HRESETn (sync_rst),
.HSIZE   (HSIZE_S0),
.HPROT   (HPROT_S0),
.HBURST  (HBURST_S0),
.HADDR   (HADDR_S0),
.HWRITE  (HWRITE_S0),
.HTRANS  (HTRANS_S0),
.HWDATA  (HWDATA_S0),
.HRESP   (HRESP_S0),
.HRDATA  (HRDATA_S0),
.HREADY  (HREADY_S0),
.HSEL    (HSEL_OUT_S0),
.rd_data(rd_data_r),
.ready  (ready_r),
.error  (error_r),
.rd_en  (rd_en_r),
.wr_en  (wr_en_r),
.address(address_r),
.wr_data(wr_data_r)
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


/////////////// Arbiter slave 0 //////////////////


arbiter #(.DATA_WIDTH(DATA_WIDTH),.ADDR_WIDTH(ADDR_WIDTH)) arb_S1 (
.HADDR_M0  (HADDR_M0),
.HPROT_M0  (HPROT_M0),
.HRESP_M0  (HRESP_M0_A1),
.HSIZE_M0  (HSIZE_M0),
.HBURST_M0 (HBURST_M0),
.HRDATA_M0 (HRDATA_M0_A1),
.HREADY_M0 (HREADY_M0_A1),
.HTRANS_M0 (HTRANS_M0),
.HWDATA_M0 (HWDATA_M0),
.HWRITE_M0 (HWRITE_M0),
.HSEL_0    (HSEL1_M0),
.HADDR_M1  (HADDR_M1),
.HPROT_M1  (HPROT_M1),
.HRESP_M1  (HRESP_M1_A1),
.HSIZE_M1  (HSIZE_M1),
.HBURST_M1 (HBURST_M1),
.HRDATA_M1 (HRDATA_M1_A1),
.HREADY_M1 (HREADY_M1_A1),
.HTRANS_M1 (HTRANS_M1),
.HWDATA_M1 (HWDATA_M1),
.HWRITE_M1 (HWRITE_M1),
.HSEL_1    (HSEL1_M1),
.HADDR_OUT (HADDR_S1),
.HWRITE_OUT(HWRITE_S1),
.HWDATA_OUT(HWDATA_S1),
.HTRANS_OUT(HTRANS_S1),
.HSIZE_OUT (HSIZE_S1),
.HPROT_OUT (HPROT_S1),
.HBURST_OUT(HBURST_S1),
.HRDATA_IN (HRDATA_S1),
.HREADY_IN (HREADY_S1),
.HRESP_IN  (HRESP_S1),
.HSEL_OUT  (HSEL_OUT_S1)
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
.HSIZE   (HSIZE_S1),
.HPROT   (HPROT_S1),
.HBURST  (HBURST_S1),
.HADDR   (HADDR_S1),
.HWRITE  (HWRITE_S1),
.HTRANS  (HTRANS_S1),
.HWDATA  (HWDATA_S1),
.HRESP   (HRESP_S1),
.HRDATA  (HRDATA_S1),
.HREADY  (HREADY_S1),
.HSEL    (HSEL_OUT_S1),
.rd_data(rd_data_t),
.ready  (ready_t),
.error  (error_t),
.rd_en  (rd_en_t),
.wr_en  (wr_en_t),
.address(address_t),
.wr_data(wr_data_t)
);



/////////////// Arbiter slave 2 //////////////////


arbiter #(.DATA_WIDTH(DATA_WIDTH),.ADDR_WIDTH(ADDR_WIDTH)) arb_S2 (
.HADDR_M0  (HADDR_M0),
.HPROT_M0  (HPROT_M0),
.HRESP_M0  (HRESP_M0_A2),
.HSIZE_M0  (HSIZE_M0),
.HBURST_M0 (HBURST_M0),
.HRDATA_M0 (HRDATA_M0_A2),
.HREADY_M0 (HREADY_M0_A2),
.HTRANS_M0 (HTRANS_M0),
.HWDATA_M0 (HWDATA_M0),
.HWRITE_M0 (HWRITE_M0),
.HSEL_0    (HSEL2_M0),
.HADDR_M1  (HADDR_M1),
.HPROT_M1  (HPROT_M1),
.HRESP_M1  (HRESP_M1_A2),
.HSIZE_M1  (HSIZE_M1),
.HBURST_M1 (HBURST_M1),
.HRDATA_M1 (HRDATA_M1_A2),
.HREADY_M1 (HREADY_M1_A2),
.HTRANS_M1 (HTRANS_M1),
.HWDATA_M1 (HWDATA_M1),
.HWRITE_M1 (HWRITE_M1),
.HSEL_1    (HSEL2_M1),
.HADDR_OUT (HADDR_S2),
.HWRITE_OUT(HWRITE_S2),
.HWDATA_OUT(HWDATA_S2),
.HTRANS_OUT(HTRANS_S2),
.HSIZE_OUT (HSIZE_S2),
.HPROT_OUT (HPROT_S2),
.HBURST_OUT(HBURST_S2),
.HRDATA_IN (HRDATA_S2),
.HREADY_IN (HREADY_S2),
.HRESP_IN  (HRESP_S2),
.HSEL_OUT  (HSEL_OUT_S2)
);


/////////////////// ahb2apb bridge /////////////////////
ahb2apb_bridge #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) ahb2apb (
.HCLK   (HCLK),
.HRESETn(sync_rst),
.HSEL   (HSEL_OUT_S2),
.HADDR  (HADDR_S2),
.HTRANS (HTRANS_S2),
.HWRITE (HWRITE_S2),
.HSIZE  (HSIZE_S2),
.HWDATA (HWDATA_S2),
.HRDATA (HRDATA_S2),
.HREADY (HREADY_S2),
.HRESP  (HRESP_S2),
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