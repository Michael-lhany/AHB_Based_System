`timescale 1ns/100ps

module Reg_File #(

parameter DATA_WIDTH = 32,
parameter ADDR_WIDTH = 32,
parameter REG_FILE_DEPTH = 16,
parameter REG_FILE_ADDR = $clog2(REG_FILE_DEPTH)

)
(
input logic 					clk,
input logic 					rst,
input logic                  	rd_en,
input logic                  	wr_en,
input logic [ADDR_WIDTH-1:0] 	address,
input logic [DATA_WIDTH-1:0] 	wr_data,
output logic [DATA_WIDTH-1:0] 	rd_data,
output logic                  	ready,
output logic                  	error
);


//Internal memory
reg [DATA_WIDTH-1:0] memory [REG_FILE_DEPTH-1:0];




//Write Logic
always_ff @(posedge clk or negedge rst) begin
	if (~rst) begin
		for (int i=0 ; i < REG_FILE_DEPTH ; i = i +1) begin
          memory[i] <= 0 ;
        end       
	end else begin
		if (wr_en && !rd_en) begin
			memory[address[REG_FILE_ADDR-1:0]] <= wr_data;
		end
	end
end




//ready and error signal logic
always_ff @(posedge clk or negedge rst) begin 
	if(~rst) begin
		error <= 1'b0;
	end else begin
		if ( address[ADDR_WIDTH-3:0] > REG_FILE_DEPTH ) begin
			error <= 1'b1;
		end else begin
			error <= 1'b0;
		end
	end
end


assign ready = 1'b1;

//Read logic
assign rd_data = (rd_en && !wr_en) ? memory[address[REG_FILE_ADDR-1:0]] : {DATA_WIDTH{1'b0}} ;


endmodule
