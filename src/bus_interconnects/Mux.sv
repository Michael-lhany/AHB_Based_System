`timescale 1ns/100ps

module mux #( parameter DATA_WIDTH = 32) 
(
input logic [DATA_WIDTH-1:0] HRDATA0, HRDATA1, HRDATA2, 
input logic HRESP0, HRESP1, HRESP2,
input logic HREADY0, HREADY1, HREADY2,
input logic HSEL0, HSEL1, HSEL2,
output logic [DATA_WIDTH-1:0] HRDATA,
output logic HRESP,
output logic HREADY  	
);

logic [2:0] selector;  

assign selector = {HSEL2,HSEL1,HSEL0};

always @(*) begin
	if (selector == 3'b001) begin
		HRDATA = HRDATA0;
		HRESP = HRESP0;
		HREADY = HREADY0;
	end else if (selector == 3'b010) begin
		HRDATA = HRDATA1;
		HRESP = HRESP1;
		HREADY = HREADY1;
	end else if (selector == 3'b100) begin
		HRDATA = HRDATA2;
		HRESP = HRESP2;
		HREADY = HREADY2;
	end
end


 
endmodule 
