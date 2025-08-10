`timescale 1ns/100ps

module rst_sync (
	input logic clk,    // Clock
	input logic rst, // Clock Enable
	output logic sync_rst  // Asynchronous reset active low	
);

reg bit_sync;

always_ff @(posedge clk or negedge rst) begin
	if(~rst) begin
		 bit_sync <= 1'b0;
		 sync_rst <= 1'b0;
	end else begin
		 bit_sync <= 1'b1;
		 sync_rst <= bit_sync;
	end
end

endmodule
