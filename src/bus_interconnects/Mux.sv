module mux #( parameter DATA_WIDTH = 32) 
(
input logic [DATA_WIDTH-1:0] HRDATA0, HRDATA1, 
input logic HRESP0, HRESP1, 
input logic HREADY0, HREADY1,
input logic HSEL0, HSEL1,
output logic [DATA_WIDTH-1:0] HRDATA,
output logic HRESP,
output logic HREADY  	
);

logic [3:0] select;  

assign select = {HSEL1,HSEL0};

always @(*) begin
	if (select == 4'b0001) begin
		HRDATA = HRDATA0;
		HRESP = HRESP0;
		HREADY = HREADY0;
	end else if (select == 4'b0010) begin
		HRDATA = HRDATA1;
		HRESP = HRESP1;
		HREADY = HREADY1;
	end else begin
		HRDATA = HRDATA0;
		HRESP = HRESP0;
		HREADY = HREADY0;
	end
end


 
endmodule 