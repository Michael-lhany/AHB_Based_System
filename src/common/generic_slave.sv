`timescale 1ns/100ps

module generic_slave #(

parameter DATA_WIDTH = 32,
parameter ADDR_WIDTH = 32

)
( 

input logic                  	HCLK,
input logic                  	HRESETn,
input logic [ADDR_WIDTH-1:0] 	HADDR,
input logic [1:0]            	HTRANS,
input logic                  	HWRITE,
input logic [2:0]            	HSIZE,
input logic [2:0]            	HBURST,
input logic [3:0]            	HPROT,
input logic [DATA_WIDTH-1:0] 	HWDATA,
input logic                  	HSEL,
input logic [DATA_WIDTH-1:0] 	rd_data,
input logic                  	ready,
input logic                  	error,
output logic [DATA_WIDTH-1:0] 	HRDATA,
output logic                  	HREADY,
output logic                  	HRESP,
output logic                  	rd_en,
output logic                  	wr_en,
output logic [ADDR_WIDTH-1:0] 	address,
output logic [DATA_WIDTH-1:0] 	wr_data
 );


/////////////////////////////////////////////////////////
///////////////////// Parameters ////////////////////////
/////////////////////////////////////////////////////////


/*HSIZE types
localparam          BYTE  = 3'b000 ,
                    HWORD = 3'b001 ,
                    WORD  = 3'b010 ,
                    DWORD = 3'b011 ,                    
                    FWORD  = 3'b100 ,
                    EWORD = 3'b101 ;
*/

localparam          IDLE  = 3'b000 ,
                    BUSY = 3'b001 ,
                    NONSEQ  = 3'b010 ,
                    SEQ = 3'b011 ;


/////////////////////////////////////////////////////////
/////////////////// Internal signals ////////////////////
/////////////////////////////////////////////////////////

logic [ADDR_WIDTH-1:0] temp_addr;
logic [DATA_WIDTH-1:0] temp_read_reg;
logic temp_write_signal;
logic valid;

typedef enum bit [1:0] {	IDLE_STATE = 2'b00,
							BUSY_STATE = 2'b01,
							NONSEQ_STATE = 2'b11,
							SEQ_STATE = 2'b10 } state;


state			current_state,
				next_state ;




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


always_comb begin 
	case (current_state)
		IDLE_STATE : begin
			if (HTRANS == NONSEQ && valid) begin
				next_state = NONSEQ_STATE;
			end else if (HTRANS == IDLE && ready) begin
				next_state = IDLE_STATE;
			end else begin
				next_state = current_state;
			end
		end
		BUSY_STATE : begin
			if (HTRANS == NONSEQ && valid) begin
				next_state = NONSEQ_STATE;
			end else if (HTRANS == BUSY && valid) begin
				next_state = BUSY_STATE;
			end else if (HTRANS == SEQ && valid) begin
				next_state = SEQ_STATE;
			end else if (HTRANS == IDLE && ready) begin
				next_state = IDLE_STATE;
			end else begin
				next_state = current_state;
			end
		end
		NONSEQ_STATE : begin
			if (HTRANS == NONSEQ && valid) begin
				next_state = NONSEQ_STATE;
			end else if (HTRANS == BUSY && valid) begin
				next_state = BUSY_STATE;
			end else if (HTRANS == SEQ && valid) begin
				next_state = SEQ_STATE;
			end else if (HTRANS == IDLE && ready) begin
				next_state = IDLE_STATE;
			end else begin
				next_state = current_state;
			end
		end
		SEQ_STATE : begin
			if (HTRANS == NONSEQ && valid) begin
				next_state = NONSEQ_STATE;
			end else if (HTRANS == BUSY && valid) begin
				next_state = BUSY_STATE;
			end else if (HTRANS == SEQ && valid) begin
				next_state = SEQ_STATE;
			end else if (HTRANS == IDLE && ready) begin
				next_state = IDLE_STATE;
			end else begin
				next_state = current_state;
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
	HREADY = ready;
	HRDATA = {DATA_WIDTH{1'b0}};
	HRESP = error;
	rd_en = 1'b0;
	wr_en = 1'b0;
	wr_data = HWDATA;
	address = {ADDR_WIDTH{1'b0}};

	case (current_state)
		IDLE_STATE : begin
			if (next_state == SEQ_STATE || next_state == BUSY_STATE) begin
				HRESP = 1'b1;
			end else begin
				HRESP = error;
			end
			HREADY = ready;
			HRDATA = {DATA_WIDTH{1'b0}};
			rd_en = 1'b0;
			wr_en = 1'b0;
			wr_data = HWDATA;
			address = {ADDR_WIDTH{1'b0}};
		end
		BUSY_STATE : begin
			HREADY = ready;
			HRDATA = {DATA_WIDTH{1'b0}};
			HRESP = error;
			rd_en = 1'b0;
			wr_en = 1'b0;
			wr_data = HWDATA;
			address = {ADDR_WIDTH{1'b0}};
		end
		NONSEQ_STATE : begin
			HREADY = ready;
			HRESP = error;
			address = temp_addr;
			if (temp_write_signal) begin
				wr_en = 1'b1;
				wr_data = HWDATA;
				rd_en = 1'b0;
			end else begin
				rd_en = 1'b1;
				HRDATA = rd_data;
			end
		end
		SEQ_STATE : begin
			HREADY = ready;
			HRESP = error;
			address = temp_addr;
			if (temp_write_signal) begin
				wr_en = 1;
				wr_data = HWDATA;
			end else begin
				rd_en = 1;
				HRDATA = rd_data;
			end
		end
		default : begin
			HREADY = ready;
			HRDATA = {DATA_WIDTH{1'b0}};
			HRESP = error;
			rd_en = 1'b0;
			wr_en = 1'b0;
			wr_data = HWDATA;
			address = {ADDR_WIDTH{1'b0}};
		end
	endcase
end


/////////////////////////////////////////////////////////
/////////////////// Internal Logic //////////////////////
/////////////////////////////////////////////////////////


always_ff @(posedge HCLK or negedge HRESETn) begin 
	if(~HRESETn) begin
		temp_addr <= {ADDR_WIDTH{1'b0}};
		temp_write_signal <= 1'b1;
	end else begin
		if (valid && next_state != BUSY_STATE) begin
			temp_addr <= HADDR;
			temp_write_signal <= HWRITE;
		end
	end
end

assign valid = HSEL && ready;




endmodule
