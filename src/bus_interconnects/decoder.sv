`timescale 1ns/100ps

module decoder #( parameter ADDR_WIDTH = 32 ) 
(
input logic [ADDR_WIDTH-1:0] HADDR,
output logic HSEL0,
output logic HSEL1,
output logic HSEL2
);


always @(*) begin 	
	HSEL0 = 1'b0;
	HSEL1 = 1'b0;
	HSEL2 = 1'b0;

	case (HADDR[31:30])
		2'b00: HSEL0 = 1'b1;
		2'b01: HSEL1 = 1'b1;
		2'b10: HSEL2 = 1'b1;
		default: begin
			HSEL0 = 1'b0;
			HSEL1 = 1'b0;
			HSEL2 = 1'b0;
		end
	endcase	
end


endmodule
