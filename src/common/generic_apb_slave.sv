module generic_apb_slave #(

parameter DATA_WIDTH = 32,
parameter ADDR_WIDTH = 32

)
( 

input logic                    	PSEL,
input logic                    	PENABLE,
input logic                    	PWRITE,
input logic [ADDR_WIDTH-1:0]   	PADDR,
input logic [DATA_WIDTH-1:0]   	PWDATA,
input logic [DATA_WIDTH-1:0] 	rd_data,
input logic                  	ready,
input logic                  	error,
output logic [DATA_WIDTH-1:0]   PRDATA,
output logic                   	PREADY,
output logic                    PSLVERR,
output logic                  	rd_en,
output logic                  	wr_en,
output logic [ADDR_WIDTH-1:0] 	address,
output logic [DATA_WIDTH-1:0] 	wr_data
 );


always_comb begin 	
	PREADY = ready;
	PSLVERR = error;
	address = PADDR;
	wr_data = PWDATA;
	if (PENABLE && PSEL) begin
		if (PWRITE) begin
			wr_en = 1'b1;
			rd_en = 1'b0;
		end else begin
			wr_en = 1'b0;
			rd_en = 1'b1;
			PRDATA = rd_data;
		end
	end else begin
		rd_en = 1'b0;
		wr_en = 1'b0;
		PRDATA = {DATA_WIDTH{1'b0}};
	end
end



endmodule : generic_apb_slave