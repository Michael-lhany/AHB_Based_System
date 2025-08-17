`timescale 1ns/100ps

module AHB_tb ();


/////////////////////////////////////////////////////////
//////////// Parameters & Internal signals //////////////
/////////////////////////////////////////////////////////


parameter DATA_WIDTH_tb = 32;
parameter ADDR_WIDTH_tb = 32;
parameter REG_FILE_DEPTH_tb = 16;
parameter CLK_PER = 10;

//HWRITE types
typedef enum logic  {  OKAY  = 1'b0 ,
                       ERROR = 1'b1  } hresp;


//HRESP types
typedef enum logic  {  READ  = 1'b0 ,
                       WRITE = 1'b1  } hwrite;


//HSIZE types
typedef enum logic [2:0]   {  BYTE  = 3'b000 ,
                              HWORD = 3'b001 ,
                              WORD  = 3'b010 ,
                              DWORD = 3'b011 ,                    
                              FWORD = 3'b100 ,
                              EWORD = 3'b101  } hsize;


//HTRANS types
typedef enum logic [1:0]   {  IDLE   = 2'b00 ,
                              BUSY   = 2'b01 ,
                              NONSEQ = 2'b10 ,
                              SEQ    = 2'b11  } htrans;


//HBURST types
typedef enum logic [2:0]   {  SINGLE = 3'b000 ,
                              INCR   = 3'b001 ,
                              WRAP4  = 3'b010 ,
                              INCR4  = 3'b011 ,                    
                              WRAP8  = 3'b100 ,
                              INCR8  = 3'b101 ,
                              WRAP16 = 3'b110 ,
                              INCR16 = 3'b111  } hburst;

//Correct and error counts
int correct_count;
int error_count;

logic [ADDR_WIDTH_tb-1:0] addresses [0:7];

/////////////////////////////////////////////////////////
//////////////////// DUT Signals ////////////////////////
/////////////////////////////////////////////////////////

//Inputs to the DUT
logic HCLK;
logic HRESETn;
hwrite HWRITE;
hsize HSIZE;
logic [3:0] HPROT;
hburst HBURST;
logic [ADDR_WIDTH_tb-1:0] HADDR;
htrans HTRANS;
logic [DATA_WIDTH_tb-1:0] HWDATA;

//Outputs from the DUT
logic HREADY;
logic HRESP;
logic [DATA_WIDTH_tb-1:0] HRDATA;
logic pwm;
logic wd_rst;


//////////////////////////////////////////////////////// 
///////////////// Design Instaniation //////////////////
////////////////////////////////////////////////////////


AHB_TOP #(.DATA_WIDTH(DATA_WIDTH_tb),.REG_FILE_DEPTH(REG_FILE_DEPTH_tb),.ADDR_WIDTH(ADDR_WIDTH_tb)) DUT (.*);


//////////////////////////////////////////////////////// 
///////////////////// Clock Generator //////////////////
////////////////////////////////////////////////////////
 

always #(CLK_PER/2) HCLK = ~HCLK ;


////////////////////////////////////////////////////////
////////////////// initial block /////////////////////// 
////////////////////////////////////////////////////////


initial begin

 $dumpfile("ahb.vcd") ;       
 $dumpvars(0,AHB_tb); 


 // Initialization
 initialize() ;


 // Reset
 reset() ;








////////////////////////////////////////////////////////
///////////////// Timer/WD/PWM tests /////////////////// 
////////////////////////////////////////////////////////

//Simple write in the timer_ctrl reg (Data: 32'h05 & Address:{2'b01,30'h08} & Size: Word) to activate the normal mode timer
 Simple_Write({32'b001}, {2'b01,30'h00}, WORD);

//Simple write in the timer_load reg (Data: 32'h05 & Address:{2'b01,30'h08} & Size: Word)
 Simple_Write(32'h05, {2'b01,30'h04}, WORD);

 @(negedge  HCLK);
 @(negedge  HCLK);

 //Simple read from the timer_count reg (Address:{2'b01,30'h10} & Size: Word)
 Simple_Read({2'b01,30'h10}, WORD);

 //Simple read from the timer_status reg (Address:{2'b01,30'h14} & Size: Word)
 Simple_Read({2'b01,30'h14}, WORD);


 //simple write in the timer_ctrl reg (Data: 32'b010 & Address:{2'b01,30'h08} & Size: Word) to activate the watch dog
 Simple_Write({32'b010}, {2'b01,30'h00}, WORD);

 @(posedge wd_rst);

 reset() ;

 //simple write in the pwm_thres reg (Data: 32'b100 & Address:{2'b01,30'h08} & Size: Word) to change the threshold of the pwm
 Simple_Write({32'b010}, {2'b01,30'h0C}, WORD);

 //simple write in the timer_ctrl reg (Data: 32'b100 & Address:{2'b01,30'h08} & Size: Word) to activate the pwm
 Simple_Write({32'b100}, {2'b01,30'h00}, WORD);

@(posedge pwm);
@(negedge pwm);

@(negedge HCLK);

////////////////////////////////////////////////////////
////////////////// Reg File tests ////////////////////// 
////////////////////////////////////////////////////////

 //Simple write (Data: 32'h0A & Address:32'h00 & Size: Word)
 Simple_Write(32'h0A, 32'h00, WORD);

 //Simple write (Data: 32'h0B & Address:32'h20 & Size: Word)
 Simple_Write(32'h0B, 32'h20, WORD);

 //Busy write (Data: 32'h04 & Address:32'h0F & Size: Word)
 Busy_Write(32'h04, 32'h0F, WORD);

 //Simple read (Address:32'h00 & Size: Word)
 Simple_Read(32'h00, WORD);

 //Busy read (Address:32'h0F & Size: Word)
 Busy_Read(32'h0F, WORD);

 //Consecutive NONSEQ transfers
 Consecutive_nonseq_Write('{32'h00,32'h00,32'h00,32'h00,32'h04,32'h03,32'h02,32'h01},
                          '{32'h00,32'h00,32'h00,32'h00,32'h56,32'h34,32'h12,32'h23},
                          WORD,
                          4);


//INCR transfers
 INCR_4_Write(32'h00, '{32'h4,32'h3,32'h2,32'h1},WORD);


//Simple write in the timer_ctrl reg (Data: 32'h05 & Address:{2'b01,30'h08} & Size: Word) to activate the normal mode timer
 Simple_Write({32'b001}, {2'b10,30'h0c}, WORD);


 #(CLK_PER*10);

 $display("correct_count: %d",correct_count);
 $display("error_count: %d",error_count);
 $finish ;

end


////////////////////////////////////////////////////////
/////////////////////// TASKS //////////////////////////
////////////////////////////////////////////////////////

/////////////// Signals Initialization //////////////////

task initialize ;
  begin
  	HCLK   	       	= 1'b0;
  	HRESETn        	= 1'b1;    
  	HWRITE     		  = WRITE;
  	HSIZE          	= WORD;
    HTRANS          = IDLE;
  	HPROT          	= 4'b0011;
  	HBURST          = SINGLE;
  	HADDR          	= {ADDR_WIDTH_tb{1'b0}};
  	HWDATA          = {DATA_WIDTH_tb{1'b0}};
    correct_count   = 0;
    error_count     = 0;
  end
endtask

///////////////////////// RESET /////////////////////////
task reset ;
  begin
  	#(CLK_PER)
  	HRESETn  = 'b0;           
  	#($urandom_range(1,5)*0.5*CLK_PER)
  	HRESETn  = 'b1;
  	@(posedge DUT.sync_rst) ;
    @(negedge HCLK);
  end
endtask

////////////////////// Simple Write /////////////////////
task Simple_Write ;
  input logic [DATA_WIDTH_tb-1:0] data;
  input logic [ADDR_WIDTH_tb-1:0] address;
  input hsize size;
  begin
    HWRITE = WRITE;
    HTRANS = NONSEQ;
    HADDR = address;
    HBURST = SINGLE;
    HSIZE = size;
    @(negedge HCLK);
    HWDATA = data;
    HTRANS = IDLE;
    HWRITE = READ;
    @(negedge HCLK);
    if (address[31:30] == 00) begin
      check_write_reg_file(data,address);
    end
  end
endtask

////////////////////// Simple Read //////////////////////
task Simple_Read ;
  input logic [ADDR_WIDTH_tb-1:0] address;
  input hsize size;
  begin
    HWRITE = READ;
    HTRANS = NONSEQ;
    HADDR = address;
    HBURST = SINGLE;
    HSIZE = size;
    @(negedge HCLK);
    HTRANS = IDLE;
    HWRITE = WRITE;
    if (address[31:30] == 2'b00) begin
      check_read_reg_file(address);
    end
    if (address == {2'b01,30'h014}) begin
      check_read_timer(address);
    end
    @(negedge  HCLK);
  end
endtask

//////////////// Multiple NONSEQ Writes //////////////////
task Consecutive_nonseq_Write ;
  input logic [ADDR_WIDTH_tb-1:0] addresses [7:0];
  input logic [DATA_WIDTH_tb-1:0] data [7:0];
  input hsize size;
  input int num;


  begin
    HBURST = SINGLE;
    HSIZE = size;
    HWRITE = WRITE;
    HTRANS = NONSEQ;
    for (int i = 0; i < num; i++) begin
      HADDR = addresses[i];
      @(negedge HCLK);
      HWDATA = data[i];
      if (addresses[i][31:30] == 00 && i != 0) begin
        check_write_reg_file(data[i-1],addresses[i-1]);
      end
    end
    HTRANS = IDLE; 
    @(negedge HCLK);
    check_write_reg_file(data[num-1],addresses[num-1]);
 
  end
endtask


//////////////// INCR 4 Writes //////////////////
task INCR_4_Write ;
  input logic [ADDR_WIDTH_tb-1:0] address;
  input logic [DATA_WIDTH_tb-1:0] data [3:0];
  input hsize size;


  begin
    HBURST = INCR4;
    HSIZE = size;
    HWRITE = WRITE;
    HTRANS = NONSEQ;
    for (int i = 0; i < 4; i++) begin
      HADDR = address + i*4;
      @(negedge HCLK);
      HTRANS = SEQ;
      HWDATA = data[i];
      if (address[31:30] == 00 && i != 0) begin
        check_write_reg_file(data[i-1],address + (i-1)*4);
      end
    end
    HTRANS = IDLE; 
    HBURST = SINGLE;
    @(negedge HCLK);
    check_write_reg_file(data[3],address + 12);
 
  end
endtask


//////////////// Check write reg file //////////////////
task check_write_reg_file ;
  input logic [DATA_WIDTH_tb-1:0] data;
  input logic [ADDR_WIDTH_tb-1:0] address;
  begin
    if (DUT.reg_file.memory[address] == data && HRESP == 1'b0) begin
      $display("Write in address: %h with data %h is succcesful",address, data );
      correct_count = correct_count + 1;
    end else if (address > REG_FILE_DEPTH_tb && HRESP == 1'b1) begin
      $display("Address exceeds the limit and error signal is asserted properly");
      correct_count = correct_count + 1;
    end else begin
      $display("There was an error in writing in address: %h data: %h", address, data);
      error_count = error_count + 1;
    end
  end
endtask



//////////////// Check read reg file //////////////////
task check_read_reg_file ;
  input logic [ADDR_WIDTH_tb-1:0] address;
  begin
    assert (HRDATA == DUT.reg_file.memory[address] && HRESP == 1'b0) begin
      $display("Read from address: %h with data %h is succcesful",address, HRDATA );
      correct_count = correct_count + 1;
    end else begin 
      error_count = error_count + 1;
    end 
  end
endtask


//////////////// Check read timer //////////////////
task check_read_timer ;
  input logic [ADDR_WIDTH_tb-1:0] address;
  begin
    @(posedge DUT.timer.timer_status);
    @(negedge HCLK);
    assert (HRDATA[0] && HRESP == 1'b0) begin
      $display("Timer has succeeded");
      correct_count = correct_count + 1;
    end else begin 
      $error("Timer failed: HRDATA[0] did not rise with timer_status");
      error_count = error_count + 1;
    end  
  end
endtask


////////////////////// Busy Write /////////////////////
task Busy_Write ;
  input logic [DATA_WIDTH_tb-1:0] data;
  input logic [ADDR_WIDTH_tb-1:0] address;
  input hsize size;
  begin
    HWRITE = WRITE;
    HTRANS = NONSEQ;
    HADDR = address;
    HBURST = SINGLE;
    HSIZE = size;
    @(negedge HCLK);
    HWDATA = data;
    HTRANS = BUSY;
    HWRITE = READ;
    @(negedge HCLK);
    HTRANS = IDLE;
    @(negedge HCLK);
    if (address[31:30] == 00) begin
      check_write_reg_file(data,address);
    end
  end
endtask


////////////////////// Busy Read //////////////////////
task Busy_Read ;
  input logic [ADDR_WIDTH_tb-1:0] address;
  input hsize size;
  begin
    HWRITE = READ;
    HTRANS = NONSEQ;
    HADDR = address;
    HBURST = SINGLE;
    HSIZE = size;
    @(negedge HCLK);
    HTRANS = BUSY;
    HWRITE = WRITE;
    if (address[31:30] == 2'b00) begin
      check_read_reg_file(address);
    end
    if (address == {2'b01,30'h014}) begin
      check_read_timer(address);
    end
    @(negedge  HCLK);
    HTRANS = IDLE;
    @(negedge HCLK);
  end
endtask

endmodule
